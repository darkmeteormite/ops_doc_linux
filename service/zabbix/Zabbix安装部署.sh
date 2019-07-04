一、基础软件安装
1、软件版本
Nginx：1.8.0
MYSQL:mysql-5.6.22
PHP:php-5.6.9
Zabbix：2.2.10（rpm包）
 
2、基础环境安装
首先安装开发组包
 
[root@zabbix ~]# yum -y groupinstall "Development tools,Desktop platform development"                  
 
3、防火墙调试
[root@zabbix ~]# setenforce 0
[root@zabbix ~]# getenforce 
Permissive
[root@zabbix ~]# service iptables stop
 
4、时区同步
[root@zabbix ~]# yum -y install ntpdate
[root@zabbix ~]# ntpdate asia.pool.ntp.org
22 Dec 14:24:34 ntpdate[24098]: step time server 59.149.185.193 offset 1.163028 sec
 
5、安装mysql（二进制程序安装）
[root@zabbix soft]# groupadd -g 306 mysql
[root@zabbix soft]# useradd -g 306 -u 306 -s /sbin/nologin -M mysql
[root@zabbix soft]# mkdir -pv /u01/mysql/{data,log}
[root@zabbix soft]# chown -R mysql.mysql /u01/mysql/data
[root@zabbix soft]# chown -R mysql.mysql /u01/mysql/log
[root@zabbix soft]# tar xf mysql-5.6.22-linux-glibc2.5-x86_64.tar.gz -C /usr/local
[root@zabbix soft]# cd /usr/local
[root@zabbix local]# ln -sv mysql-5.6.22-linux-glibc2.5-x86_64/ mysql
[root@zabbix local]# cd mysql
[root@zabbix mysql]# chown root.mysql ./*
[root@zabbix mysql]# scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql 
--datadir=/u01/mysql/data
 
[root@zabbix mysql]# vim /etc/my.cnf
[mysqld]
datadir = /u01/mysql/data    #数据目录
socket = /tmp/mysql.sock
pid-file = /tmp/mysql.pid
log_error = /var/log/mysql/mysql.log
log-bin = /u01/mysql/log/mysql-bin    #log-bin文件存放目录
log-bin-index = /u01/mysql/log/mysql-bin.index
expire_logs_days = 30      #超过30天的binlog删除
basedir = /usr/local/mysql
character_set_server = utf8      #server级别字符集
default_storage_engine = InnoDB   #默认存储
innodb_buffer_pool_size = 4000M    #主要作用是缓存innodb表的索引，数据，插入数据时的缓冲
explicit_defaults_for_timestamp = true    #开启查询缓存
 
[root@zabbix mysql]# cp support-files/mysql.server /etc/rc.d/init.d/mysqld
[root@zabbix mysql]# chmod +x /etc/rc.d/init.d/mysqld
[root@zabbix mysql]# chkconfig --add mysqld
[root@zabbix mysql]# chkconfig mysqld on
[root@zabbix mysql]# echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
 
[root@zabbix mysql]# ln -sv /usr/local/mysql/include /usr/include/mysqld
 
[root@zabbix mysql]# ldconfig 
[root@zabbix mysql]# ldconfig -p | grep mysql
libtcmalloc_minimal.so.0 (libc6,x86-64) => /usr/local/mysql/lib/libtcmalloc_minimal.so.0
libmysqlclient.so.18 (libc6,x86-64) => /usr/lib64/mysql/libmysqlclient.so.18
libmysqlclient.so.18 (libc6,x86-64) => /usr/local/mysql/lib/libmysqlclient.so.18
libmysqlclient.so (libc6,x86-64) => /usr/local/mysql/lib/libmysqlclient.so
[root@zabbix mysql]# echo "export PATH=/usr/local/mysql/bin:$PATH" > /etc/profile.d/mysql.sh
 
[root@zabbix mysql]# source /etc/profile.d/mysql.sh
[root@zabbix mysql]# vim /etc/man.config     
                     MANPATH /usr/local/mysql/man
[root@zabbix mysql]# mkdir /var/log/mysql
[root@zabbix mysql]# service mysqld start
Starting MySQL.                                            [  OK  ]
[root@zabbix mysql]# ss -tnl
State      Recv-Q Send-Q                                         Local Address:Port   
LISTEN     0      128                                                        *:22 
LISTEN     0      100                                                127.0.0.1:25 
LISTEN     0      80                                                        :::3306 
LISTEN     0      128                                                       :::22  
LISTEN     0      100                                                      ::1:25
###mysql已经配置完毕
 
6、安装nginx
[root@zabbix nginx-1.8.0]# yum -y install pcre-devel openssl-devel
[root@zabbix nginx-1.8.0]# groupadd -r nginx
[root@zabbix nginx-1.8.0]# useradd -g nginx -r -s /sbin/nologin -M nginx
[root@zabbix soft]# tar xf nginx-1.8.0.tar.gz 
[root@zabbix soft]# cd nginx-1.8.0
 
[root@zabbix nginx-1.8.0]# ./configure \
   --prefix=/usr/local/nginx \
   --sbin-path=/usr/local/nginx/sbin/nginx \
   --conf-path=/usr/local/nginx/etc/nginx.conf \
   --error-log-path=/var/log/nginx/error.log \
   --http-log-path=/var/log/nginx/access.log \
   --pid-path=/var/run/nginx/nginx.pid  \
   --lock-path=/var/lock/nginx.lock \
   --user=nginx \
   --group=nginx \
   --with-http_ssl_module \
   --with-http_flv_module \
   --with-http_stub_status_module \
   --with-http_gzip_static_module \
   --http-client-body-temp-path=/var/tmp/nginx/client/ \
   --http-proxy-temp-path=/var/tmp/nginx/proxy/ \
   --http-fastcgi-temp-path=/var/tmp/nginx/fcgi/ \
   --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
   --http-scgi-temp-path=/var/tmp/nginx/scgi \
   --with-pcre
 
##注意：有些目录原来不存在
[root@zabbix ~]# mkdir -pv /var/tmp/nginx/{client,proxy,fcgi,uwsgi,scgi}
 
###################出现这就没问题了
Configuration summary
  + using system PCRE library
  + using system OpenSSL library
  + md5: using OpenSSL library
  + sha1: using OpenSSL library
  + using system zlib library
  nginx path prefix: "/usr/local/nginx"
  nginx binary file: "/usr/sbin/nginx"
  nginx configuration prefix: "/etc/nginx"
  nginx configuration file: "/etc/nginx/nginx.conf"
  nginx pid file: "/var/run/nginx/nginx.pid"
  nginx error log file: "/var/log/nginx/error.log"
  nginx http access log file: "/var/log/nginx/access.log"
  nginx http client request body temporary files: "/var/tmp/nginx/client/"
  nginx http proxy temporary files: "/var/tmp/nginx/proxy/"
  nginx http fastcgi temporary files: "/var/tmp/nginx/fcgi/"
  nginx http uwsgi temporary files: "/var/tmp/nginx/uwsgi"
  nginx http scgi temporary files: "/var/tmp/nginx/scgi"
[root@zabbix nginx-1.8.0]# echo $?
0
[root@zabbix nginx-1.8.0]# make && make install
[root@zabbix nginx-1.8.0]# echo $?
0
 
提供启动脚本
 
[root@zabbix nginx-1.8.0]# vim /etc/rc.d/init.d/nginx 
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemin
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# pidfile:     /var/run/nginx.pid
# Source function library.
. /etc/rc.d/init.d/functions
# Source networking configuration.
. /etc/sysconfig/network
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
nginx="/usr/sbin/nginx"
prog=$(basename $nginx)
NGINX_CONF_FILE="/etc/nginx/nginx.conf"
lockfile=/var/lock/subsys/nginx
start() {
   [ -x $nginx ] || exit 5
   [ -f $NGINX_CONF_FILE ] || exit 6
   echo -n $"Starting $prog: "
   daemon $nginx -c $NGINX_CONF_FILE
   retval=$?
   echo
   [ $retval -eq 0 ] && touch $lockfile
   return $retval
}
stop() {
   echo -n $"Stopping $prog: "
   killproc $prog -QUIT
   retval=$?
   echo
   [ $retval -eq 0 ] && rm -f $lockfile
   return $retval
}
restart() {
   configtest || return $?
   stop
   start
}
reload() {
   configtest || return $?
   echo -n $"Reloading $prog: "
   killproc $nginx -HUP
   RETVAL=$?
   echo
}
force_reload() {
   restart
}
configtest() {
 $nginx -t -c $NGINX_CONF_FILE
}
rh_status() {
   status $prog
}
rh_status_q() {
   rh_status >/dev/null 2>&1
}
case "$1" in
   start)
       rh_status_q && exit 0
       $1
       ;;
   stop)
       rh_status_q || exit 0
       $1
       ;;
   restart|configtest)
       $1
       ;;
   reload)
       rh_status_q || exit 7
       $1
       ;;
   force-reload)
       force_reload
       ;;
   status)
       rh_status
       ;;
   condrestart|try-restart)
       rh_status_q || exit 0
           ;;
   *)
       echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-
reload|configtest}"
       exit 2
esac
 
[root@zabbix local]# chmod +x /etc/rc.d/init.d/nginx
[root@zabbix local]# chkconfig --add nginx
[root@zabbix local]# service nginx start
 
[root@zabbix local]# ss -tnl
State       Recv-Q Send-Q  Local Address:Port                 Peer Address:Port              
LISTEN      0      128                 *:80                              *:*                  
LISTEN      0      128                 *:22                              *:*                  
LISTEN      0      100         127.0.0.1:25                              *:*                  
LISTEN      0      80                 :::3306                           :::*                  
LISTEN      0      128                :::22                             :::*                  
LISTEN      0      100               ::1:25                             :::* 
 
#######查看结果
[root@zabbix u01]# curl http://localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
 
7、安装PHP
######php的部分依赖 
[root@zabbix ~]# yum -y install bzip2-devel libmcrypt libmcrypt-devel libxslt-devel libxml2-devel
[root@zabbix ~]# yum -y install libjpeg-devel libpng-devel mhash mhash-devel freetype-devel
libtidy-devel glibc-utils libtool-ltdl-devel php-common php-mbstring php-gd php-odbc php-pear 
php-xml php-bcmath libpng libpng-devel libaio libaio-devel  
 
[root@zabbix local]# cd /u01/soft
[root@zabbix php]# tar xf php-5.6.9.tar.xz
[root@zabbix soft]# cd php-5.6.9
[root@zabbix php-5.6.9]# ./configure \
    --prefix=/usr/local/php \
    --enable-fpm \
    --with-mysql=mysqlnd  \
    --with-pdo-mysql=mysqlnd  \
    --with-mysqli=mysqlnd  \
    --with-xmlrpc \
    --with-openssl \
    --with-zlib \
    --with-freetype-dir \
    --with-gd \
    --with-jpeg-dir \
    --with-png-dir \
    --with-iconv \
    --enable-short-tags \
    --enable-sockets \
    --enable-soap \
    --enable-mbstring \
    --enable-static \
    --enable-gd-native-ttf \
    --with-curl \
    --with-xsl \
    --enable-ftp \
    --with-libxml-dir \
    --enable-bcmath \        
    --with-fpm-user=nginx \
    --with-fpm-group=nginx \
    --with-config-file-path=/etc \
    --with-config-file-scan-dir=/etc/php.d
#这是某运维老鸟说的他企业里都是这么配置的，不需要更改。可自行搜索
 
[root@zabbix php-5.6.9]# make && make install   #这里需要等待一段时间了，可以同时进行第三步操作
 
#############为php提供配置文件，以fastcgi方式监听在9000端口
[root@zabbix php-5.6.9]# cp sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm  
###########为php提供配置文件
[root@zabbix php-5.6.9]# chmod +x /etc/rc.d/init.d/php-fpm
[root@zabbix php-5.6.9]# chkconfig --add php-fpm
[root@zabbix php-5.6.9]# chkconfig php-fpm on
[root@zabbix php-5.6.9]# chkconfig --list php-fpm
php-fpm         0:off   1:off   2:on    3:on    4:on    5:on    6:off
[root@zabbix php-5.6.9]# cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
##############如果要实现php和web服务分离可以编辑此文件，这里保持默认
 
##启动php-fpm
[root@zabbix etc]# service php-fpm start
Starting php-fpm  done
 
#####注意
#1、这里启动可能会出现问题。php很多动态模块加载不上。如果是高手，请略过。
     如果没有做过的可以试一下，重新编译一边php，我这是这样解决的。
#2、版本与系统的模块不兼容，需要升级模块，，具体方法自己研究吧。测试出来的结果。。（用php5.5.x的没有问题）
 
 
[root@zabbix etc]# ss -tnl
State       Recv-Q Send-Q         Local Address:Port           Peer Address:Port 
LISTEN      0      128                127.0.0.1:9000                      *:*     
LISTEN      0      80                        :::3306                     :::*     
LISTEN      0      128                        *:80                        *:*   
 
#####安装与配置xcache加速器
[root@zabbix soft]# tar xf xcache-3.2.0.tar.bz2 
[root@zabbix soft]# cd xcache-3.2.0     ###注意要3.2版本才支持php5.6
   
[root@zabbix xcache-3.2.0]# /usr/local/php/bin/phpize  #注意这里要先解压xcache在运行此命令
Configuring for:
PHP Api Version:         20131106
Zend Module Api No:      20131226
Zend Extension Api No:   220131226
 
[root@zabbix xcache-3.2.0]# ./configure --enable-xcache --with-php-config=/usr/local/php/bin/php-config
 
[root@zabbix xcache-3.2.0]# make && make install
        
#注意输出的最后信息Installing shared extensions:     /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226/
        
[root@zabbix xcache-3.2.0]# mkdir /etc/php.d   #提供xcache扩展配置文件
[root@zabbix xcache-3.2.0]# cp xcache.ini /etc/php.d/
[root@zabbix xcache-3.2.0]# vim /etc/php.d/xcache.ini
 
[xcache-common]
;; non-Windows example:
extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226/xcache.so  ##修改这个路径
 
[root@edeiweiss0 xcache-3.2.0]# diff xcache.ini /etc/php.d/xcache.ini
4c4
< extension = xcache.so
---
> extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20090626/xcache.so
 
8、安装zabbix
###第一种方法[root@zabbix zabbix]# yum -y localinstall *.rpm     #这里用最简单的方法安装
###编译安装 （准备数据库，导入数据库）  
[root@first zabbix-2.4.7]# useradd -r zabbix
mysql> create database zabbix character set utf8;
Query OK, 1 row affected (0.00 sec)
 
mysql> grant all on zabbix.* to zabbix@'%' identified by 'xixihaha';
Query OK, 0 rows affected (0.04 sec)
 
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
 
[root@zabbix soft]# tar xf zabbix-2.2.10.tar.gz
[root@zabbix soft]# cd zabbix-2.2.10
[root@zabbix zabbix-2.2.10]# mysql zabbix < database/mysql/schema.sql 
[root@zabbix zabbix-2.2.10]# mysql zabbix < database/mysql/images.sql 
[root@zabbix zabbix-2.2.10]# mysql zabbix < database/mysqldata.sql 
###解决依赖关系
[root@zabbix zabbix-2.2.10]# yum -y install net-snmp net-snmp-devel perl-DBi
 
[root@zabbix zabbix-2.2.10]# ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent 
--with-mysql --enable-ipv6 --with-net-snmp --with-libcurl
 
[root@zabbix zabbix-2.2.10]# make install
二、配置各种接口交互
1、nginx和php交互
[root@zabbix php-5.6.9]# vim /www/index.php    ###php显示
welcome zabbix.
<?php
  echo phpinfo();
?>
 

2、nginx的php配置段

       location ~ \.php$ {
               root           /u01/www;
               fastcgi_pass   127.0.0.1:9000;
                fastcgi_index  index.php;
                fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
                include        fastcgi_params;
        }

3、服务端配置

[root@zabbix zabbix-2.2.10]# ln -sv /usr/local/mysql/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
`/usr/lib64/libmysqlclient.so.18` -> `/usr/local/mysql/lib/libmysqlclient.so.18`
 
[root@zabbix zabbix-2.2.10]# useradd -r zabbix
[root@zabbix zabbix-2.2.10]# cd /usr/local/zabbix
[root@zabbix zabbix]# cd etc
#配置服务端
[root@zabbix etc]# cat zabbix_server.conf |grep -v "#" |grep -v "^$" > zabbix_server.conf.bak
[root@zabbix etc]# mv zabbix_server.conf zabbix_server.conf.backup
[root@zabbix etc]# mv zabbix_server.conf.bak zabbix_server.conf
 
[root@zabbix etc]# vim zabbix_server.conf
    LogFile=/tmp/zabbix_server.log
    DBName=zabbix
    DBUser=zabbix
    DBPassword=xixihaha
        
#配置客户端       
[root@zabbix etc]# cat zabbix_agentd.conf | grep -v "#" | grep -v "^$" > zabbix_agentd.conf.bak
[root@zabbix etc]# mv zabbix_agentd.conf zabbix_agentd.conf.backup
[root@zabbix etc]# mv zabbix_agentd.conf.bak zabbix_agentd.conf
[root@zabbix etc]# vim zabbix_agentd.conf
    LogFile=/tmp/zabbix_agentd.log
    Server=127.0.0.1,192.168.9.9
    ServerActive=127.0.0.1
    Hostname=Zabbix server
    UnsafeUserParameters=1
 
#提供服务端启动脚本
[root@zabbix zabbix]# vim /etc/rc.d/init.d/zabbix-server
[root@zabbix zabbix]# chmod +x /etc/rc.d/init.d/zabbix-server
[root@zabbix zabbix]# chkconfig --add zabbix-server
 
#!/bin/sh
 
# Zabbix
# Copyright (C) 2001-2015 Zabbix SIA
#
# chkconfig:   - 86 15
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 
# Start/Stop the Zabbix server daemon.
# Place a startup script in /sbin/init.d, and link to it from /sbin/rc[023].d 
 
SERVICE="Zabbix server"
DAEMON=/usr/local/zabbix/sbin/zabbix_server
PIDFILE=/tmp/zabbix_server.pid
 
case $1 in
  'start')
    if [ -x ${DAEMON} ]
    then
      $DAEMON
      # Error checking here would be good...
      echo "${SERVICE} started."
    else
      echo "Can't find file ${DAEMON}."
      echo "${SERVICE} NOT started."
    fi
  ;;
  'stop')
    if [ -s ${PIDFILE} ]
    then
      if kill `cat ${PIDFILE}` >/dev/null 2>&1
      then
        echo "${SERVICE} terminated."
        rm -f ${PIDFILE}
      fi
    fi
  ;;
  'restart')
    $0 stop
    sleep 10
    $0 start
  ;;
  *)
    echo "Usage: $0 start|stop|restart"
    ;;
esac
 
#提供客户端启动脚本
[root@zabbix zabbix]# vim /etc/rc.d/init.d/zabbix-agentd 
[root@zabbix zabbix]# chmod +x /etc/rc.d/init.d/zabbix-agentd
[root@zabbix zabbix]# chkconfig --add zabbix-agentd
#!/bin/sh
 
# Zabbix
# Copyright (C) 2001-2015 Zabbix SIA
#
# chkconfig:   - 86 15
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 
# Start/Stop the Zabbix agent daemon.
# Place a startup script in /sbin/init.d, and link to it from /sbin/rc[023].d 
 
SERVICE="Zabbix agent"
DAEMON=/usr/local/zabbix/sbin/zabbix_agentd
PIDFILE=/tmp/zabbix_agentd.pid
 
case $1 in
  'start')
    if [ -x ${DAEMON} ]
    then
      $DAEMON
      # Error checking here would be good...
      echo "${SERVICE} started."
    else
      echo "Can't find file ${DAEMON}."
      echo "${SERVICE} NOT started."
    fi
  ;;
  'stop')
    if [ -s ${PIDFILE} ]
    then
      if kill `cat ${PIDFILE}` >/dev/null 2>&1
      then
        echo "${SERVICE} terminated."
        rm -f ${PIDFILE}
      fi
    fi
  ;;
  'restart')
    $0 stop
    sleep 10
    $0 start
  ;;
  *)
    echo "Usage: $0 start|stop|restart"
    ;;
esac



三、安装zabbix界面
1、复制web文件
[root@zabbix zabbix-2.2.10]# cp -a frontends/php/* /u01/www

2、php差一个模块补上
[root@zabbix ~]# cd /u01/soft/php-5.5.30/ext/gettext/
[root@zabbix gettext]# /usr/local/php/bin/phpize
Configuring for:
PHP Api Version:         20121113
Zend Module Api No:      20121212
Zend Extension Api No:   220121212
[root@zabbix gettext]# ./configure --with-php-config=/usr/local/php/bin/php-config
[root@zabbix gettext]# make && make install
[root@zabbix gettext]# vim /etc/php.ini
extension = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/gettext.so"    ##在末尾加入这一行
[root@zabbix gettext]# service php-fpm stop
[root@zabbix gettext]# service php-fpm start    ###重新打开网页

3、修改字体为中文，并解决乱码问题

[root@zabbix soft]# cd /u01/www
[root@zabbix www]# vim include/locales.inc.php
#####修改下面两行
    'zh_CN' => array('name' => _('Chinese (zh_CN)'),        'display' => true),
    'zh_TW' => array('name' => _('Chinese (zh_TW)'),        'display' => true),
#####到C:\windows\fonts 拷贝一个中文字体到zabbix网站fonts目录下替换掉就可以了（最好是微软雅黑）
[root@zabbix fonts]# rm -rf DejaVuSans.ttf 
[root@zabbix fonts]# mv msyh.ttf DejaVuSans.ttf