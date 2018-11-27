瓦力安装部署文档

一、软件版本
```
Nginx：1.12.0
MYSQL:mysql-5.6.40
PHP:php-7.0.6
```
二、安装nginx
```
# vim nginx_install.sh
#!/bin/bash
#
# 安装依赖环境
yum -y groupinstall "Development tools"
yum -y install \
                  libxml2 \
                  libxml2-devel \
                  openssl-devel \
                  bzip2 \
                  bzip2-devel \
                  libcurl-devel \
                  libjpeg \
                  libjpeg-devel \
                  libpng-devel \
                  libicu-devel \
                  libmcrypt-devel \
                  freetype-devel \
                  postgresql-devel \
                  libtidy \
                  libtidy-devel \
                  ImageMagick-devel \
                  mhash \
                  mhash-devel \
                  pcre-devel \
                  wget \
                  net-tools \
                  lrzsz

# 安装nginx
install_nginx() {
  useradd www
  mkdir -pv /data/conf/nginx
  mkdir -pv /data/logs/nginx
  mkdir -pv /data/software
  mkdir -pv /data/run
  cd /data/software \
  && wget -O ngx_http_secure_download.zip https://github.com/replay/ngx_http_secure_download/archive/master.zip \
  && unzip ngx_http_secure_download.zip \
  && wget -O nginx-push-stream-module.zip https://github.com/wandenberg/nginx-push-stream-module/archive/master.zip \
  && unzip nginx-push-stream-module.zip \
  && wget http://nginx.org/download/nginx-1.12.0.tar.gz \
  && tar xf nginx-1.12.0.tar.gz \
  && cd nginx-1.12.0 \
  && ./configure \
    --user=nobody \
    --group=nobody \
    --prefix=/usr/local/nginx \
    --conf-path=/data/conf/nginx/nginx.conf \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --add-module=../nginx-push-stream-module-master \
    --with-pcre \
    --with-pcre-jit \
    --with-http_gzip_static_module \
    --add-module=../ngx_http_secure_download-master \
  && make -j `grep processor /proc/cpuinfo|wc -l` \
  && make install \
  && sed -i 's@#pid        logs/nginx.pid;@pid        /data/run/nginx.pid;@g' /data/conf/nginx/nginx.conf


if [ ! -f /etc/init.d/nginx ];then
cat> /etc/init.d/nginx << 'EOF'
#! /bin/sh
# chkconfig: 2345 55 25
# Description: Startup script for nginx webserver on Debian. Place in /etc/init.d and
# run 'update-rc.d -f nginx defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add nginx'
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="nginx daemon"
NAME=nginx
DAEMON=/usr/local/nginx/sbin/$NAME
CONFIGFILE=/data/conf/nginx/$NAME.conf
PIDFILE=/data/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

set -e
[ -x "$DAEMON" ] || exit 0
do_start() {
  $DAEMON -c $CONFIGFILE || echo -n "nginx already running"
}
do_stop() {
  kill `cat $PIDFILE` || echo -n "nginx not running"
}
do_reload() {
  kill -HUP `cat $PIDFILE` || echo -n "nginx can't reload"
}
case "$1" in
start)
echo -n "Starting $DESC: $NAME"
do_start
echo "."
;;
stop)
echo -n "Stopping $DESC: $NAME"
do_stop
echo "."
;;
reload|graceful)
echo -n "Reloading $DESC configuration..."
do_reload
echo "."
;;
restart)
echo -n "Stopping $DESC: $NAME"
do_stop
echo "."
usleep 100000
echo -n "Restarting $DESC: $NAME"
do_start
echo "."
;;
*)
echo "Usage: $SCRIPTNAME {start|stop|reload|restart}" >&2
exit 3
;;
esac
exit 0
EOF
fi
sed -i 's@#user nobody;@user www;@g' /data/conf/nginx/nginx.conf
chmod +x /etc/init.d/nginx
chkconfig --add nginx
/etc/init.d/nginx start
}
install_nginx

# bash -x nginx_install.sh
```
三、安装php

```
# vim php_install.sh
#!/bin/bash
#
install_php() {
yum -y groupinstall "Development tools"
yum -y install \
                  libxml2 \
                  libxml2-devel \
                  openssl-devel \
                  bzip2 \
                  bzip2-devel \
                  libcurl-devel \
                  libjpeg \
                  libjpeg-devel \
                  libpng-devel \
                  libicu-devel \
                  libmcrypt-devel \
                  freetype-devel \
                  postgresql-devel \
                  libtidy \
                  libtidy-devel \
                  ImageMagick-devel \
                  mhash \
                  mhash-devel \
                  pcre-devel \
                  wget

  mkdir -pv /data/conf/php7/
  mkdir /data/logs/php7/ -pv
  cd /usr/local/src
  wget -O php.tar.xz "http://mirrors.sohu.com/php/php-7.0.6.tar.xz"
  mkdir /usr/local/src/php
  tar -Jxf /usr/local/src/php.tar.xz -C /usr/local/src/php --strip-components=1
  cd /usr/local/src/php
  ./configure \
     --prefix=/usr/local/php7 \
     --sysconfdir=/data/conf/php7 \
     --with-config-file-path=/data/conf/php7 \
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
     --enable-sysvshm \
     --with-tidy \
     --enable-inline-optimization \
     --with-curl \
     --enable-mbregex \
     --enable-mbstring \
     --with-mcrypt \
     --with-gd \
     --enable-gd-native-ttf \
     --with-openssl --with-mhash \
     --enable-pcntl \
     --enable-sockets \
     --with-xmlrpc \
     --enable-soap \
     --enable-intl \
     --with-pdo-pgsql \
     --enable-fpm \
     --enable-debug
  make
  make install

cp php.ini-production /data/conf/php7/php.ini

if [ ! -f /etc/init.d/php7-fpm ];then
cat> /etc/init.d/php7-fpm << 'EOF'
#! /bin/sh
### BEGIN INIT INFO
# Provides:          php-fpm
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts php-fpm
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO
prefix=/usr/local/php7
exec_prefix=${prefix}
php_fpm_BIN=${exec_prefix}/sbin/php-fpm
php_fpm_CONF=/data/conf/php7/php-fpm.conf
php_fpm_PID=${prefix}/var/run/php-fpm.pid
php_ini=/data/conf/php7/php.ini
php_opts="-c $php_ini --fpm-config $php_fpm_CONF --pid $php_fpm_PID"
wait_for_pid () {
  try=0
  while test $try -lt 35 ; do
    case "$1" in
      'created')
      if [ -f "$2" ] ; then
        try=''
        break
      fi
      ;;
      'removed')
      if [ ! -f "$2" ] ; then
        try=''
        break
      fi
      ;;
    esac
    echo -n .
    try=`expr $try + 1`
    sleep 1
  done
}
case "$1" in
  start)
    echo -n "Starting php-fpm "
    $php_fpm_BIN --daemonize $php_opts
    if [ "$?" != 0 ] ; then
      echo " failed"
      exit 1
    fi
    wait_for_pid created $php_fpm_PID
    if [ -n "$try" ] ; then
      echo " failed"
      exit 1
    else
      echo " done"
    fi
  ;;
  stop)
    echo -n "Gracefully shutting down php-fpm "
    if [ ! -r $php_fpm_PID ] ; then
      echo "warning, no pid file found - php-fpm is not running ?"
      exit 1
    fi
    kill -QUIT `cat $php_fpm_PID`
    wait_for_pid removed $php_fpm_PID
    if [ -n "$try" ] ; then
      echo " failed. Use force-quit"
      exit 1
    else
      echo " done"
    fi
  ;;
  status)
    if [ ! -r $php_fpm_PID ] ; then
      echo "php-fpm is stopped"
      exit 0
    fi
    PID=`cat $php_fpm_PID`
    if ps -p $PID | grep -q $PID; then
      echo "php-fpm (pid $PID) is running..."
    else
      echo "php-fpm dead but pid file exists"
    fi
  ;;
  force-quit)
    echo -n "Terminating php-fpm "
    if [ ! -r $php_fpm_PID ] ; then
      echo "warning, no pid file found - php-fpm is not running ?"
      exit 1
    fi
    kill -TERM `cat $php_fpm_PID`
    wait_for_pid removed $php_fpm_PID
    if [ -n "$try" ] ; then
      echo " failed"
      exit 1
    else
      echo " done"
    fi
  ;;
  restart)
    $0 stop
    $0 start
  ;;
  reload)
    echo -n "Reload service php-fpm "
    if [ ! -r $php_fpm_PID ] ; then
      echo "warning, no pid file found - php-fpm is not running ?"
      exit 1
    fi
    kill -USR2 `cat $php_fpm_PID`
    echo " done"
  ;;
  configtest)
    $php_fpm_BIN -t
  ;;
  *)
    echo "Usage: $0 {start|stop|force-quit|restart|reload|status|configtest}"
    exit 1
  ;;
esac
EOF
fi
chmod +x /etc/init.d/php7-fpm
chkconfig --add php7-fpm
chkconfig php7-fpm on


cd /usr/local/src \
&& wget http://pecl.php.net/get/imagick-3.4.3.tgz \
&& tar xf imagick-3.4.3.tgz \
&& cd imagick-3.4.3 \
&& /usr/local/php7/bin/phpize \
&& ./configure --with-php-config=/usr/local/php7/bin/php-config \
&& make && make install \
&& cd /usr/local/src \
&& wget http://pecl.php.net/get/redis-3.1.2.tgz \
&& tar xf redis-3.1.2.tgz \
&& cd redis-3.1.2 \
&& /usr/local/php7/bin/phpize \
&& ./configure --with-php-config=/usr/local/php7/bin/php-config \
&& make && make install \
&& ln -sv /usr/local/php7 /usr/local/php \
&& cp /data/conf/php7/php-fpm.conf.default /data/conf/php7/php-fpm.conf \
&& cp /data/conf/php7/php-fpm.d/www.conf.default /data/conf/php7/php-fpm.d/www.conf \
&& sed -i 's@user = nobody@user = www@g' /data/conf/php7/php-fpm.d/www.conf \
&& sed -i 's@group = nobody@group = www@g' /data/conf/php7/php-fpm.d/www.conf \
&& echo "export PATH=$PATH:/usr/local/php/bin" >> /etc/profile \
&& source /etc/profile \
&& /etc/init.d/php7-fpm start
}
install_php

# bash php_install.sh
```
四、安装mysql5.6
```
1、下载源码包

# cd/usr/local/src
下载mysql5.6.40二进制包
# wget http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.40-linux-glibc2.12-x86_64.tar.gz
# tar xf  mysql-5.6.40-linux-glibc2.12-x86_64.tar.gz -C /usr/local
# ln -sv mysql-5.6.40-linux-glibc2.12 mysql
# chown -R root.mysql /usr/local/mysql


2、安装

# yum -y install cmake gcc gcc-c++ bison ncurses ncurses-devel
# groupadd -g 306 mysql
# useradd -g mysql -u 306 -s /sbin/nologin -M mysql
# mkdir /data/mysql -pv
# chown -R mysql.mysql /data/mysql

3、配置

设置权限
# chown -R mysql:mysql /data/mysql
添加配置文件
# vim /etc/my.cnf
[mysqld] 
port=3306 
basedir=/usr/local/mysql 
datadir=/data/mysql 
character-set-server=utf8 
default-storage-engine=InnoDB 
max_connections=5120 
  
query_cache_size=0 
tmp_table_size=18M 
log-error = /data/mysql/mysql-error.log
  
thread_cache_size=8 
myisam_max_sort_file_size=64G 
myisam_sort_buffer_size=35M 
key_buffer_size=25M 
read_buffer_size=64K 
read_rnd_buffer_size=256K 
sort_buffer_size=256K 
  
innodb_flush_log_at_trx_commit=1 
innodb_log_buffer_size=1M 
innodb_buffer_pool_size=47M 
innodb_log_file_size=24M 
innodb_thread_concurrency=8 
 
初始化mysql 
/usr/local/mysql/scripts/mysql_install_db \
--user=mysql \ 
--basedir=/usr/local/mysql \ 
--datadir=/data/mysql 
添加MySQL环境变量
# echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile
# source /etc/profile
导出头文件
# ln -sv /usr/local/mysql/include /usr/include/mysqld
导出库文件
# echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
# ldconfig
添加启动脚本
# cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
# chmod +x /etc/init.d/mysqld
# chkconfig --add mysqld
# /etc/init.d/mysqld start

```
五、部署walle
```
1、安装php composer
# cd /usr/local/src
# curl -sS https://getcomposer.org/installer | php 
# mv composer.phar /usr/local/bin/composer       # PATH目录
2、代码检出
mkdir -p /data/www/walle-web && cd /data/www/walle-web  # 新建目录
git clone https://github.com/meolu/walle-web.git .      # 代码检出
3、设置mysql连接
# 授权账户，并创建数据库
mysql> create database walle;
mysql> grant all on walle.* to walle@'localhost' identified by 'walle';
mysql> flush privileges;

# vim config/local.php +14
'db' => [
    'dsn'       => 'mysql:host=localhost;dbname=walle', # 新建数据库walle
    'username'  => 'walle',                          # 连接的用户名
    'password'  => 'walle',                          # 连接的密码
],

4、安装vendor
# cd walle-web

# composer install --prefer-dist --no-dev --optimize-autoloader -vvvv

5、初始化项目
cd walle-web
./yii walle/setup # 需要你的yes

6.配置nginx
凡是在第7步刷新页面看到50x均是前5步安装不完整，自行检查
凡是在第7步刷新页面看到404均是nginx配置不当，自行检查

nginx简单配置

server {
    listen       80;
    server_name  walle.compony.com; # 改你的host
    root /the/dir/of/walle-web/web; # 根目录为web
    index index.php;

    # 建议放内网
    # allow 192.168.0.0/24;
    # deny all;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri = 404;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}


7、恭喜：）
访问地址：localhost

当然，可能你配置nginx时的server_name是walle.company.com时，配置本地hosts之后，直接访问：walle.company.com亦可。
```
