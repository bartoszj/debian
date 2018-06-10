# docker build -t bartoszj/debian .

FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com
ENV HOME /home/debian

RUN chmod g=u /etc/passwd
RUN apt-get update \
 && apt-get install -y bash-completion vim dnsutils wget curl links2 lynx \
    apt-file lshw git openssh-client netcat netcat-openbsd \
    mysql-client postgresql-client mongodb-clients redis-tools \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /home/debian \
 && cp /etc/skel/.* /home/debian/ 2>/dev/null || true

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]
