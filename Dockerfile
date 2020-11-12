# docker build -t bartoszj/debian .

FROM debian:testing
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
WORKDIR ${HOME}

RUN chmod g=u /etc/passwd
RUN apt update \
 && apt install --yes --no-install-recommends apt-transport-https bash-completion lsb-release vim procps htop dstat file \
    dnsutils gnupg whois wget curl telnet \
    apt-file unzip lshw git openssh-client socat netcat netcat-openbsd nmap speedtest-cli iperf iperf3 tcpdump kafkacat nfs-common \
    python3 python2 python-is-python3 \
    jq jid \
    # groff
    mariadb-client mycli postgresql-client redis-tools apache2-utils \
 && apt install --yes --no-install-recommends links2 lynx \
 && apt-file update \
 && apt clean

# Fix Mariadb charset
RUN sed -i"" -e "s|default-character-set|# default-character-set|g" /etc/mysql/mariadb.conf.d/50-client.cnf

# MongoDB
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - \
 && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list \
 && apt update \
 && apt install --yes mongodb-org-shell \
 && apt clean

# MongoSH
RUN wget -c https://downloads.mongodb.com/compass/mongosh_0.5.2_amd64.deb \
 && dpkg --install mongosh_0.5.2_amd64.deb \
 && rm *.deb \
 && apt clean

# Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
 && apt update \
 && apt install --yes kubectl \
 && kubectl completion bash >/etc/bash_completion.d/kubectl \
 && apt clean

# kubectx & kubens
RUN curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o /usr/local/bin/kubens \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o /usr/local/bin/kubectx \
 && chmod 755 /usr/local/bin/kubens \
 && chmod 755 /usr/local/bin/kubectx \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash -o /etc/bash_completion.d/kubens \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash -o /etc/bash_completion.d/kubectx

# # Helm
# RUN HELM_VERSION="v2.13.1" \
#  && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh \
#  && chmod 700 get_helm.sh \
#  && ./get_helm.sh --version "${HELM_VERSION}" \
#  && rm get_helm.sh

# Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
 && apt update \
 && apt install --yes google-cloud-sdk \
 && apt clean

# Vault
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
 && echo "deb [arch=amd64] https://apt.releases.hashicorp.com buster main" | tee -a /etc/apt/sources.list.d/hashicorp.list \
 && apt update \
 && apt install --yes vault \
 && setcap cap_ipc_lock= /usr/bin/vault \
 && apt clean

# # OpenShift CLI
# RUN OC_VERSION="v3.11.0" \
#  && OC_VERSION_HASH="0cbc58b" \
#  && wget -O openshift-origin-cli.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_HASH}-linux-64bit.tar.gz \
#  && mkdir openshift-origin-cli || true \
#  && tar -zxvf openshift-origin-cli.tar.gz --directory openshift-origin-cli --strip-components=1 \
#  && mv openshift-origin-cli/oc /usr/local/bin/ \
#  && rm -f openshift-origin-cli.tar.gz \
#  && rm -rf openshift-origin-cli

# Bombardier
RUN BOMBARDIER_VERSION="v1.2.4" \
 && wget -c https://github.com/codesenberg/bombardier/releases/download/${BOMBARDIER_VERSION}/bombardier-linux-amd64 -O /usr/local/bin/bombardier \
 && chmod 755 /usr/local/bin/bombardier

# # Elasticsearch Stress Test
# RUN curl -s https://raw.githubusercontent.com/logzio/elasticsearch-stress-test/master/elasticsearch-stress-test.py -o /usr/local/bin/elasticsearch-stress-test \
#  && chmod 755 /usr/local/bin/elasticsearch-stress-test \
#  && pip install elasticsearch

# # ES Rally
# RUN pip3 install esrally

# # RabbitMQ Perf Test
# RUN curl -sL https://github.com/rabbitmq/rabbitmq-perf-test/releases/download/v2.8.1/perf-test_linux_x86_64 -o /usr/local/bin/rabbit-perf-test \
#  && chmod 755 /usr/local/bin/rabbit-perf-test

# # JMX Term
# RUN curl -L https://github.com/jiaqi/jmxterm/releases/download/v1.0.1/jmxterm_1.0.1_all.deb -O \
#  && apt install --yes openjdk-11-jre-headless \
#  && apt install ./jmxterm*deb \
#  && rm jmxterm*deb \
#  && apt clean

# RabbitMQ Admin
RUN curl -sL https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v3.8.2/bin/rabbitmqadmin -o /usr/local/bin/rabbitmqadmin \
 && chmod 755 /usr/local/bin/rabbitmqadmin \
 && rabbitmqadmin --bash-completion > /etc/bash_completion.d/rabbitmqadmin

# go-zkcli
RUN curl -sL https://github.com/outbrain/zookeepercli/releases/download/v1.0.12/zookeepercli-linux-amd64-binary.tar.gz -o zookeepercli-linux-amd64-binary.tar.gz \
 && tar -zxvf zookeepercli-linux-amd64-binary.tar.gz \
 && mv zookeepercli /usr/local/bin/ \
 && rm -f *.tar.gz

# User dir settings
RUN mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
