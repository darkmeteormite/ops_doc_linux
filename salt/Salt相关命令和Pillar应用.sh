1.先了解下管理端（master）常用相关命令
 
 1.1 salt     #主要管理命令
   命令格式：salt [options]  <target> [arguments]
    例：salt ‘*’ test.ping
 
 1.2 salt-key #证书管理
    # salt-key –L           #查看所有minion-key
    # salt-key –a  <keys-name>   #接受某个minion-key
    # salt-key –d  <keys-name>   #删除某个minion-key
    # salt-key –A           #接受所有的minion-key
    # salt-key –D           #删除所有的minion-key
 
 1.3 salt-run #管理minion
    # salt-run manage.up           #显示当前活着的minion
    # salt-run manage.down           #显示未存活的minion
    # salt-run manage.status         #显示当前up和down 的minion   
    # salt-run manage.downremovekeys-True   #显示未存活的minion，并将其移除
 
 1.4 salt-cp #将master文件复制到minion，不支持复制目录
   命令格式：salt-cp [options]<target> SRC DST
   例：salt-cp '*'/root/test.sh  /root/test.sh
 
 1.5 salt-ssh   
   #通过ssh连接被管理端，被管理端不用安装minion，管理端也不用安装master，salt-ssh是一个独立的包，安装后即可使用saltstack大部分功能，没有通讯机制ZeroMQ，命令执行速度会下降。一般没有客户端没有安装minion时候才考虑先用salt-ssh批量安装minion。
   # apt-get install salt-ssh sshpass   #salt-ssh用的sshpass进行密码交互，必须要安装
   
   1.5.1 salt-ssh常用参数
    -r，-raw-shell ：执行shell命令  
    --key-deploy   ：配置keys
    -i，-ignore-host-keys  ：当ssh连接时，忽略keys
     -passwd      ：指定默认密码
     -roster-file   ：指定roster文件
   
   1.5.2 salt-ssh使用
    1.5.2.1 sat-ssh通过调用roster配置文件实现，所以先定义roster，让salt-ssh生效，就可以执行操作了

    # vi /etc/salt/roster
    db:
      host: 192.168.18.212
      user: root
      passwd: 123456
      port: 22
      timeout: 10
    
    1.5.2.1 测试
    # salt-ssh 'db' test.ping
    db:
        True
    
    1.5.2.3 执行shell命令及salt本身的模块
    #第一次运行时会提示是否接受秘钥，如果不想再提示可以加入—key-deploy参数
    # salt-ssh 'db' -r 'uptime'     
    # salt-ssh 'db' disk.usage          #调用salt本身的模块
    # salt-ssh 'db' grains.itemcpu_model   #获取grains信息
2、Pillar
 Pillar是Salt最重要的系统之一，可用于提供开发接口，用于在master端定义数据，然后再minion中使用，一般传输敏感的数据，例如ssh key，加密证书等。
 pillar和states建立方式类似，由sls文件组成，有一个入口文件top.sls，通过这个文件关联其他sls文件，默认路径在/srv/pillar,可通过/etc/salt/master里面pillar_roots:指定位置。
 pillar到底什么作用呢？那么下面介绍一个简单的例子，你就明白了。
 用zabbix监控新上架的服务器（10台），需要将zabbix_agentd.conf分发到被监控主机，这个文件中hostname的ip每台都不同，我们不可能写10分配置文件吧！那么如何让hostname在分发的时候就根据被监控主机IP，修改成自己的呢？这时就用到渲染了，默认渲染器是jinja，支持for in循环判断，格式是{%...%}{% end* %}，这样一来salt会先让jinja渲染，然后交给yaml处理。
 2.1 创建pillar目录和top.sls文件

 # mkdir /srv/pillar
 # vi /srv/pillar/top.sls
 base:
   '*':
     - ip
 
 2.2 先通过pillar获取minion主机IP
 # vi /srv/pillar/ip.sls
 ip: {{ grains['ipv4'][1] }}
 #写完后，执行sls命令，可以看到已经获取到IP

 # salt '*' pillar.item ip
 host2:
     ----------
     ip:
         192.168.18.213
 host1:
     ----------
     ip:
         192.168.18.212
 2.3 随后写个sate文件，将文件分发到minion上

 # mkdir /srv/salt/zabbix
 # vi /srv/salt/zabbix/agentd_conf.sls
 zabbix:
   file.managed:
     - source: salt://zabbix/zabbix_agentd.conf
     - name: /usr/local/zabbix/conf/zabbix_agentd.conf
     - template: jinja
     - defaults:
      ip: {{ pillar['ip'] }}
 
 2.4 修改zabbix_agentd.conf要渲染的IP
 # vi /srv/salt/zabbix/zabbix_agentd.conf
 LogFile=/tmp/zabbix_agentd.log
 Server=192.168.18.214
 ServerActive=127.0.0.1
 Hostname={{ ip }}
 
 2.5 执行单sls命令，不用将sls文件关联到top.sls文件                         
 # salt '*' state.sls zabbix.agentd_conf
 host1:
 ----------
           ID: zabbix
     Function: file.managed
         Name:/usr/local/zabbix/conf/zabbix_agentd.conf
        Result: True
       Comment: File/usr/local/zabbix/conf/zabbix_agentd.conf is in the correct state
      Started: 11:48:35.261683
     Duration: 139.733 ms
      Changes:  
  
 Summary
 ------------
 Succeeded: 1
 Failed:    0
 ------------
 Total states run:     1 
 host2:
 ----------
          ID: zabbix
    Function: file.managed
        Name:/usr/local/zabbix/conf/zabbix_agentd.conf
      Result: True
     Comment: File/usr/local/zabbix/conf/zabbix_agentd.conf is in the correct state
     Started: 11:31:41.906766
    Duration: 141.928 ms
     Changes:  
  
 Summary
 ------------
 Succeeded: 1
 Failed:    0
 ------------
 Total states run:     1
 #这时再通过命令查看，已经更新成功

 # salt '*' cmd.run 'cat/usr/local/zabbix/conf/zabbix_agentd.conf'      
 host1:
    LogFile=/tmp/zabbix_agentd.log
    Server=192.168.18.214
    ServerActive=127.0.0.1
    Hostname=192.168.18.212
 host2:
    LogFile=/tmp/zabbix_agentd.log
    Server=192.168.18.214
    ServerActive=127.0.0.1
    Hostname=192.168.18.213
pillar相关命令：
#刷新pillar数据到minion
# salt "*" saltutil.refresh_pillar
#查看所有pillar信息
# salt "*" pillar.items
#查看某个pillar信息
# salt "*" pillar.item ip
既然grains与pillar类似，就说下区别：
1.grains是minion每次加载时获取本地系统信息数据，是静态的，固定的，而pillar是动态加载数据，随时变化的，比grains更灵活。
2.grains数据存储在minion本地，pillar存储在master。