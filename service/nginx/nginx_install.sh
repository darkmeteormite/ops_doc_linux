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
                  wget

# 安装nginx
install_nginx() {
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
chmod +x /etc/init.d/nginx
chkconfig --add nginx
/etc/init.d/nginx start
}
install_nginx