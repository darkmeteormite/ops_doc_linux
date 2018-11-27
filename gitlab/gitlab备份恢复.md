1、gitlab备份路径设置
```
# vim /etc/gitlab/gitlab.rb
gitlab_rails['manage_backup_path'] = true   
gitlab_rails['backup_path'] = '/data/gitlab/backups'  #gitlab备份目录
gitlab_rails['backup_archive_permissions'] = 0644     #gitlab生成的备份文件权限
gitlab_rails['backup_keep_time'] = 604800             #备份保留天数为7天

创建目录修改权限
# mkdir /data/gitlab/backups
# chown git.git /data/gitlab/backups
# chmod -R 755 /data/gitlab/backups

重载配置
# gitlab-ctl reconfigure
```
2、备份
```
# gitlab-rake gitlab:backup:create

Dumping database ...
Dumping PostgreSQL database gitlabhq_production ... [DONE]
done
Dumping repositories ...
 * root/lemon ... [DONE]
[SKIPPED] Wiki
 * erlang/ejabberd ... [DONE]
[SKIPPED] Wiki
 * ryan/test ... [DONE]
[SKIPPED] Wiki
 * freeman/hbforce ... [DONE]
[SKIPPED] Wiki
 * ryan/huoban_v3 ... [DONE]
[SKIPPED] Wiki
...
...
...
[SKIPPED] Wiki
 * huoban/hbevent ... [DONE]
[SKIPPED] Wiki
done
Dumping uploads ...
done
Dumping builds ...
done
Dumping artifacts ...
done
Dumping pages ...
done
Dumping lfs objects ...
done
Dumping container registry images ...
[DISABLED]
Creating backup archive: 1540287457_2018_10_23_11.3.6_gitlab_backup.tar ... done
Uploading backup archive to remote storage  ... skipped
Deleting tmp directories ... done
done
done
done
done
done
done
done
Deleting old backups ... done. (0 removed)

```

3、定时备份
```
# vim gitlab_backup.sh
#!/bin/bash
/usr/bin/gitlab-rake gitlab:backup:create CRON=1

# crontab -l
0 1 * * * /bin/bash -x /data/gitlab/backups/gitlab_backup.sh > /data/gitlab/backups/`date`-gitlab.log 2>&1
```

4、恢复
```
GItlab只能还原到与备份文件相同的gitlab版本。
假设在上面gitlab备份之前创建了huoban_api项目，然后不小心误删了huoban_api项目，现在就进行gitlab恢复操作：

停止相关数据连接服务
# gitlab-ctl stop unicorn
# gitlab-ctl stop sidekiq
# gitlab-ctl status
    run: alertmanager: (pid 1376) 2023s; run: log: (pid 1370) 2023s
    run: gitaly: (pid 1354) 2023s; run: log: (pid 1350) 2023s
    run: gitlab-monitor: (pid 1374) 2023s; run: log: (pid 1366) 2023s
    run: gitlab-workhorse: (pid 1371) 2023s; run: log: (pid 1369) 2023s
    run: logrotate: (pid 1372) 2023s; run: log: (pid 1368) 2023s
    run: nginx: (pid 1355) 2023s; run: log: (pid 1351) 2023s
    run: node-exporter: (pid 1375) 2023s; run: log: (pid 1367) 2023s
    run: postgres-exporter: (pid 1377) 2023s; run: log: (pid 1365) 2023s
    run: postgresql: (pid 1382) 2023s; run: log: (pid 1380) 2023s
    run: prometheus: (pid 1373) 2023s; run: log: (pid 1364) 2023s
    run: redis: (pid 1381) 2023s; run: log: (pid 1378) 2023s
    run: redis-exporter: (pid 1353) 2023s; run: log: (pid 1349) 2023s
    down: sidekiq: 15s, normally up; run: log: (pid 1352) 2023s
    down: unicorn: 6s, normally up; run: log: (pid 1379) 2023s

通过之前备份文件进行恢复
# cd /data/gitlab/backups
# ls -l
-rw-r--r-- 1 git git 9766666240 Oct 23 17:40 1540287457_2018_10_23_11.3.6_gitlab_backup.tar
Gitlab的恢复操作会先将当前所有的数据清空，然后再根据备份数据进行恢复
# gitlab-rake gitlab:backup:restore BACKUP=1540287457_2018_10_23_11.3.6

启动Gitlab
# gitlab-ctl start

恢复完成，检查一下恢复情况
# gitlab-rake gitlab:check SANITIZE=true

重新加载Gitlab的配置文件
# gitlab-ctl reconfigure

```
