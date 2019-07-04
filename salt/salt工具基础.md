一、安装Salt
    Salt需要epel源支持，所有安装前需要先安装epel源包。

1、salt-master
    
    yum -y install salt-master

2、salt-minion

    yum -y install salt-minion

二、配置Salt

1、master(/etc/init.d/master)

    # salt运行的用户，影响到salt的执行权限
    user: root
    #salt的运行线程，开的线程越多一般处理的速度越快，但一般不要超过CPU的个数
    worker_threads: 10
    # master的管理端口
    publish_port : 4505
    # master跟minion的通讯端口，用于文件服务，认证，接受返回结果等
    ret_port : 4506
    # 如果这个master运行的salt-syndic连接到了一个更高层级的master,那么这个参数需要配置成连接到的这个高层级master的监听端口
    syndic_master_port : 4506
    # 指定pid文件位置
    pidfile: /var/run/salt-master.pid
    # saltstack 可以控制的文件系统的开始位置
    root_dir: /
    # 日志文件地址
    log_file: /var/log/salt_master.log
    # 分组设置
    nodegroups:
      group_all: '*'
    # salt state执行时候的根目录
    file_roots:
      base:
        - /etc/salt/file
    # 设置pillar 的根目录
    pillar_roots:
      base:
        - /etc/salt/pillar

2、配置minion(/etc/salt/minion)

    # salt运行的用户，影响到salt的执行权限
    user: root
    #s alt的运行线程，开的线程越多一般处理的速度越快，但一般不要超过CPU的个数
    worker_threads: 10
    # master的管理端口
    publish_port : 4505
    # master跟minion的通讯端口，用于文件服务，认证，接受返回结果等
    ret_port : 4506
    # 如果这个master运行的salt-syndic连接到了一个更高层级的master,那么这个参数需要配置成连接到的这个高层级master的监听端口
    syndic_master_port : 4506
    # 指定pid文件位置
    pidfile: /var/run/salt-master.pid
    # saltstack 可以控制的文件系统的开始位置
    root_dir: /
    # 日志文件地址
    log_file: /var/log/salt_master.log
    # 分组设置
    nodegroups:
      group_all: '*'
    # salt state执行时候的根目录
    file_roots:
      base:
        - /etc/salt/file
    # 设置pillar 的根目录
    pillar_roots:
      base:
        - /etc/salt/pillar
    master: mail  #这块的mail
    id: node1-bjwf
        
3、启动salt

    service salt-master start
    service salt-minion start
    # saltstack 是使用python2的语言编写，对python3的兼容性不好，请使用python2的环境

4、简单测试

    [root@mail salt]# salt-key -L   #显示所有公钥
    Accepted Keys:
    Denied Keys:
    Unaccepted Keys:
    node1-bjwf
    Rejected Keys:
    
    [root@mail salt]# salt-key -A -y node1-bjwf   #接受node1-bjwf的认证
    The following keys are going to be accepted:
    Unaccepted Keys:
    node1-bjwf
    Key for minion node1-bjwf accepted.
    
    [root@mail salt]# salt-key -L   
    Accepted Keys:
    node1-bjwf     #可以看到已经添加要信任列表
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:
    
    [root@mail salt]# salt-key -y -d node1-bjwf  #删除node1-bjwf的认证
    Deleting the following keys:
    Accepted Keys:
    node1-bjwf
    Key for minion node1-bjwf deleted.
    
三、常用模块

1、status模块（查看系统信息）
    
    [root@mail salt]# salt "*" status.loadavg    #查看负载情况（ *代表所有信任的主机列表）
    node1-bjwf:
        ----------
        1-min:
            0.0
        15-min:
            0.0
        5-min:
            0.0
    [root@mail salt]# salt "*" status.cpuinfo       #查看cpu信息
    [root@mail salt]# salt "*" status.diskstats     #查看磁盘信息
    [root@mail salt]# salt "*" status.meminfo       #查看内存信息
    [root@mail salt]# salt "*" status.w             #w命令返回信息
    
2、cmd模块（远程执行命令模块，具有强大的功能）
    
    # cmd.run 执行一个远程的shell命令

3、复制文件模块
    
    # cp.get_file
    # sudo salt \* cp.get_file salt://process/check_process.sh /etc/zabbix/scripts/check_process.sh

四、salt常用功能

1、查看版本
    
    [root@mail ~]# salt --version
    [root@mail ~]# salt --versions  #查看详细信息

2、salt-key

    # salt-key -L            #查看所有的minion
    # salt-key -a id -y      #接受指定的minion
    # salt-key -A -y         #接受所有的minion
    # salt-key -d id         #删除指定的minion
    # salt-key -D -y         #删除所有的minion
    # salt-key -r id         #拒绝指定的minion
    # salt-key -R            #拒绝所有的minion

3、minion匹配方式

   # salt -E 'app*' test.ping           #正则匹配
   # salt -L 'node1,node2' test.ping    #列表匹配
   # salt -G 'os:centos' test.ping      #grains匹配
   # salt -N pgsql test.ping            #组匹配
   # salt -C 'os:centos or L@node1' test.ping #复合匹配
   # salt -I 'key,value' test.ping      #pillar匹配
   # salt -S '192.168.1.0/24' test.ping #CIDR匹配

4、将minion分组

    # vim /etc/salt/master
    nodegroups:
        bjwf: 'L@bjwf-node1,bjwf-node2'      #L表示列表的方式，E正则表达式
    # salt -N bjwf test.ping
        bjwf-node2:
            True
        bjwf-node1:
            True
    
5、minion状态管理

    # salt-run manage.up        #查看存活的minion
    # salt-run manage.down      #查看死掉的minion
    # salt-run manage.down removekeys=True   #查看死掉的minion并将其删除
    # salt-run manage.status    #查看minion的相关信息
        down:
        up:
            - bjwf-node1
            - bjwf-node2
    # salt-run manage.versions  #查看salt的所有master和minion的版本信息






salt "*" saltutil.refresh_pillar
