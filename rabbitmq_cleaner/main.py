#! /usr/bin/env python

import asyncio
from dataclasses import dataclass
from kubernetes import client, config
from typing import Optional, List
import base64
import tqdm
import rabbitmq_api


@dataclass
class RabbitMQ:
    name: str
    namespace: str
    username: str
    password: str

    @property
    def url(self) -> str:
        return f"http://{self.name}.{self.namespace}.svc:15672"


def find_rabbitmq() -> List[RabbitMQ]:
    rabbitmq: List[RabbitMQ] = []
    try:
        config.load_incluster_config()
    except config.config_exception.ConfigException as e:
        config.load_kube_config()

    v1 = client.CoreV1Api()
    print("Get all RabbitMQ services")
    ret = v1.list_service_account_for_all_namespaces(label_selector="app in (rabbitmq, rabbitmq-ha)", watch=False)
    for i in ret.items:
        name = i.metadata.name
        namespace = i.metadata.namespace
        username: Optional[str] = None
        password: Optional[str] = None

        # Get secrets for service
        secrets = v1.list_namespaced_secret(namespace, label_selector="app in (rabbitmq, rabbitmq-ha)", watch=False)
        if len(secrets.items) == 1:
            if "rabbitmq-username" in secrets.items[0].data:
                username = base64.b64decode(secrets.items[0].data["rabbitmq-username"]).decode("utf-8")
            else:
                username = "rabbit"
            password = base64.b64decode(secrets.items[0].data["rabbitmq-password"]).decode("utf-8")

        if username is not None and password is not None:
            rabbitmq.append(RabbitMQ(name=name, namespace=namespace, username=username, password=password))
    return rabbitmq


def filter_queues(queues: List[rabbitmq_api.Queue]) -> List[rabbitmq_api.Queue]:
    def f(queue: rabbitmq_api.Queue) -> bool:
        if queue.name.endswith("_worker") and queue.consumers == 0 and queue.messages == 0:
            return True
        return False

    return list(filter(f, queues))


async def clean_rabbitmq(name: str, queue: asyncio.Queue, progress: tqdm.tqdm = None, task_progress: tqdm.tqdm = None):
    while True:
        rabbitmq = await queue.get()  # type: RabbitMQ

        credentials = rabbitmq_api.Credentials(username=rabbitmq.username, password=rabbitmq.password)
        api = rabbitmq_api.RabbitMQAPI(credentials=credentials, base_url=rabbitmq.url)
        queues = filter_queues(await api.get_queues())

        if len(queues) > 0:
            if task_progress is not None:
                task_progress.desc = f"{name} {rabbitmq.namespace}"
                task_progress.reset(len(queues))

            await api.delete_queues(queues, progress=task_progress)
        await api.close()

        if progress is not None:
            progress.update()
        queue.task_done()


QUEUE_WORKERS = 3


if __name__ == '__main__':
    async def run():
        # Find all RabbitMQ instances
        rabbitmqs = find_rabbitmq()
        job_queue = asyncio.Queue()
        for r in rabbitmqs:
            job_queue.put_nowait(r)

        with tqdm.tqdm(total=len(rabbitmqs), unit="rabbitmq", position=0) as bar:
            # Run jobs
            tasks = []
            bars = []
            for i in range(QUEUE_WORKERS):
                task_name = f"worker-{i}"
                task_bar = tqdm.tqdm(position=i + 1, unit="queue")
                bars.append(task_bar)
                task = asyncio.create_task(clean_rabbitmq(task_name, job_queue, bar, task_bar))
                tasks.append(task)

            # Wait until all jobs are finished
            await job_queue.join()

            # Cancel workers
            for task in tasks:
                task.cancel()
            for task_bar in bars:
                task_bar.close()

            # Wait until all worker tasks are cancelled.
            await asyncio.gather(*tasks, return_exceptions=True)

    loop = asyncio.run(run())
