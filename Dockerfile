FROM debian:latest
LABEL maintainer Bartosz Janda, bjanda@pgs-soft.com

RUN apt-get update \
 && apt-get install -y vim dnsutils wget curl links2 lynx mysql-client postgresql-client
