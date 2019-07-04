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
  wget -O php.tar.xz "http://mirrors.sohu.com/php/php-7.2.9.tar.xz"
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
&& /etc/init.d/php7-fpm start
}
install_php