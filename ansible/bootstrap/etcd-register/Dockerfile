FROM __image_prefix__/python2:latest
ENV version=2

ENV DOCKER_GEN_VERSION=0.7.0
ENV DOCKER_GEN_URL https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

ENV DOCKER_HOST unix:///var/run/docker.sock

RUN apt-get install -yqq --no-install-recommends libffi-dev libssl-dev \
    && cd /tmp && wget $DOCKER_GEN_URL \
    && tar xvzf docker-gen-linux-amd64*.tar.gz -C /usr/local/bin \ 
    && rm -vf /tmp/docker-gen-linux*

ADD requirements.pip /
RUN pip install -r requirements.pip

ADD . /app
WORKDIR /app

CMD docker-gen -interval 5 -watch -notify "python /tmp/register.py" etcd.tmpl /tmp/register.py
