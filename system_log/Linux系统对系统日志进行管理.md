# Linux系统对 /var/log/journal  日志进行管理


###journal对日志进行管理

```
journalctl   #查看全部日志
journalctl -n 4 #查看最新的四行日志
journalctl --since time	###查看从某时间开始的日志
journalctl --until time	###查看截止某个时间前的所有日志
journalctl --since time --until time	###查看时间段内的日志
journalctl -p err		###查看错误信息日志
journalctl -o verbose  ###查看日志详细信息
journalctl _PID=num _COMM=sshd  ###查看制定pid和命令日志信息
```

###journal对日志采集
journal可以直接查看当前系统中日志，但是当系统重启后，以前日志会消失，不便于对日志保存分析和管理。不过可以通过rsyslog提供的思路，将日志保存在文件中，方便管理。

```
mkdir /var/log/journal		###创建文件保存采集的日志
chgrp systemd-journal /var/log/journal/	###改变日志所有组
chmod g+s /var/log/journal/	###赋予用户组s权限，以后产生的所有日志文件都属于该组
kill -1 进程pid号	###重新加载配置文件
```

#查看垃圾文件的办法

```
du -t 100M /var 或 journalctl --disk-usage 命令查看

#查看某个目录的大小并排序(单位未MB)
du -hm --max-depth=1 /var/ | sort -n    #从小到大排

#清空/var/log/journal文件的方法
journalctl --vacuum-time=1w   #保留最近一周的日志

journalctl --vacuum-size=500M  #保留500M的日志

find /var/log/ -type f -mtime +30 -exec rm -f {} \;   #删除30天之前的文件
```
