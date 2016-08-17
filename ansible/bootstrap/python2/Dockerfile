FROM __image_prefix__/base:latest
ENV version=2

RUN apt-get install -yqq --force-yes --no-install-recommends \
      build-essential python python-dev python-virtualenv
RUN wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py \
    && python /tmp/get-pip.py
