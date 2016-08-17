FROM __image_prefix__/base:latest
ENV version=2

ENV CONFD_VERSION 0.11.0
ENV CONFD_URL https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64

RUN apt-get -yqq update && apt-get -yq install haproxy
RUN wget $CONFD_URL -O /usr/local/bin/confd && chmod +x /usr/local/bin/confd

COPY entrypoint.sh /
CMD /bin/bash /entrypoint.sh
