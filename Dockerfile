# docker build -t bartoszj/debian .

FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian
WORKDIR ${HOME}

RUN chmod g=u /etc/passwd
RUN apt-get update \
 && apt-get install -y bash-completion vim dnsutils whois wget curl links2 lynx telnet \
    apt-file lshw git openssh-client netcat netcat-openbsd \
    mysql-client postgresql-client mongodb-clients redis-tools \
 && apt-file update \
 && mkdir -p ${HOME} \
 && cp /etc/skel/.* ${HOME} 2>/dev/null || true \
 && chgrp -R 0 ${HOME} \
 && chmod -R g=u ${HOME}

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
