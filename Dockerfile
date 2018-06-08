FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com

RUN chmod g=u /etc/passwd
RUN apt-get update \
 && apt-get install -y vim dnsutils wget curl links2 lynx mysql-client postgresql-client \
 && rm -rf /var/lib/apt/lists/*

COPY uid_entrypoint /usr/bin/
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["bash"]

