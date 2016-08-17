FROM __image_prefix__/python2:latest
ENV version=2

ENV ANSIBLE_URL=https://github.com/ansible/ansible.git
ENV ANSIBLE_BRANCH=v2.1.1.0-1

# NOTE: ansible UID must match UID specified in roles/base/vars/main.yml
ENV ANSIBLE_UID=2000

ADD requirements.pip /
RUN apt-get -yqq install libffi-dev libssl-dev libyaml-dev
RUN git clone -b $ANSIBLE_BRANCH --recursive $ANSIBLE_URL /app && \
    cd /app && \
    groupadd -g $ANSIBLE_UID ansible && \
    useradd -m ansible -u $ANSIBLE_UID -g $ANSIBLE_UID && \
    python setup.py install && \
    rm -rf /app
RUN pip install -r requirements.pip

COPY src /etc/ansible 
RUN chown -Rf ansible. /etc/ansible && \
    cp -v /etc/ansible/scripts/main /usr/local/sbin

USER ansible
WORKDIR /etc/ansible/plays
ENTRYPOINT [ "ansible" ] 
