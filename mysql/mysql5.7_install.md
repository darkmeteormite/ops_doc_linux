1、下载源码包

```
# cd /usr/local/src
# wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.22.tar.gz
# tar xf mysql-5.7.22.tar.gz 
下载boost
# wget http://www.sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz
# tar -zxvf boost_1_59_0.tar.gz -C /usr/local
# mv /usr/local/boost_1_59_0 /usr/local/boost
```


2、安装
```
# yum -y install cmake gcc gcc-c++ bison ncurses ncurses-devel
# mkdir /data/mysql -pv
# chown -R mysql.mysql /data/mysql
# groupadd -g 306 mysql
# useradd -g mysql -u 306 -s /sbin/nologin -M mysql
# cd /usr/local/src/mysql-5.7.22

cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/data/mysql \
-DWITH_BOOST=/usr/local/boost \
-DSYSCONFDIR=/etc \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DENABLE_DTRACE=0 \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_EMBEDDED_SERVER=1

# make -j 4 
# make install
```
3、配置
```
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
/usr/local/mysql/bin/mysqld \
--initialize-insecure \
--user=mysql \
--basedir=/usr/local/mysql \
--datadir=/data/mysql
添加MySQL环境变量
# echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile.d
导出头文件
# ln -sv /usr/local/mysql/include /usr/include/mysqld
导出库文件
# echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
# ldconfig
添加启动脚本
# cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
# chmod +x /etc/init.d/mysqld
# chkconfig --add mysqld
```
4、启动mysql并设置密码
```
# /etc/init.d/mysqld start
找到mysql5.7的初始密码
# grep "temporary password" mysql-error.log
2018-09-25T06:30:28.930040Z 1 [Note] A temporary password is generated for root@localhost: Ui4/OupkjroO
# mysql -uroot -pUi4/OupkjroO
mysql> alter user root@localhost identified by 'huobanim2014';
```
