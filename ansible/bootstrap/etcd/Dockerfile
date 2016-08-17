FROM __image_prefix__/python2:latest
ENV version=2

# warning: do not use ETCD_XXX prefixed env vars
ENV APP_VERSION=v2.3.7

ENV URL https://github.com/coreos/etcd/releases/download/$APP_VERSION/etcd-$APP_VERSION-linux-amd64.tar.gz

RUN curl -L $URL -o /tmp/etcd.tar.gz \
    && cd /tmp && tar zxf etcd.tar.gz \
    && mv -v etcd-*/etcd /usr/local/bin/ \
    && mv -v etcd-*/etcdctl /usr/local/bin/

ADD requirements.pip /
RUN pip install -r requirements.pip

VOLUME /app/data
ADD etcd_proc.py /bin/etcd_proc.py
ADD etcd_monitor.sh /bin/etcd_monitor.sh

ENTRYPOINT ["/usr/bin/python", "/bin/etcd_proc.py"]
