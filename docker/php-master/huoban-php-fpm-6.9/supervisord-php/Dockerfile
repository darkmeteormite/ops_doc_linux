FROM centos:6.9

MAINTAINER HuoBan Docker Maintainers "zhangqiang@huoban.com"

COPY epel.repo /etc/yum.repos.d/server.repo

RUN set -ex ;\
         yum -y install postgresql10 \
                postgresql10-devel \
		autoconf \
		file \
		gcc \
		zip \
		make \
		wget \
                gcc-c++ \
		libxml2-devel \
		libcurl-devel \
        	libedit-devel \
                libicu-devel \
		libpng-devel \
	        libjpeg-devel \
		libmcrypt \
	        libmcrypt-devel \
                libtidy-devel \
 		bzip2-devel \
                ImageMagick-devel \
	        freetype \
		freetype-devel \
		mhash-devel \
       		openssl-devel \
        	curl-devel \
		libXrender \
                pcre-devel \
		supervisor \
                crontabs \
		libXext ; \
	yum clean all


RUN set -ex ;\
        cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
        mkdir -p /data/conf/php7 ;\
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O php.tar.gz "http://mirrors.sohu.com/php/php-7.0.6.tar.gz";\
	mkdir /usr/src/php;tar xf /usr/src/php.tar.gz -C /usr/src/php --strip-components=1 \
	&& cd /usr/src/php \
	&& ./configure \
                --prefix="/usr/local/php7" \
		--with-config-file-path="/data/conf/php7" \
		--sysconfdir="/data/conf/php7" \
                --enable-mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
                --with-iconv \
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--enable-zip \
		--with-zlib \
                --with-bz2 \
                --enable-calendar \
                --enable-exif \
		--with-libxml-dir \
		--enable-xml \
                --disable-rpath \
                --disable-short-tags \
                --enable-bcmath \
                --enable-shmop \
                --enable-sysvmsg \
                --enable-sysvsem \
                --with-tidy \
                --enable-inline-optimization \
		--with-curl \
                --enable-mbregex \
		--enable-mbstring \
		--with-mcrypt \
		--with-gd \
		--enable-gd-native-ttf \
		--with-openssl \
                --with-mhash \
                --enable-pcntl \
                --enable-sockets \
                --with-xmlrpc \
                --enable-soap \
                --enable-intl \
                --with-pdo-pgsql=/usr/pgsql-10/bin \
                --with-pgsql=/usr/pgsql-10/include \
		--disable-cgi \
		--enable-ftp \
		--enable-fpm \
		--with-libedit \
        && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
	&& make -j $NPROC \
	&& make install \
        && cp php.ini-production /data/conf/php7/php.ini \
        && sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@g' /data/conf/php7/php.ini \
	&& { find /usr/local/php7/bin /usr/local/php7/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
        && cd /usr/src/ \
        && rm -rf /usr/src/*


RUN set -ex \
	&& cd /data/conf/php7 \
	&& if [ -d php-fpm.d ]; then \
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi \
	&& { \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf \
	&& { \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = [::]:9000'; \
	} | tee php-fpm.d/zz-docker.conf \
        && sed -i 's@pm.max_children = 5@pm.max_children = 100@g' /data/conf/php7/php-fpm.d/www.conf \
        && sed -i 's@pm.start_servers = 2@pm.start_servers = 10@g' /data/conf/php7/php-fpm.d/www.conf \
        && sed -i 's@pm.min_spare_servers = 1@pm.min_spare_servers = 5@g' /data/conf/php7/php-fpm.d/www.conf \
        && sed -i 's@pm.max_spare_servers = 3@pm.max_spare_servers = 20@g' /data/conf/php7/php-fpm.d/www.conf \
        && sed -i 's@upload_max_filesize = 2M@upload_max_filesize = 200M@g' /data/conf/php7/php.ini \
        && cd /usr/src \
        && wget http://pecl.php.net/get/imagick-3.4.3.tgz  \
        && tar xf imagick-3.4.3.tgz \
        && cd imagick-3.4.3 \
        && /usr/local/php7/bin/phpize \
        && ./configure --with-php-config=/usr/local/php7/bin/php-config \
        && make \
        && make install \
        && cd /usr/src \
	&& wget http://pecl.php.net/get/redis-3.1.2.tgz \
        && tar xf redis-3.1.2.tgz \
        && cd redis-3.1.2 \
        && sh /usr/local/php7/bin/phpize \
        && ./configure --with-php-config=/usr/local/php7/bin/php-config \
        && make \
        && make install \
        && cd /usr/src \
        && rm -rf /usr/src/* 



RUN set -ex \
        && ln -s /usr/local/php7 /usr/local/php \
        && ln -s /usr/local/php7/bin/php /usr/local/bin/huoban_php \
        && ln -s /usr/local/php7/bin/* /usr/local/bin/ \
        && ln -s /usr/local/php7/sbin/php-fpm /usr/local/bin/php-fpm \
        && useradd -g 100 -u 100 user_00 \
        && ln -s /usr/pgsql-10 /usr/local/pgsql \
        && touch /var/log/cron \
        && chmod 600 /var/log/cron \
        && sed -i '/session    required   pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/crond


COPY supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
