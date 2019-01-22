# docker build -t bartoszj/debian .

FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
WORKDIR ${HOME}

RUN chmod g=u /etc/passwd
RUN apt-get update \
 && apt-get install --yes bash-completion vim procps htop dstat dnsutils whois wget curl telnet \
    apt-file unzip lshw git openssh-client socat netcat netcat-openbsd nmap speedtest-cli iperf iperf3 \
    jq jid groff \
    mysql-client mysql-server mycli postgresql-client mongodb-clients redis-tools apache2-utils \
 && apt-get install --yes --no-install-recommends links2 lynx \
 && apt-file update \
 # Kubernetes
 && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
 && chmod +x ./kubectl \
 && mv ./kubectl /usr/local/bin/ \
 # Helm
 && HELM_VERSION="v2.12.2" \
 && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh \
 && chmod 700 get_helm.sh \
 && ./get_helm.sh --version "${HELM_VERSION}" \
 && rm get_helm.sh \
 # OpenShift CLI
 && OC_VERSION="v3.11.0" \
 && OC_VERSION_HASH="0cbc58b" \
 && wget -O openshift-origin-cli.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_HASH}-linux-64bit.tar.gz \
 && mkdir openshift-origin-cli || true \
 && tar -zxvf openshift-origin-cli.tar.gz --directory openshift-origin-cli --strip-components=1 \
 && mv openshift-origin-cli/oc /usr/local/bin/ \
 && rm -f openshift-origin-cli.tar.gz \
 && rm -rf openshift-origin-cli \
 # User dir settings
 && mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
