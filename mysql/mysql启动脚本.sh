#!/bin/sh
# Copyright Abandoned 1996 TCX DataKonsult AB & Monty Program KB & Detron HB
# This file is public domain and comes with NO WARRANTY of any kind

# MySQL daemon start/stop script.

# Usually this is put in /etc/init.d (at least on machines SYSV R4 based
# systems) and linked to /etc/rc3.d/S99mysql and /etc/rc0.d/K01mysql.
# When this is done the mysql server will be started when the machine is
# started and shut down when the systems goes down.

# Comments to support chkconfig on RedHat Linux
# chkconfig: 2345 64 36
# description: A very fast and reliable SQL database engine.

# Comments to support LSB init script conventions
### BEGIN INIT INFO
# Provides: mysql
# Required-Start: $local_fs $network $remote_fs
# Should-Start: ypbind nscd ldap ntpd xntpd
# Required-Stop: $local_fs $network $remote_fs
# Default-Start:  2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop MySQL
# Description: MySQL is a very fast and reliable SQL database engine.
### END INIT INFO



basedir=/usr/local/mysql
datadir=/data/mysql_3306
service_startup_timeout=900
lockdir='/var/lock/subsys'
lock_file_path="$lockdir/mysql_3306"
bindir=/usr/local/mysql/bin
sbindir=/usr/local/mysql/bin
libexecdir=/usr/local/mysql/bin
conf=/data/conf/3306/my.cnf
mysqld_pid_file_path=$datadir/mysql.pid



PATH="/sbin:/usr/sbin:/bin:/usr/bin:$basedir/bin"
export PATH


case "$1" in
  'start')
    
    $bindir/mysqld_safe --defaults-file="$conf" --basedir="$basedir" --datadir="$datadir" --pid-file="$mysqld_pid_file_path" --log-error=${datadir}/mysql-error.log --socket=${datadir}/mysql.sock --plugin-dir=${basedir}/lib/plugin --user=mysql >/dev/null &
    return_value=$?

    if [ $return_value == 0 ];then
      echo  "Starting MySQL Secceed"
    else
      echo  "Straring MySQL Failed"
    fi
    if test -w "$lockdir"
      then
        touch "$lock_file_path"
    fi
      exit $return_value
    ;;

  'stop')
    # Stop daemon. We use a signal here to avoid having to know the
    # root password.

    if test -s "$mysqld_pid_file_path"
    then
      # signal mysqld_safe that it needs to stop
      touch "$mysqld_pid_file_path.shutdown"

      mysqld_pid=`cat "$mysqld_pid_file_path"`

      if (kill -0 $mysqld_pid 2>/dev/null)
      then
        echo "Shutting down MySQL"
        kill $mysqld_pid
        # mysqld should remove the pid file when it exits, so wait for it.
        return_value=$?
      else
        log_failure_msg "MySQL server process #$mysqld_pid is not running!"
        rm "$mysqld_pid_file_path"
      fi

      # Delete lock for RedHat / SuSE
      if test -f "$lock_file_path"
      then
        rm -f "$lock_file_path"
      fi
      exit $return_value
    else
      log_failure_msg "MySQL server PID file could not be found!"
    fi
    ;;

    *)
      # usage
      basename=`basename "$0"`
      echo "Usage: $basename  {start|stop}  [ MySQL server options ]"
      exit 1
    ;;
esac

exit 0