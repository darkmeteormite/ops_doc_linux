源码安装 lnmp 环境并搭建 zabbix3.4

1. php 安装

    //升级安装并重启
    yum update  && shutdown -r now

    //安装基础环境
    yum -y groupinstall "Development tools"

    yum -y install wget iproute iotop mtr perf telnet dstat iftop vim

    yum -y install  libxml2 libxml2-devel openssl-devel bzip2 bzip2-devel libcurl-devel libjpeg libjpeg-devel libpng-devel libicu-devel libmcrypt-devel freetype-devel libtidy libtidy-devel ImageMagick-devel mhash mhash-devel pcre-devel libzip postgresql-devel

    //统一配置目录
    mkdir -p /data/conf/PHP7
    mkdir -p /data/logs/PHP7
    mkdir -p /root/software 

    //下载并编译安装
     cd /root/software/ && wget -O php.tar.xz "https://secure.php.net/get/php-7.0.6.tar.xz/from/this/mirror"

     // --strip-components=N    解压时去除N层目录结构
     mkdir php7 &&  tar -xf /root/software/php.tar.xz -C /root/software/php7 --strip-components=1

     //预编译
      cd /root/software/php7 && ./configure --prefix=/usr/local/php7 --sysconfdir=/data/conf/php7 --with-config-file-path=/data/conf/php7 --enable-mysqlnd --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-iconv --with-freetype-dir --with-jpeg-dir --with-png-dir --enable-zip --with-zlib --with-bz2 --enable-calendar --enable-exif --with-libxml-dir --enable-xml --disable-rpath --disable-short-tags --enable-bcmath --enable-shmop --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-tidy --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --enable-intl --with-pdo-pgsql --enable-fpm --with-gettext


      //编译安装
      make -j8 && make install

      //编译报错需要重新安装依赖并编译时,先清除上一次编译生成的文件
      make distclean

      //复制配置文件
      cp -rp php.ini-production /data/conf/php7/php.ini

      //设置开机自启
      cp -rp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
      chmod +x /etc/init.d/php-fpm
      chkconfig --add php-fpm
      chkconfig php-fpm on

      //动态添加imagick与redis模块
      cd /root/software/

       wget http://pecl.php.net/get/imagick-3.4.3.tgz
       tar xf imagick-3.4.3.tgz && cd imagick-3.4.3
       /usr/local/php7/bin/phpize
       ./configure --with-php-config=/usr/local/php7/bin/php-config
       make && make install

       cd /root/software/
        wget http://pecl.php.net/get/redis-3.1.2.tgz
       tar xf redis-3.1.2.tgz && cd redis-3.1.2
       /usr/local/php7/bin/phpize
       ./configure --with-php-config=/usr/local/php7/bin/php-config
       make && make install

       //gettext模块是 zabbix 简体中文需要用到的模块,可以编译的时候直接加入,可以动态的在源码包里面去编译

       --with-gettext

       cd /root/software/php7/ext/gettext && /usr/local/php7/bin/phpize && ./configure --with-php-config=/usr/local/php7/bin/php-config
       make && make install
       vim /data/conf/php7/php.ini
        extension = "gettext.so"   //添加这一行
        /etc/init.d/php-fpm restart


       //php 做软连接,方便以后维护升级
        ln -sv /usr/local/php7 /usr/local/php

        //修改默认配置文件名
        cp -rp /data/conf/php7/php-fpm.conf.default /data/conf/php7/php-fpm.conf
        cp -rp /data/conf/php7/php-fpm.d/www.conf.default /data/conf/php7/php-fpm.d/www.conf

2. nginx 安装(与 php 同一个机器基础环境就不重复安装了)

    //安装依赖
    yum -y install libxml2 libxml2-devel openssl-devel bzip2 bzip2-devel libcurl-devel libjpeg libjpeg-devel libpng-devel libicu-devel libmcrypt-devel freetype-devel postgresql-devel libtidy libtidy-devel ImageMagick-devel mhash mhash-devel pcre-devel wget

    //统一配置
    mkdir -p /data/conf/nginx   
    mkdir -p /data/logs/nginx   
    mkdir -p /data/run      
    chmod 777 /data/{run,logs}

    //下载并安装
    cd /root/software/
    wget -O ngx_http_secure_download.zip https://github.com/replay/ngx_http_secure_download/archive/master.zip \
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
      && make install

      //添加启动脚本
      vim /etc/init.d/nginx
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

        //赋予限权并开机自启
        chmod +x /etc/init.d/nginx
        chkconfig --add nginx
        chkconfig nginx on
        /etc/init.d/nginx start


        //修改 nginx 配置文件,主要修改的选项
        vim /data/conf/nginx/nginx.conf
        pid        /data/run/nginx.pid;  //这个得和开机脚本一致
        error_log  /data/logs/nginx/error.log  info;    //注意 log 目录要存在
        log_format          //开启这项才能打开 main
        access_log  /data/logs/nginx/access.log  main;
        server_name  47.97.154.62;      //指定 server 名称
        root   /data/html;              //指定 root 目录
        location / {
            root   html;      //这个要改成 /usr/share/zabbix目录
            index  index.php index.html index.htm;      //添加index.php,不添加会报错
        }
        //开启 php 通信,注意是  $document_root
        location ~ \.php$ {
            root           /data/html;      //这个要改成 /usr/share/zabbix目录
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }


3. 编译安装 mysql5.7.22

    //下载并解压
    cd /root/software/
    wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.22.tar.gz && tar xf mysql-5.7.22.tar.gz

    //安装 boost,mysql5.7开始需要这个库支持
    wget http://www.sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz && tar -zxvf boost_1_59_0.tar.gz -C /usr/local
    mv /root/software/boost_1_59_0 /usr/local/boost

    //安装依赖环境
    yum -y install cmake gcc gcc-c++ bison ncurses ncurses-devel

    //创建目录及用户
    mkdir /data/mysql -pv && groupadd -g 306 mysql && useradd -g mysql -u 306 -s /sbin/nologin -M mysql && chown -R mysql.mysql /data/mysql

    //编译安装
    cd /root/software//mysql-5.7.22

    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DWITH_BOOST=/usr/local/boost -DSYSCONFDIR=/etc -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EMBEDDED_SERVER=1 

    make -j 4 && make install

    //设置权限并修改配置
    chown -R mysql:mysql /data/mysql

    vim /etc/my.cnf
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

    //初始化 mysql, 这里有个坑,没有任何输出信息,要去/data/mysql目录查看是否生成了 mysql 数据目录,如果没有则需要把/data/mysql目录里面的数据全部删除重新执行一遍
    /usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql


    //设置环境变量
    echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile && source /etc/profile

    //导出头文件
    ln -sv /usr/local/mysql/include /usr/include/mysqld

    //导出库文件
    echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
    ldconfig

    //添加开机自启
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    chkconfig --add mysqld

    //启动 mysql
    /etc/init.d/mysqld start

    //初始化 mysql
    mysql_secure_installation


4. 安装 zabbix3.4
    系统初始化已经添加了 zabbix 的 yum 源不需要安装,直接安装包就行
    yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-get zabbix-agent

    //mysql 创建数据库及用户权限
    create database zabbix character set utf8 collate utf8_bin;   
    grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';   
    flush privileges;

    //修改zabbix 连接数据库配置文件
    vim /etc/zabbix/zabbix_server.conf
    DBHost=localhost
    DBName=zabbix
    DBUser=zabbix
    DBPassword=zabbix

    //导入数据,使用'*'号代替具体版本号更具通用型
    zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | /usr/local/mysql/bin/mysql -uzabbix -pzabbix zabbix

    //解决zabbix图形化列表下中文乱码
    yum -y install wqy-microhei-fonts
    mv /usr/share/fonts/dejavu/DejaVuSans.ttf /usr/share/fonts/dejavu/DejaVuSans.ttf.bak
    cp -f /usr/share/fonts/wqy-microhei/wqy-microhei.ttc /usr/share/fonts/dejavu/DejaVuSans.ttf

    chown -R zabbix:zabbix /etc/zabbix
    chown -R zabbix:zabbix /usr/share/zabbix
    chown -R zabbix:zabbix /usr/lib/zabbix

    //不修改权限,nginx 会报403
    chmod -R 755 /etc/zabbix/web/

    //对 mysql.sock 做软链,不指定默认软链启动会报错
    find / -name mysql.sock
    ln -sv 源sock /var/lib/mysql/mysql.sock

    //修改 php 相关配置,修改如下配置
    vim /data/conf/php7/php.ini
    max_execution_time = 300
    max_input_time = 300
    memory_limit = 128M
    post_max_size = 16M
    upload_max_filesize = 2M
    date.timezone = Asia/Shanghai
    always_populate_raw_post_data = -1
    mysqli.default_socket = /var/lib/mysql/mysql.sock

    //修改 nginx 配置,将 nginx 的 root 目录设置为 zabbix 的配置文件目录
    vim /data/conf/nginx/nginx.conf
    root           /usr/share/zabbix;

    //启动服务
    /etc/init.d/php-fpm start
    /etc/init.d/nginx start
    systemctl start zabbix-server

    //访问 zabbix,因为 nginx 已经指定 zabbix 的配置文件目录为 root 目录了所以直接 http://IP 就可以访问了
    直接使用 ip 访问,默认用户 Admin  密码: zabbix


注意事项:
    php 会把一些session文件写入到/tmp 目录下,不要轻易修改该目录下的文件夹或删除文件
