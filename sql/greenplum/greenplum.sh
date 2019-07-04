Greenplum数据库安装部署

安装需求：
1台MASTER，一台Segment计算节点
安装环境：Centos7.3


一、Master节点安装
   
1、配置hosts
# vim /etc/hosts
# GPDB
10.47.125.55 GPDB01
10.47.125.65 GPDB02
10.47.125.66 GPDB03

2、同步时间
# /usr/sbin/ntpdate cn.pool.ntp.org

3、关闭iptables，firewalld
# systemctl disable firewalld
# systemctl stop firewalld
# setenforce 0
# getenforce

4、解压软件
# unzip greenplum-db-4.3.12.0-rhel5-x86_64.zip

5、安装

	I HAVE READ AND AGREE TO THE TERMS OF THE ABOVE PIVOTAL SOFTWARE
	LICENSE AGREEMENT.
	********************************************************************************
	Do you accept the Pivotal Database license agreement? [yes|no]
	********************************************************************************

	yes

	********************************************************************************
	Provide the installation path for Greenplum Database or press ENTER to
	accept the default installation path: /usr/local/greenplum-db-4.3.12.0
	********************************************************************************

	/usr/local/greenplum-db-4.3.12.0

	********************************************************************************
	Install Greenplum Database into /usr/local/greenplum-db-4.3.12.0? [yes|no]
	********************************************************************************

	yes

	********************************************************************************
	/usr/local/greenplum-db-4.3.12.0 does not exist.
	Create /usr/local/greenplum-db-4.3.12.0 ? [yes|no]
	(Selecting no will exit the installer)
	********************************************************************************

	yes

	Extracting product to /usr/local/greenplum-db-4.3.12.0

	********************************************************************************
	Installation complete.
	Greenplum Database is installed in /usr/local/greenplum-db-4.3.12.0

	Pivotal Greenplum documentation is available
	for download at http://gpdb.docs.pivotal.io
	********************************************************************************

6、查看安装文件
	
	# ll /usr/local/
	lrwxrwxrwx   1 root root   23 Mar 31 11:27 greenplum-db -> ./greenplum-db-4.3.12.0
	drwxr-xr-x  11 root root 4096 Mar 31 11:27 greenplum-db-4.3.12.0

二、创建GP安装配置文件并配置SSH互相

# mkdir -pv /data/greenplum/config
mkdir: created directory ‘/data’
mkdir: created directory ‘/data/greenplum’
mkdir: created directory ‘/data/greenplum/config’
# cd /data/greenplum/config
# vim allnodes.txt
	GPDB01
	GPDB02

# vim nodes.txt
	GPDB02

三、配置所有GP节点root用户的ssh互信

# source /usr/local/greenplum-db/greenplum_path.sh
# gpssh-exkeys -f /data/greenplum/config/allnodes.txt
	[STEP 1 of 5] create local ID and authorize on local host
	  ... /root/.ssh/id_rsa file exists ... key generation skipped

	[STEP 2 of 5] keyscan all hosts and update known_hosts file

	[STEP 3 of 5] authorize current user on remote hosts
	  ... send to GPDB01
	  ... send to GPDB02

	[STEP 4 of 5] determine common authentication file content

	[STEP 5 of 5] copy authentication files to all remote hosts
	  ... finished key exchange with GPDB01
	  ... finished key exchange with GPDB02

	[INFO] completed successfully

四、检查磁盘调度算法
# cat echo deadline > /sys/block/vd*/queue/scheduler
修改为
# echo deadline > /sys/block/vda/queue/scheduler
添加到/etc/rc.local

五、磁盘预读取配置
设置方法：blockdev --setra 16384 /dev/vd*    #添加到rc.local

六、用户资源限额配置
# vim /etc/security/limits.d/20-nproc.conf
* soft nofile 1048576 
* hard nofile 1048576 
* soft nproc 1048576 
* hard nproc 1048576 

七、创建目录并授权
1、master创建

# mkdir /data/greenplum/master
# chown -R gpadmin.gpadmin /data/greenplum

2、slave创建
gpssh -f /data/greenplum/config/nodes.txt  -e ''
Note: command history unsupported on this machine ...
=> mkdir -pv /data/greenplum/{primary,mirror}
[GPDB02] mkdir -pv /data/greenplum/{primary,mirror}
[GPDB02] mkdir: created directory ‘/data’
[GPDB02] mkdir: created directory ‘/data/greenplum’
[GPDB02] mkdir: created directory ‘/data/greenplum/primary’
[GPDB02] mkdir: created directory ‘/data/greenplum/mirror’
=> chown -R gpadmin.gpadmin /data/greenplum
[GPDB02] chown -R gpadmin.gpadmin /data/greenplum

八、各节点GP软件的安装
# gpseginstall -f /data/greenplum/config/allnodes.txt -c csv
	
	20170331:12:12:31:023331 gpseginstall:gpdb01:root-[INFO]:-Installation Info:
	link_name greenplum-db
	binary_path /usr/local/greenplum-db-4.3.12.0
	binary_dir_location /usr/local
	binary_dir_name greenplum-db-4.3.12.0
	20170331:12:12:31:023331 gpseginstall:gpdb01:root-[INFO]:-check cluster password access
	20170331:12:12:32:023331 gpseginstall:gpdb01:root-[INFO]:-de-duplicate hostnames
	20170331:12:12:32:023331 gpseginstall:gpdb01:root-[INFO]:-master hostname: gpdb01
	20170331:12:12:33:023331 gpseginstall:gpdb01:root-[INFO]:-chown -R gpadmin:gpadmin /usr/local/greenplum-db
	20170331:12:12:33:023331 gpseginstall:gpdb01:root-[INFO]:-chown -R gpadmin:gpadmin /usr/local/greenplum-db-4.3.12.0
	20170331:12:12:33:023331 gpseginstall:gpdb01:root-[INFO]:-rm -f /usr/local/greenplum-db-4.3.12.0.tar; rm -f /usr/local/greenplum-db-4.3.12.0.tar.gz
	20170331:12:12:33:023331 gpseginstall:gpdb01:root-[INFO]:-cd /usr/local; tar cf greenplum-db-4.3.12.0.tar greenplum-db-4.3.12.0
	20170331:12:12:35:023331 gpseginstall:gpdb01:root-[INFO]:-gzip /usr/local/greenplum-db-4.3.12.0.tar
	20170331:12:13:02:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: mkdir -p /usr/local
	20170331:12:13:02:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: rm -rf /usr/local/greenplum-db-4.3.12.0
	20170331:12:13:02:023331 gpseginstall:gpdb01:root-[INFO]:-scp software to remote location
	20170331:12:13:04:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: gzip -f -d /usr/local/greenplum-db-4.3.12.0.tar.gz
	20170331:12:13:09:023331 gpseginstall:gpdb01:root-[INFO]:-md5 check on remote location
	20170331:12:13:11:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: cd /usr/local; tar xf greenplum-db-4.3.12.0.tar
	20170331:12:13:12:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: rm -f /usr/local/greenplum-db-4.3.12.0.tar
	20170331:12:13:13:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: cd /usr/local; rm -f greenplum-db; ln -fs greenplum-db-4.3.12.0 greenplum-db
	20170331:12:13:14:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: chown -R gpadmin:gpadmin /usr/local/greenplum-db
	20170331:12:13:15:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: chown -R gpadmin:gpadmin /usr/local/greenplum-db-4.3.12.0
	20170331:12:13:16:023331 gpseginstall:gpdb01:root-[INFO]:-rm -f /usr/local/greenplum-db-4.3.12.0.tar.gz
	20170331:12:13:16:023331 gpseginstall:gpdb01:root-[INFO]:-version string on master: gpssh version 4.3.12.0 build 1
	20170331:12:13:16:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: . /usr/local/greenplum-db/./greenplum_path.sh; /usr/local/greenplum-db/./bin/gpssh --version
	20170331:12:13:17:023331 gpseginstall:gpdb01:root-[INFO]:-remote command: . /usr/local/greenplum-db-4.3.12.0/greenplum_path.sh; /usr/local/greenplum-db-4.3.12.0/bin/gpssh --version
	20170331:12:13:22:023331 gpseginstall:gpdb01:root-[INFO]:-SUCCESS -- Requested commands completed

查看从节点是否复制文件
# ll /usr/local/
	lrwxrwxrwx   1 gpadmin gpadmin   21 Mar 31 12:13 greenplum-db -> greenplum-db-4.3.12.0
	drwxr-xr-x  11 gpadmin gpadmin 4096 Mar 31 11:27 greenplum-db-4.3.12.0

九、初始化数据库
以下工作，在Master节点上以gpadmin用户登陆完成。
(切换到gpadmin用户)
1、创建配置文件
# cd /data/greenplum/config
# cat gpinitsystem_config
	ARRAY_NAME="GPDB"
	SEG_PREFIX=gpseg
	PORT_BASE=40000
	declare -a DATA_DIRECTORY=(/data/greenplum/primary)
	MASTER_HOSTNAME=gpdb01
	MASTER_DIRECTORY=/data/greenplum/master/
	MASTER_PORT=5432
	TRUSTED_SHELL=ssh
	CHECK_POINT_SEGMENTS=256
	ENCODING=UNICODE
	MIRROR_PORT_BASE=50000
	REPLICATION_PORT_BASE=41000
	MIRROR_REPLICATION_PORT_BASE=51000
	declare -a MIRROR_DATA_DIRECTORY=(/data/greenplum/mirror)
2、配置gpadmin用户的各节点就互相

$ gpssh-exkeys -f /data/greenplum/config/allnodes.txt
	[STEP 1 of 5] create local ID and authorize on local host

	[STEP 2 of 5] keyscan all hosts and update known_hosts file

	[STEP 3 of 5] authorize current user on remote hosts
	  ... send to GPDB01
	  ... send to GPDB02
	  ***
	  *** Enter password for GPDB02:

	[STEP 4 of 5] determine common authentication file content

	[STEP 5 of 5] copy authentication files to all remote hosts
	  ... finished key exchange with GPDB01
	  ... finished key exchange with GPDB02

	[INFO] completed successfully

3、初始化数据库
	
	$ gpinitsystem -c gpinitsystem_config -h nodes.txt -B 8

4、配置环境变量

	$ source /usr/local/greenplum-db/greenplum_pash.sh
	$ export MASTER_DATA_DIRECTORY=/data/greenplum/master/gpseg-1

5、建立冗余的master节点
	
	$gpinitstandby -s gpdb(03)

6、调整数据库参数
	
	以下数据库参数调整后必须重新启动数据库。
	调整方法：执行命令 gpconfig -c 参数名 -v 参数值 -m Master节点值
	检查方法：重启数据库后，执行命令 gpconfig -s 参数名
	参数名 参数值 master节点值

	$ gpconfig -c shared_buffers -v 128MB -m 128MB
	$ gpconfig -c gp_vmem_protect_limit -v 15360 -m 15360
	$ gpconfig -c max_connections -v 1000 -m 200
	$ gpconfig --skipvalidation -c wal_send_client_timeout -v 60s -m 60s 

7、关闭数据库
	
	$ gpstop -a

8、启动数据库
 
	$ gpstart -a

9、检查数据库的参数

	$ gpconfig -s shared_buffers
	$ gpconfig -s gp_vmem_protect_limit
	$ gpconfig -s max_connections
	$ gpconfig -s wal_send_client_timeout

	# psql postgres
		show shared_buffers;
		show gp_vmem_protect_limit;
		show max_connections;
		show wal_send_client_timeout;

10、创建业务数据库

	# psql postgres
	postgres=# create database XXX;
	CREATE DATABASE

11、调整连接控制参数

	修改文件 $MASTER_DATA_DIRECTORY/pg_hba.conf
	增加一行：
	host all all 0/0 md5
	修改standby master上的文件 $MASTER_DATA_DIRECTORY/pg_hba.conf
	增加一行：
	host all all 0/0 md5

12、查看数据库连接状态

	$ gpstate




