#! /usr/bin/env python

import asyncio
import aiohttp
import random
import urllib.parse
from dataclasses import dataclass, fields
from typing import Type, List, Coroutine
from yarl import URL
import tqdm


@dataclass
class Queue:
    consumers: int
    messages: int
    name: str
    vhost: str

    @classmethod
    def from_dict(cls: Type['Queue'], obj: dict) -> 'Queue':
        class_fields = {f.name for f in fields(cls)}
        o = cls(**{k: v for k, v in obj.items() if k in class_fields})
        return o


class Credentials:
    def __init__(self, username: str, password: str):
        self.username = username
        self.password = password


class RabbitMQAPI:
    GET_QUEUES_RETRY = 5
    GET_QUEUES_RETRY_SLEEP = 3
    DELETE_QUEUE_RETRY = 5
    DELETE_QUEUE_RETRY_SLEEP = 3

    def __init__(self, credentials: Credentials, base_url: str):
        conn = aiohttp.TCPConnector(limit=30)
        timeout = aiohttp.ClientTimeout(total=10)
        auth = aiohttp.BasicAuth(credentials.username, credentials.password)
        self._session = aiohttp.ClientSession(connector=conn, timeout=timeout, auth=auth)

        self.base_url = URL(base_url)

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        await self.close()

    async def close(self):
        await self._session.close()

    async def get_queues(self, retry: int = GET_QUEUES_RETRY) -> List[Queue]:
        url = self.base_url.with_path("/api/queues")

        retry -= 1
        try:
            # Get queues
            async with self._session.get(url) as resp:
                if resp.status != 200:
                    raise Exception(f"Unknown response code {resp.status}")
                j = await resp.json()
                queues = [Queue.from_dict(q) for q in j]
                return queues
        except asyncio.TimeoutError as err:
            # print(f"Timeout {url}")
            if retry == 0:
                raise Exception(f"Cannot get queues due timeout {err}")
            else:
                await asyncio.sleep(random.uniform(0, self.GET_QUEUES_RETRY_SLEEP))
                return await self.get_queues(retry=retry)

    async def delete_queue(self, queue: Queue, retry: int = DELETE_QUEUE_RETRY):
        url = self.base_url.join(
            URL(f"/api/queues/{urllib.parse.quote(queue.vhost, safe='')}/{queue.name}").with_query({"if-empty": "true", "if-unused": "true"})
        )

        retry -= 1
        try:
            await self._session.delete(url)
        except asyncio.TimeoutError as err:
            # print(f"Timeout {url}")
            if retry == 0:
                raise Exception(f"Cannot delete queue due timeout {err}")
            else:
                await asyncio.sleep(random.uniform(0, self.DELETE_QUEUE_RETRY_SLEEP))
                return await self.delete_queue(queue=queue, retry=retry)

    async def delete_queues(self, queues: List[Queue], progress: tqdm.tqdm = None):
        async def delete_queue(queue: Queue):
            await self.delete_queue(queue)
            if progress is not None:
                progress.update()

        c: List[Coroutine] = []
        for q in queues:
            c.append(delete_queue(q))
        await asyncio.gather(*c)
