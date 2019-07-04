install_redis() {

yum -y install lrzsz iftou htop telnet
mkdir -pv /data/conf/redis
mkdir -pv /data/logs/redis
mkdir -pv /data/redis
cd /usr/local/src
wget http://download.redis.io/releases/redis-2.8.8.tar.gz
tar xf /usr/local/src/redis-2.8.8.tar.gz
cd /usr/local/src/redis-2.8.8
make
make PREFIX=/usr/local/redis install
cp /usr/local/src/redis-2.8.8/redis.conf /data/conf/redis/
sed -i 's@daemonize no@daemonize yes@g' /data/conf/redis/redis.conf
sed -i 's@pidfile /var/run/redis.pid@pidfile /data/redis/6379.pid@g' /data/conf/redis/redis.conf
sed -i 's@dir ./@dir /data/redis/@g' /data/conf/redis/redis.conf
chown -R nobody.nobody /data/conf/redis
chown -R nobody.nobody /data/logs/redis
chown -R nobody.nobody /data/redis
if [ ! -f /etc/init.d/redis ];then
cat> /etc/init.d/redis << 'EOF'
#!/bin/sh
#
# redis - this script starts and stops the redis-server daemon
#
# chkconfig:   - 85 15
# description:  Redis is a persistent key-value database
# processname: redis-server

redis="/usr/local/redis/bin/redis-server"
prog=$(basename $redis)
config="/data/conf/redis/redis.conf"
pidFile="/data/redis/6379.pid"

start() {
    [ -x $redis ] || exit 5
    echo -n $"Starting $prog: "
    su -c "$redis $config" nobody -s /bin/bash
    retval=$?
    echo
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    if [ -f "$pidFile" ]; then
        kill `cat $pidFile`
    fi
    retval=$?
    echo
    return $retval
}

restart() {
    stop
    sleep 1
    start
}

reload() {
    echo -n $"Reloading $prog: "
    if [ -f "$pidFile" ]; then
        kill -HUP `cat $pidFile`
    fi
    retval=$?
    echo
    return $retval
}

force_reload() {
    restart
}

case "$1" in
    start)
        $1
        ;;
    stop)
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        $1
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|reload}"
        exit 2
esac
EOF
fi
chmod +x /etc/init.d/redis
chkconfig --add redis
chkconfig redis on
}
install_redis