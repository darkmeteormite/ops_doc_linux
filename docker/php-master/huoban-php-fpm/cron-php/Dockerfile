FROM centos:7.6.1810

MAINTAINER HuoBan Docker Maintainers "zhangqiang@huoban.com"

COPY epel.repo /etc/yum.repos.d/server.repo

RUN set -ex ;\
	yum install -y \
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
		postgresql \
    		postgresql-libs \
		postgresql-devel \
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


ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-bz2 --enable-calendar --enable-exif  --disable-rpath --disable-short-tags --enable-bcmath --enable-shmop --enable-sysvmsg --enable-sysvsem --with-tidy --enable-inline-optimization  --enable-mbregex  --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --enable-intl --with-pdo-pgsql
ENV PHP_URL="http://mirrors.sohu.com/php/php-7.0.6.tar.xz"

RUN set -ex ;\
        cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
        mkdir -p /usr/local/etc/conf.d && useradd www-data;\
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O php.tar.xz "$PHP_URL";\
	mkdir /usr/src/php;tar -Jxf /usr/src/php.tar.xz -C /usr/src/php --strip-components=1 \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="/usr/local/etc/" \
		--with-config-file-scan-dir="/usr/local/etc/conf.d" \
		--with-gd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-libxml-dir \
		--with-iconv \
		--enable-xml \
		--disable-cgi \
		--enable-ftp \
		--enable-mbstring \
		--enable-gd-native-ttf \
		--enable-mysqlnd \
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		--with-mcrypt \
		--with-jpeg-dir \
		--with-freetype-dir \
		--with-png-dir \
		--enable-zip \
		$PHP_EXTRA_CONFIGURE_ARGS \
        && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
	&& make -j $NPROC \
	&& make install \
        && cp php.ini-production /usr/local/etc/conf.d/php.ini \
        && sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@g' /usr/local/etc/conf.d/php.ini \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
        && cd /usr/src/ \
        && rm -rf php*


RUN set -ex \
	&& cd /usr/local/etc \
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
        && sed -i 's@pm.max_children = 5@pm.max_children = 100@g' /usr/local/etc/php-fpm.d/www.conf \
        && sed -i 's@pm.start_servers = 2@pm.start_servers = 10@g' /usr/local/etc/php-fpm.d/www.conf \
        && sed -i 's@pm.min_spare_servers = 1@pm.min_spare_servers = 5@g' /usr/local/etc/php-fpm.d/www.conf \
        && sed -i 's@pm.max_spare_servers = 3@pm.max_spare_servers = 20@g' /usr/local/etc/php-fpm.d/www.conf \
        && sed -i 's@upload_max_filesize = 2M@upload_max_filesize = 200M@g' /usr/local/etc/conf.d/php.ini \
        && cd /usr/src \
        && wget http://pecl.php.net/get/imagick-3.4.3.tgz  \
        && tar xf imagick-3.4.3.tgz \
        && cd imagick-3.4.3 \
        && /usr/local/bin/phpize \
        && ./configure --with-php-config=/usr/local/bin/php-config \
        && make \
        && make install \
        && cd /usr/src \
	&& wget http://pecl.php.net/get/redis-3.1.2.tgz \
        && tar xf redis-3.1.2.tgz \
        && cd redis-3.1.2 \
        && sh /usr/local/bin/phpize \
        && ./configure --with-php-config=/usr/local/bin/php-config \
        && ln -s /usr/local/bin/php /usr/local/bin/huoban_php \
        && cd /usr/src \
        && rm -rf imagick* \
        && rm -rf redis* \
        && touch /var/log/cron.log 

COPY crontab /etc/cron.d/mq-cron

CMD ["crond && tail -f /var/log/cron.log"]
