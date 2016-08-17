FROM debian:jessie
ENV version=2

# enable non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

# disable apt-get cache
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# install base packages
RUN apt-get update -yqq \
    && apt-get -yqq dist-upgrade \
    && apt-get -yqq --force-yes install \
      curl wget git-core vim locales apt-transport-https

# add self-signed certificate
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout private.key -out private.crt
# todo: is this still needed?
COPY internal.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
