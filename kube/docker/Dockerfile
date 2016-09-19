FROM debian:8.5
RUN apt-get update -y
RUN apt-get install -y iptables-persistent
COPY ./hyperkube /usr/local/bin/hyperkube
CMD ["hyperkube"]
