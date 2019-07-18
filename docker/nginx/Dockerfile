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
    && groupadd -g 101 -r nginx \
    && useradd -u 101 -d /var/cache/nginx -s /sbin/nologin -g nginx nginx \
    && cd /usr/local/src \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && wget -O ngx_http_secure_download.zip https://github.com/replay/ngx_http_secure_download/archive/master.zip \
    && unzip ngx_http_secure_download.zip \
    && wget -O nginx-push-stream-module.zip https://github.com/wandenberg/nginx-push-stream-module/archive/master.zip \
    && unzip nginx-push-stream-module.zip \
    && tar xf nginx.tar.gz \
    && cd nginx-$NGINX_VERSION \
    && ./configure \
    		--user=nginx \
    		--group=nginx \
    		--prefix=/etc/nginx \
    		--sbin-path=/usr/sbin/nginx \
    		--conf-path=/etc/nginx/nginx.conf \
    		--modules-path=/usr/lib/nginx/modules \
    		--error-log-path=/var/log/nginx/error.log \
    		--http-log-path=/var/log/nginx/access.log \
    		--pid-path=/var/run/nginx.pid \
    		--lock-path=/var/run/nginx.lock \
    		--http-client-body-temp-path=/var/cache/nginx/client_temp \
    		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    		--with-http_stub_status_module \
    		--with-http_ssl_module \
    		--with-pcre \
    		--with-pcre-jit \
    		--with-http_gzip_static_module \
    		--with-http_realip_module \
                --with-http_addition_module \
                --with-http_sub_module \
                --with-http_dav_module \
                --with-http_flv_module \
                --with-http_mp4_module \
                --with-http_gunzip_module \
                --with-http_random_index_module \
                --with-http_secure_link_module \
                --with-http_auth_request_module \
                --with-http_xslt_module=dynamic \
                --with-http_image_filter_module=dynamic \
                --with-http_geoip_module=dynamic \
                --with-threads \
                --with-stream \
                --with-stream_ssl_module \
                --with-stream_ssl_preread_module \
                --with-stream_realip_module \
                --with-stream_geoip_module=dynamic \
                --with-http_slice_module \
                --with-mail \
                --with-mail_ssl_module \
                --with-compat \
                --with-file-aio \
                --with-http_v2_module \
    		--add-module=../nginx-push-stream-module-master \
    		--add-module=../ngx_http_secure_download-master \
        \
        && make -j `grep processor /proc/cpuinfo|wc -l` \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/ngx_http_xslt_filter_module.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module.so \
	&& install -m755 objs/ngx_http_image_filter_module.so /usr/lib/nginx/modules/ngx_http_image_filter_module.so \
	&& install -m755 objs/ngx_http_geoip_module.so /usr/lib/nginx/modules/ngx_http_geoip_module.so \
	&& install -m755 objs/ngx_stream_geoip_module.so /usr/lib/nginx/modules/ngx_stream_geoip_module.so \
	&& ln -s /usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/local/src/nginx-* \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
        && yum clean all

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
