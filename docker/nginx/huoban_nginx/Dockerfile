FROM centos:7.6.1810

LABEL maintainer="zhangqiang@huoban.com"

ENV NGINX_VERSION 1.16.0

RUN curl -fSL http://mirrors.aliyun.com/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo \
 \
    && yum -y install unzip \
                  gcc \
		  make \
                  libxml2 \
                  gd-devel \
                  GeoIP-devel \
                  libxslt-devel \
                  libxml2-devel \
                  openssl-devel \
                  bzip2 \
                  bzip2-devel \
                  libcurl-devel \
                  libjpeg \
                  libjpeg-devel \
                  libpng-devel \
                  libicu-devel \
                  freetype-devel \
                  postgresql-devel \
                  ImageMagick-devel \
                  pcre-devel \
                  mhash-devel \
                  wget \
    && mkdir -p /data/conf/nginx \
    && mkdir -p /data/logs/nginx \
    && mkdir -p /data/run \
    && cd /usr/local/src \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && wget -O ngx_http_secure_download.zip https://github.com/replay/ngx_http_secure_download/archive/master.zip \
    && unzip ngx_http_secure_download.zip \
    && wget -O nginx-push-stream-module.zip https://github.com/wandenberg/nginx-push-stream-module/archive/master.zip \
    && unzip nginx-push-stream-module.zip \
    && tar xf nginx.tar.gz \
    && cd nginx-$NGINX_VERSION \
    && ./configure \
    		--user=nobody \
    		--group=nobody \
    		--prefix=/usr/local/nginx \
    		--sbin-path=/usr/sbin/nginx \
    		--conf-path=/data/conf/nginx/nginx.conf \
                --with-http_stub_status_module \
                --with-http_ssl_module \
                --with-pcre \
                --with-pcre-jit \
                --with-http_gzip_static_module \
    		--add-module=../nginx-push-stream-module-master \
    		--add-module=../ngx_http_secure_download-master \
        \
        && make -j `grep processor /proc/cpuinfo|wc -l` \
	&& make install \
	&& rm -rf /usr/local/src/nginx-* \
	&& ln -sf /dev/stderr /data/logs/nginx/error.log \
        && yum clean all

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
