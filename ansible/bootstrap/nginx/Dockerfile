FROM __image_prefix__/base:latest
ENV version=2

ENV NGINX_VERSION 1.9.12
ENV SRC_DIR /usr/local/src

#install build packages and module deps
RUN apt-get -qq update && \
    apt-get install -yqq build-essential \
                         zlib1g-dev \
                         libpcre3-dev \
                         libssl-dev \
                         libxslt1-dev \
                         libxml2-dev \
                         libgd2-xpm-dev \
                         libgeoip-dev \
                         libgoogle-perftools-dev \
                         libperl-dev

WORKDIR $SRC_DIR
ADD tcp.patch /tmp

RUN git clone https://github.com/yaoweibin/nginx_tcp_proxy_module.git

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd ${SRC_DIR}/nginx-${NGINX_VERSION}/ && \
		patch -p1 < /tmp/tcp.patch && \
    ./configure --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/var/run/nginx.pid \
                --lock-path=/var/run/nginx.lock \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                --user=nginx \
                --group=nginx \
                --add-module=${SRC_DIR}/nginx_tcp_proxy_module/  \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_addition_module \
                --with-http_sub_module \
                --with-http_geoip_module \
                --with-http_gunzip_module \
                --with-http_gzip_static_module \
                --with-http_random_index_module \
                --with-http_secure_link_module \
                --with-http_stub_status_module \
                --with-http_auth_request_module \
                --with-mail \
                --with-mail_ssl_module \
                --with-file-aio \
                --with-http_v2_module \
                --with-cc-opt='-g \
                -O2 \
                -fstack-protector \
                --param=ssp-buffer-size=4 \
                -Wformat \
                -Wformat-security \
                -Wp,-D_FORTIFY_SOURCE=2' \
                --with-ld-opt='-Wl,-Bsymbolic-functions \
                -Wl,-z,relro \
                -Wl,--as-needed' \
                --with-ipv6 && \
     make && make install
