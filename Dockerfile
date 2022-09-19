# docker build -t bartoszj/debian .

FROM debian:testing
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR ${HOME}

ARG KUBELOGIN_VERSION=0.0.20
ARG KUBECTL_VERSION=1.24.3-00
ARG KUBECTX_VERSION=0.9.4
ARG HELM_VERSION=3.9.4
ARG VAULT_VERSION=1.11.3
ARG BOMBARDIER_VERSION="v1.2.5"

RUN chmod g=u /etc/passwd
RUN apt update \
 && apt upgrade --yes \
 && apt install --yes --no-install-recommends apt-transport-https bash-completion lsb-release vim procps htop dstat file less iproute2 \
    dnsutils gnupg whois wget curl ca-certificates telnet \
    apt-file unzip lshw git openssh-client socat netcat-traditional netcat-openbsd nmap stress-ng speedtest-cli iperf iperf3 tcpdump kafkacat nfs-common \
    python3 python-is-python3 \
    jq \
    # jid
    mariadb-client mycli postgresql-client redis-tools nghttp2-client \
    links2 lynx \
 && apt-file update \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Fix Mariadb charset
RUN sed -i"" -e "s|default-character-set|# default-character-set|g" /etc/mysql/mariadb.conf.d/50-client.cnf

# AWS
RUN apt update \
 && apt install --yes --no-install-recommends groff-base less \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && if [ $(dpkg --print-architecture) = "amd64" ]; then export AWS_ARCH="x86_64"; else export AWS_ARCH="aarch64"; fi \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf aws awscliv2.zip \
 && echo "complete -C '/usr/local/bin/aws_completer' aws" > /etc/bash_completion.d/aws

# Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
RUN apt update \
 && curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
 && AZ_REPO=bullseye; echo "deb https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
 && apt update \
 && apt install --yes azure-cli \
 && apt clean

# # Google Cloud SDK
# RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
#  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
#  && apt update \
#  && apt install --yes google-cloud-sdk \
#  && apt clean

# # MongoDB
# # https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/
# # https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
# RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add - \
#  && echo "deb http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list \
#  && apt update \
#  && apt install --yes mongodb-org-shell mongodb-mongosh \
#  && if [ $(dpkg --print-architecture) = "amd64" ]; then apt install --yes mongocli; fi \
#  && apt clean

# Kubelogin
# https://github.com/Azure/kubelogin
RUN curl -fSL https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-$(dpkg --print-architecture).zip -o kubelogin-linux-$(dpkg --print-architecture).zip \
 && unzip -d kubelogin kubelogin-linux-$(dpkg --print-architecture).zip \
 && mv kubelogin/bin/linux_$(dpkg --print-architecture)/kubelogin /usr/local/bin/ \
 && rm -rf kubelogin kubelogin-linux-$(dpkg --print-architecture).zip

# Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
 && apt update \
 && apt install --yes kubectl=${KUBECTL_VERSION} \
 && kubectl completion bash >/etc/bash_completion.d/kubectl \
 && rm -rf /var/lib/apt/lists/*

# Kubectx & kubens
RUN if [ $(dpkg --print-architecture) = "amd64" ]; then \
 curl -fSL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_x86_64.tar.gz -o kubectx.tgz \
 && curl -fSL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_x86_64.tar.gz -o kubens.tgz \
 ; else \
 curl -fSL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_$(dpkg --print-architecture).tar.gz -o kubectx.tgz \
 && curl -fSL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_$(dpkg --print-architecture).tar.gz -o kubens.tgz \
 ; fi \
 && mkdir kubectx kubens \
 && tar -C kubectx -xzf kubectx.tgz \
 && tar -C kubens -xzf kubens.tgz \
 && mv kubectx/kubectx /usr/local/bin \
 && mv kubens/kubens /usr/local/bin \
 && rm -rf kubectx kubens kubectx.tgz kubens.tgz

# Helm
RUN curl -fSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz -o helm.tar.gz \
 && mkdir helm \
 && tar -C helm --strip-components=1 -xzf helm.tar.gz \
 && mv helm/helm /usr/local/bin \
 && rm -rf helm helm.tar.gz

# Vault
RUN wget -c https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_$(dpkg --print-architecture).zip -O vault_linux.zip \
 && unzip vault_linux.zip \
 && mv vault /usr/local/bin/ \
 && rm vault_linux.zip \
 && echo "if [ -f /usr/local/bin/vault ]; then complete -C /usr/local/bin/vault vault; fi" >> /etc/bash.bashrc

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
RUN wget -c https://github.com/codesenberg/bombardier/releases/download/${BOMBARDIER_VERSION}/bombardier-linux-$(dpkg --print-architecture) -O /usr/local/bin/bombardier \
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
# RUN curl -L https://github.com/jiaqi/jmxterm/releases/download/v1.0.2/jmxterm_1.0.2_all.deb -O \
#  && apt install --yes openjdk-11-jre-headless \
#  && apt install ./jmxterm*deb \
#  && rm jmxterm*deb \
#  && apt clean

# # RabbitMQ Admin
# RUN RABBITMQ_ADMIN_VERSION=3.8.2 \
#  && curl -sL https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v${RABBITMQ_ADMIN_VERSION}/bin/rabbitmqadmin -o /usr/local/bin/rabbitmqadmin \
#  && chmod 755 /usr/local/bin/rabbitmqadmin \
#  && rabbitmqadmin --bash-completion > /etc/bash_completion.d/rabbitmqadmin

# # go-zkcli
# RUN if [ $(dpkg --print-architecture) = "amd64" ]; then export GO_ZKCLI_VERSION=1.0.12 \
#  && curl -sL https://github.com/outbrain/zookeepercli/releases/download/v${GO_ZKCLI_VERSION}/zookeepercli-linux-$(dpkg --print-architecture)-binary.tar.gz -o zookeepercli-linux-binary.tar.gz \
#  && tar -zxvf zookeepercli-linux-binary.tar.gz \
#  && mv zookeepercli /usr/local/bin/ \
#  && rm -f *.tar.gz \
#  ; fi

# User dir settings
RUN mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
