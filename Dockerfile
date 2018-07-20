# docker build -t bartoszj/debian .

FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
WORKDIR ${HOME}

RUN chmod g=u /etc/passwd
RUN apt-get update \
 && apt-get install -y procps bash-completion vim dnsutils whois wget curl links2 lynx telnet \
    apt-file lshw git openssh-client netcat netcat-openbsd \
    mysql-client postgresql-client mongodb-clients redis-tools \
 && apt-file update \

 && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
 && chmod +x ./kubectl \
 && mv ./kubectl /usr/local/bin/ \

 && OC_VERSION="v3.9.0" \
 && OC_VERSION_HASH="191fece" \
 && wget -O openshift-origin-cli.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_VERSION_HASH}-linux-64bit.tar.gz \
 && mkdir openshift-origin-cli || true \
 && tar -zxvf openshift-origin-cli.tar.gz --directory openshift-origin-cli --strip-components=1 \
 && mv openshift-origin-cli/oc /usr/local/bin/ \
 && rm -f openshift-origin-cli.tar.gz \
 && rm -rf openshift-origin-cli \
 
 && mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
