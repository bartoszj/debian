# docker build -t bartoszj/debian .

FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
WORKDIR ${HOME}

RUN chmod g=u /etc/passwd
RUN apt update \
 && apt install --yes apt-transport-https bash-completion vim procps htop dstat dnsutils gnupg whois wget curl telnet \
    apt-file unzip lshw git openssh-client socat netcat netcat-openbsd nmap speedtest-cli iperf iperf3 kafkacat \
    jq jid groff \
    mysql-client mysql-server mycli postgresql-client mongodb-clients redis-tools apache2-utils \
 && apt install --yes --no-install-recommends links2 lynx \
 && apt-file update \
 # Kubernetes
 && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
 && apt update \
 && apt install --yes kubectl kubeadm \
 && kubectl completion bash >/etc/bash_completion.d/kubectl \
 ## kubectx & kubens
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o /usr/local/bin/kubens \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o /usr/local/bin/kubectx \
 && chmod 755 /usr/local/bin/kubens \
 && chmod 755 /usr/local/bin/kubectx \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash -o /etc/bash_completion.d/kubens \
 && curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash -o /etc/bash_completion.d/kubectx \
 # Helm
 && HELM_VERSION="v2.13.1" \
 && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh \
 && chmod 700 get_helm.sh \
 && ./get_helm.sh --version "${HELM_VERSION}" \
 && rm get_helm.sh \
 # Google Cloud SDK
 && CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
 && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && apt update && apt install --yes google-cloud-sdk \
 # OpenShift CLI
 && OC_VERSION="v3.11.0" \
 && OC_VERSION_HASH="0cbc58b" \
 && wget -O openshift-origin-cli.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_HASH}-linux-64bit.tar.gz \
 && mkdir openshift-origin-cli || true \
 && tar -zxvf openshift-origin-cli.tar.gz --directory openshift-origin-cli --strip-components=1 \
 && mv openshift-origin-cli/oc /usr/local/bin/ \
 && rm -f openshift-origin-cli.tar.gz \
 && rm -rf openshift-origin-cli \
 # Bombardier
 && BOMBARDIER_VERSION="v1.2.4" \
 && wget -c https://github.com/codesenberg/bombardier/releases/download/${BOMBARDIER_VERSION}/bombardier-linux-amd64 -O /usr/local/bin/bombardier \
 && chmod 755 /usr/local/bin/bombardier \
 # User dir settings
 && mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
