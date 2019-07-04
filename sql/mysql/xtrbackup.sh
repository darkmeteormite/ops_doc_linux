XtraBackup是由Percona提供的MySQL数据库备份工具，根据官方介绍，这也是世界上唯一一款开源的能够为InnoDB和XtraDB数据库进行热备的工具。
特点：
	1、备份过程快速、可靠；
	2、备份过程不会打断正在执行的事务；
	3、能够基于压缩等功能节约磁盘空间和流量；
	4、自动实现备份检验；
	5、还原速度快
Percona XtraBackup是基于InnoDB的崩溃恢复功能。它复制您的InnoDB数据文件，导致内部不一致的数据；但随后它对文件执行崩溃恢复，使它们再次成为一致，可用的数据库。
这是因为InnoDB维护一个重做日志，也称为事务日志。这包含对InnoDB数据的每个更改的记录。当InnoDB启动时，它会检查数据文件和事务日志，并执行两个步骤。它将提交的事务日志条目应用于数据文件，并对修改数据但未提交的任何事务执行撤销操作。


一、安装XtraBackup
1、安装yum源
# yum install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
或者：# vim /etc/yum.repos.d/percona.repo

########################################
# Percona releases and sources, stable #
########################################
[percona-release-$basearch]
name = Percona-Release YUM repository - $basearch
baseurl = http://repo.percona.com/release/$releasever/RPMS/$basearch
enabled = 1
gpgcheck = 0
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-release-noarch]
name = Percona-Release YUM repository - noarch
baseurl = http://repo.percona.com/release/$releasever/RPMS/noarch
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-release-source]
name = Percona-Release YUM repository - Source packages
baseurl = http://repo.percona.com/release/$releasever/SRPMS
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

####################################################################
# Testing & pre-release packages. You don't need it for production #
####################################################################
[percona-testing-$basearch]
name = Percona-Testing YUM repository - $basearch
baseurl = http://repo.percona.com/testing/$releasever/RPMS/$basearch
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-testing-noarch]
name = Percona-Testing YUM repository - noarch
baseurl = http://repo.percona.com/testing/$releasever/RPMS/noarch
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-testing-source]
name = Percona-Testing YUM repository - Source packages
baseurl = http://repo.percona.com/testing/$releasever/SRPMS
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

############################################
# Experimental packages, use with caution! #
############################################
[percona-experimental-$basearch]
name = Percona-Experimental YUM repository - $basearch
baseurl = http://repo.percona.com/experimental/$releasever/RPMS/$basearch
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-experimental-noarch]
name = Percona-Experimental YUM repository - noarch
baseurl = http://repo.percona.com/experimental/$releasever/RPMS/noarch
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

[percona-experimental-source]
name = Percona-Experimental YUM repository - Source packages
baseurl = http://repo.percona.com/experimental/$releasever/SRPMS
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

2、搜索percona-xtrabackup
# yum list | grep percona-xtrabackup
3、安装percona-xtrabackup
# yum -y install percona-xtrabackup-24

4、源代码安装
(1)、下周源代码
# git clone https://github.com/percona/percona-xtrabackup.git
# cd percona-xtrabackup
# git checkout 2.4
(2)、解决依赖关系
# yum install cmake gcc gcc-c ++ libaio libaio-devel automake autoconf \
  bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel \
  vim-common
(3)、使用cmake编译
# cmake -DBUILD_CONFIG = xtrabackup_release -DWITH_MAN_PAGES = OFF && make -j4
# make install

二、完全备份
1、创建具有完全备份所需的最低权限的数据库用户的SQL示例如下（前提mysql已经安装好了）
	mysql> CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY 'bkpass';
	mysql> GRANT RELOAD,LOCK TABLES,PROCESS,REPLICATION CLIENT ON *.* TO 'bkpuser'@'localhost';
	mysql> FLUSH PRIVILEGES;
2、配置xtrabackup
# 所有的xtrabackup配置都可以通过配置/etc/my.cnf来完成，也可以通过命令执行选项
	例如：
	[xtrabackup]
	target_dir = /data/backups/mysql/
3、创建完全备份
	# xtrabackup --user=root --host=localhost --backup --target-dir=/data/backup/mysql/$(date +%Y%m%d) --datadir=/data/mysql/
		170217 14:41:49 Executing UNLOCK TABLES
		170217 14:41:49 All tables unlocked
		170217 14:41:49 Backup created in directory '/data/backup/mysql/20170217'
		170217 14:41:49 [00] Writing backup-my.cnf
		170217 14:41:49 [00]        ...done
		170217 14:41:49 [00] Writing xtrabackup_info
		170217 14:41:49 [00]        ...done
		xtrabackup: Transaction log of lsn (1632403) to (1632409) was copied.
		170217 14:41:49 completed OK!     #看到这几行，就是成功了
	
	# ll  #查看备份文件
	总用量 12324
	-rw-r----- 1 root root      421 2月  17 14:41 backup-my.cnf
	drwxr-x--- 2 root root     4096 2月  17 14:41 hellodb
	-rw-r----- 1 root root 12582912 2月  17 14:41 ibdata1
	drwxr-x--- 2 root root     4096 2月  17 14:41 mysql
	drwxr-x--- 2 root root     4096 2月  17 14:41 performance_schema
	drwxr-x--- 2 root root     4096 2月  17 14:41 test
	drwxr-x--- 2 root root     4096 2月  17 14:41 tmp
	-rw-r----- 1 root root      113 2月  17 14:41 xtrabackup_checkpoints
	-rw-r----- 1 root root      490 2月  17 14:41 xtrabackup_info
	-rw-r----- 1 root root     2560 2月  17 14:41 xtrabackup_logfile
	#备份完成后，数据不能直接用于恢复操作，因为备份的数据中可能会包含尚未提交的事务或已经提交但尚未同步至数据文件中得事务。因此，此时的数据文件仍然不一致，所以我们需要“准备”一个完全备份。

	# xtrabackup --prepare --target-dir=/data/backup/mysql/20170217/
		# 如果执行正确，其输出信息的最后几行通常如下
		InnoDB: 5.7.13 started; log sequence number 1632789
		xtrabackup: starting shutdown with innodb_fast_shutdown = 1
		InnoDB: FTS optimize thread exiting.
		InnoDB: Starting shutdown...
		InnoDB: Shutdown completed; log sequence number 1632808
		170217 14:50:43 completed OK!    #可以看到提示，准备好了
4、恢复数据
	注意：在恢复备份之前，datadir必须为空。还要注意，MySQL服务器需要在执行恢复之前关闭。您不能恢复到正在运行的mysqld实例的datadir。
	# xtrabackup --copy-back --target-dir=/data/backup/mysql/20170217/
		170217 14:56:08 [01]        ...done
		170217 14:56:08 [01] Copying ./ibtmp1 to /data/mysql/ibtmp1
		170217 14:56:08 [01]        ...done
		170217 14:56:08 completed OK!
	# chown -R mysql.mysql /data/mysql
		#当数据恢复到DATADIR目录以后，还需要确保所有数据文件的属主和属组均为正常的用户，如mysql，否则，是启动不了的
	# service mysql start
		Starting MySQL (Percona Server). SUCCESS!
	# netstat -tnl|grep 3306
		tcp   0   0 :::3306   :::*    LISTEN

三、增量备份
	无论xtrabackup和innobackupex工具支持增量备份，这意味着它们可以只复制自上次备份以来更改的数据。
	您可以在每个完全备份之间执行许多增量备份，因此您可以设置备份过程，例如每周一次的完全备份和每天的增量备份，或每天的完全备份以及每小时的增量备份。
	每个InnoDB的页面都会包含一个LSN信息，每当相关的数据发生改变，相关的页面的LSN就会自动增长，这正是InnoDB表可以进行增量备份的基础，即xtrabackup通过备份上次的完全备份之后发生改变的页面来实现。
1、创建增量备份前，先创建完全备份
	# xtrabackup --user=root --host=localhost --backup --target-dir=/data/backup/mysql/$(date +%Y%m%d) --datadir=/data/mysql/
	# xtrabackup --user=root --host=localhost --backup --target-dir=/data/backup/mysql/20170217 --datadir=/data/mysql/
2、创建增量备份（根据完全备份创建第一次增量备份）
	# xtrabackup --backup --target-dir=/data/backup/mysql/$(date +%Y%m%d%H%M%S) --incremental-basedir=/data/backup/mysql/$(date +%Y%m%d)
	# xtrabackup --backup --target-dir=/data/backup/mysql/20170217152442 --incremental-basedir=/data/backup/mysql/20170217
	注意：其中--incremental-basedir=/data/backup/mysql/20170217是完全备份的目录，--target-dir=/data/backup/mysql/20170217152442是增量备份所在的目录。
	     这是第一次增量备份，所有--incremental-basedir所指的是完全备份目录，在执行过增量备份之后在一次进行增量备份时，其--incremental-basedir应该指向上一次的增量备份所在的目录。
	     增量备份仅能用于InnoDB或XtraDB表，对于MyISAM表而言，执行增量备份时其实进行的时完全备份。
3、准备增量备份
	“准备”(prepare)增量备份与整理完全备份有着一些不同，尤其要注意的是：
		需要在每个备份(包含完全和每个增量备份上)，讲已经提交的食物进行“重放”。“重放”之后，所有的备份数据将合并到完全备份上。
		基于所有的备份将未提交的事务进行“回滚”。
	# xtrabackup --prepare --apply-log-only --target-dir=/data/backup/mysql/20170217
	要将第一个增量备份应用于完整备份，执行以下命令
	# xtrabackup --prepare --apply-log-only --target-dir=/data/backup/mysql/20170217 --incremental-dir=/data/backup/mysql/20170218
	这会将增量文件应用于其中的文件/data/backup/mysql/20170217，这会将它们按时间推进到增量备份的时间。然后，它会照常应用重做日志到结果。
	最终数据在/data/backup/mysql/20170217，而不是在增量目录中。所有应该看到类似如下的输出：
		170217 15:47:27 [01] Copying /data/backup/mysql/20170218/huoban/db.opt to ./huoban/db.opt
		170217 15:47:27 [01]        ...done
		170217 15:47:27 [00] Copying /data/backup/mysql/20170218//xtrabackup_info to ./xtrabackup_info
		170217 15:47:27 [00]        ...done
		170217 15:47:27 completed OK!
	而后，第二个增量
	# xtrabackup --prepare --target-dir=/data/backup/mysql/20170217 --incremental-dir=/data/backup/mysql/20170219
	* 其中 --apply-log-only 应该在合并除最后一个增量之外的所有增量时使用。这就是为什么上一行不包含此选项。
	  即使在最后一步执行了--apply-log-only，备份仍然是一致的，但在这种情况下，服务器将执行回滚阶段。
4、恢复备份
	# xtrabackup --copy-back --target-dir=/data/backup/mysql/20170217/
	# chown -R mysql.mysql /data/mysql

































启动备份

xtrabackup --backup --target-dir=/data /backups/mysql

xtrabackup --prepare --target-dir=/data/backups/mysql

还原备份
xtrabackup --copy-back --target-dir=/data/backups/mysql


增量备份（要进行增量备份，需要完全备份，如果没有完全备份，增量是没有用的）
xtrabackup --backup --target-dir=/data/backups/inc1 --incremental-basedir=/data/backups/mysql

/data/backups/inc1目录现在应包含增量文件   /data/backups/mysql是完全备份的目录

创建增量备份
要进行增量备份，首先需要完全备份。


一、CUS上准备环境
1、在CUS1上安装percona-server-server,percona-server-client,percona-server-clien,percona-xtrbackup-24(版本和OPEN机器上一样)
	# yum -y install Percona-Server-server-56-5.6.33 Percona-Server-client-56-5.6.33 percona-xtrbackup-24
2、创建目录
	# mkdir -pv /data/mysql 
3、修改配置文件 
	# vim /etc/my.cnf
		server_id                     = 323
		relay-log                     = mysql-relay-bin
		log-slave-updates             = 1
		read-only                     = 1

二、备份OPEN机器上的数据
1、创建备份目录
	# mkdir -pv /data/backup/mysql
2、安装percona-xtrabackup-24
    # yum -y install percona-xtrbackup-24
3、创建备份
	# xtrabackup --backup --target-dir=/data/backup/mysql
	# tar zcf mysql.tar.gz /data/backup/mysql
4、scp传送给CUS1

三、CUS1上恢复数据
1、准备恢复
	# xtrabackup --prepare --target-dir=/data/backup/mysql/mysql
2、恢复数据到指定目录
	# xtrabackup --copy-back --target-dir=/data/backup/mysql/mysql
3、恢复权限
	# chown -R mysql.mysql /data/mysql
4、启动MYSQL

四、创建主从
1、OPEN机器上授权
	mysql > GRANT REPLICATION SLAVE，REPLICATION CLIENT ON *.* TO 'slaveUser'@'10.25.232.251' IDENTIFIED BY 'slaveuser';  
	mysql > flush privileges;
2、iptables中放行（OPEN)
	iptables -I INPUT 16 -s 10.46.68.114/32 -j ACCEPT
	iptables -I OUTPUT 19 -d 10.46.68.114/32 -j ACCEPT
3、CUS1连接主服务器  
	# cat xtrabackup_binlog_pos_innodb
		mysql-bin.000002	18304406
	
	mysql> CHANGE MASTER TO
			MASTER_HOST='10.47.59.34',
			MASTER_USER='slaveUser',
			MASTER_PASSWORD='slaveuser',
			MASTER_LOG_FILE='mysql-bin.000002',
			MASTER_LOG_POS='18304406';
	mysql> START SLAVE;		




#!/bin/bash
#
# 2017-02-16

Backup_Data=/data/backup/mysql
# PATH
prog='/usr/bin/xtrabackup'
# start date
STD_date=$(date +%Y%m%d)
BEF_date=$(date -d '-1 day' +%Y%m%d)
#
[ ! -d $Backup_Data/$STD_date ] && mkdir -p $Backup_Data/$STD_date


perfect() {
    echo "Starting perfect backup mysql"
    $prog --user=root --host=localhost --backup --target-dir=$Backup_Data/$STD_date &> $Backup_Data/${STD_date}.log
    retval=$?
    return $retval
}

incremental() {
    echo "Starting incremental backup mysql"
    $prog --user=root --host=localhost --backup --target-dir=$Backup_Data/$STD_date ----incremental-dir=$Backup_Data/$BEF_date &> $Backup_Data/${STD_date}.log
    retval=$?
    return $retval
}

prepare() {
    echo "Starting prepare backup mysql"
}

case "$1" in
        perfect)
                perfect
                ;;
        incremental)
                incremental
                ;;
        *)
                echo $"Usage: $0 {perfect|incremental}"
                RETVAL=2
esac
exit $RETVAL








