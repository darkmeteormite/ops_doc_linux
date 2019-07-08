一、安装rabbitmq
1、安装erlang
# yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel git xmlto libxslt ncurses zip unzip
# wget http://erlang.org/download/otp_src_20.3.tar.gz
# tar xf otp_src_20.3.tar.gz   #解压
# cd otp_src_20.3
# ./configure --prefix=/usr/local/erlang --with-ssl --enable-threads --enable-smp-support --enable-kernel-poll --enable-hipe --without-javac  //不用java编译，故去掉java避免错误    
# make && make install //编译后安装
添加环境变量  
# vi /etc/profile.d/erlang.sh   
export PATH=$PATH:/usr/local/erlang/bin  

2、安装elixir

# wget https://github.com/elixir-lang/elixir/archive/v1.6.0.tar.gz
# tar xf v1.6.0.tar.gz
# cd /root/elixir-1.6.0/
# vim Makefile
    PREFIX ?= /usr/local/elixir
# make clean test
# make install
# echo "export PATH=/usr/local/elixir/bin:$PATH" >> /etc/profile
# source /etc/profile


3、安装rabbitmq
# wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.6/rabbitmq-server-3.7.6.tar.xz
# tar xf rabbitmq-server-3.7.6.tar.xz
# cd rabbitmq-server-3.7.6.tar.xz
*编译安装并指定目录
# make 
# make install PREFIX=/usr/local/rabbitmq 
# echo "export PATH=/usr/local/rabbitmq/lib/erlang/lib/rabbitmq_server-3.7.6/sbin:$PATH" >> /etc/profile
# source /etc/profile

4、安装web插件管理界面
# mkdir /etc/rabbitmq
# rabbitmq-plugins enable rabbitmq_management

5、提供启动脚本
#!/bin/sh
#
# chkconfig:   - 20 80
# description: Starts and stops the redis daemon.

# Source function library.
. /etc/rc.d/init.d/functions
export PATH=/usr/local/bin:/usr/local/erlang/bin/:$PATH
export HOME=/root
# file_descriptors 1024 to 65535
ulimit -n 65536
rabbitmq_server="/usr/local/rabbitmq/lib/erlang/lib/rabbitmq_server-3.7.6/sbin/rabbitmq-server"
rabbitmq_ctl="/usr/local/rabbitmq/lib/erlang/lib/rabbitmq_server-3.7.6/sbin/rabbitmqctl"

start() {
    $rabbitmq_server -detached
}

stop() {
    $rabbitmq_ctl stop
}

restart() {
    stop
    start
}

status() {
    $rabbitmq_ctl status
}


case "$1" in
    start)
        start && exit 0
        $1
        ;;
    stop)
        stop || exit 0
        $1
        ;;
    restart)
    restart || exit 0
        $1
        ;;
    status)
        status
    $1
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart}"
        exit 2
esac
exit $?

6、修改定义数据目录和日志目录及网页管理端
# vim /etc/rabbitmq/rabbitmq-env.conf
RABBITMQ_MNESIA_BASE=/data/rabbitmq/mnesia
RABBITMQ_LOG_BASE=/data/rabbitmq/logs
RABBITMQ_NODE_PORT=5672

# vim /etc/rabbitmq/rabbitmq.config
[
{rabbit,[{tcp_listeners,[5672]},{loopback_users,[]}]}
].


7、交换器          
    direct:如果路由键匹配的话，消息就被投递到对应的队列。     
    fanout:这种类型的交换器会将收到的消息广播到绑定的队列上。消息通信模式很简单：当你发送一条消息到fanout交换器时，它会把消息投递给所有附加在此交换机的队列。这允许你对单条消息做不同方式的反应。
    topic:这类交换器允许你实现又去的消息通信场景，它使得来自不同源头的消息能够到达同一个队列。


二、集群模式配置
1、RabbitMQ集群概述
    通过Erlang的分布式特性（通过magic cookie认证节点）进行RabbitMQ集群，各RabbitMQ服务为对等节点，即每个节点都提供服务给客户端连接，进行消息发送与接收。
    这些节点通过 RabbitMQ HA 队列（镜像队列）进行消息队列结构复制。本方案中搭建2个节点，并且都是磁盘节点（所有节点状态保持一致，节点完全对等），只要有任何一个节点能够工作，RabbitMQ 集群对外就能提供服务。
2、集群的模式
    单一模式：最简单地情况，单点，非集群模式
    普通模式：默认的集群模式。
        对于Queue来说，消息实体只存在于其中一个节点，A、B两个节点仅有相同的元数据，即队列结构。
        当消息进入A节点的Queue中后，consumer从B节点拉取时，RabbitMQ会临时在A、B间进行消息传输，把A中的消息实体取出并经过B发送给consumer。所以consumer应尽量连接每一个节点，从中取消息。即对于同一个逻辑队列，要在多个节点建立屋里Queue。否则无论consumer连A或B，出口总在A，会产生瓶颈。
        该模式存在一个问题就是当A节点故障后，B节点无法取到A节点中还未消费的消息实体。
        如果做了消息持久化，那么得等A节点恢复，然后才可被消费；如果没有持久化的话，然后就没有然后了。。。   
    镜像模式：把需要的队列做成镜像队列，存在于多个节点，属于RabbitMQ的HA方案。
        该模式解决了上述问题，其实质和普通模式不同之处在于，消息实体会主动在镜像节点间同步，而不是在consumer取数据时临时拉取。
        该模式带来的副作用也很明显，除了降低系统性能外，如果镜像队列数量过多，加之大量的消息进入，集群内部的网络带宽将会被这种同步通讯大大消耗掉。
        所以在对可靠性要求较高的场合中适用。
3、RabbitMQ配置步骤
    （1）安装Erlang、RabbitMQ（文章上面有步骤）
    （2）修改/etc/hosts
        加入集群2节点的对应关系
        192.168.12.20 node1
        192.168.12.21 node2
    （3）设置Erlang Cookie 
        RabbitMQ节点之间和命令行工具（e.g.rabbitmqctl）是使用Cookie互通的，Cookie是一组随机的数字+字母的字符串。当RabbitMQ服务器启动的时候，Erlang VM会自动创建一个随机内容的Cookie文件。如果是通过源安装RabbitMQ的话，Erlang Cookie文件在/var/lib/rabbitmq/.erlang.cookie。如果是通过源码安装的RabbitMQ，Erlang Cookie文件在$HOME/.erlang.cookie。 
        [root@node1 ~]# ll .erlang.cookie    #启动node1节点会自动生成这个文件
        -r-------- 1 root root 20 12月 28 00:00 .erlang.cookie    #复制到节点node2中去
        [root@node1 ~]# scp .erlang.cookie node2:/root
        #确认节点的.erlang.cookie值一致
            [root@node1 ~]# cat .erlang.cookie
            ODVFCTFDGBCAEIIOCXDN
            [root@node2 ~]# cat .erlang.cookie
            ODVFCTFDGBCAEIIOCXDN
    （4）使用detached参数，在后台启动Rabbit node
        *先停止现有的Rabbitmq-server，在重新在后台运行
        node1:
            [root@node1 ~]# rabbitmqctl stop
            Stopping and halting node rabbit@node1 ...
            ...done.
            [root@node1 ~]# rabbitmq-server -detached
        node2:
            [root@node2 ~]# rabbitmqctl stop
            Stopping and halting node rabbit@node2 ...
            ...done.
            [root@node2 ~]# rabbitmq-server -detached
    （5）通过rabbitmqctl cluste_status命令，查看节点信息
        node1:
            [root@node1 ~]# rabbitmqctl cluster_status
            Cluster status of node rabbit@node1 ...
            [{nodes,[{disc,[rabbit@node1]}]},
             {running_nodes,[rabbit@node1]},
             {partitions,[]}]
            ...done.
        node2:
            [root@node2 ~]# rabbitmqctl cluster_status
            Cluster status of node rabbit@node2 ...
            [{nodes,[{disc,[rabbit@node2]}]},
             {running_nodes,[rabbit@node2]},
             {partitions,[]}]
            ...done.
    （6）将node1、node2组成集群
        因为rabbitmq-server启动时，会一起启动节点和应用，它预先设置RabbitMQ应用作为standalone模式。要将一个节点加入到现有的集群中，你需要停止这个应用并将节点设置为原始状态，然后就为加入集群准备好了。但是如果使用rabbitmqctl stop，应用和节点都将被关闭。所以可以使用rabbitmqctl stop_app仅仅关闭应用。
        node2
            [root@node2 ~]# rabbitmqctl stop_app
            Stopping node rabbit@node2 ...
            ...done.
            [root@node2 ~]# rabbitmqctl join_cluster rabbit@node1
            Clustering node rabbit@node2 with rabbit@node1 ...
            ...done.
        此时node2与node1会自动建立连接。
        如果要使用内存节点，则可以使用一下命令：
            [root@node2 ~]# rabbitmqctl join_cluster --ram rabbit@node1
        集群配置好后，可以在RabbitMQ任意节点上执行rabbitmqctl cluster_status来查看是否集群配置成功
        node1:
            [root@node1 ~]# rabbitmqctl cluster_status
            Cluster status of node rabbit@node1 ...
            [{nodes,[{disc,[rabbit@node1,rabbit@node2]}]},
             {running_nodes,[rabbit@node1]},
             {partitions,[]}]
            ...done.
        node2:
            [root@node2 ~]# rabbitmqctl cluster_status
            Cluster status of node rabbit@node2 ...
            [{nodes,[{disc,[rabbit@node1,rabbit@node2]}]}]
            ...done.
        重启node2上的应用
            [root@node2 ~]# rabbitmqctl start_app
            Starting node rabbit@node2 ...
            ...done.
        同时可以在web管理工具中看到集群信息（192.168.12.20:15672）
    （7）、RabbitMQ镜像功能
        使用Rabbit镜像功能，需要基于RabbitMQ策略来实现，策略是用来控制和修改群集范围的某个vhost队列行为和Exchange行为
        rabbitmqctl set_policy [-p vhostpath] {name} {pattern} {definition} [priority]
        例如：rabbitmqctl set_policy ha-allqueue "^" '{"ha-mode":"all"}'
            pattern：匹配队列名称的正则表达式，进行区分哪些队列使用哪些策略
            definition：其实就是一些arguments，支持如下参数：
                1、ha-mode:One of all, exactly or nodes (the latter currently not supported by web UI).
                2、ha-params:Absent if ha-mode is all, a number if ha-mode is exactly, or an array of strings if ha-mode is nodes.
                3、ha-sync-mode:One of manual or automatic. //如果不指定该参数默认为manual,这个在高可用集群测试的时候详细分析 
                4、federation-upstream-set:A string; only if the federation plugin is enabled.
        开始创建镜像模式
            [root@node1 ~]# rabbitmqctl set_policy -p '/www' ha-allqueue "^" '{"ha-mode":"all"}'
            这行命令在vhost名称为'/www'创建了一个策略，策略名称为ha-allqueue,策略模式为 all 即复制到所有节点，包含新增节点，策略正则表达式为 “^” 表示所有匹配所有队列名称。
            例如rabbitmqctl set_policy -p '/www' ha-allqueue "^message" '{"ha-mode":"all"}'
            注意："^message" 这个规则要根据自己修改，这个是指同步"message"开头的队列名称，我们配置时使用的应用于所有队列，所以表达式为"^"。
    （8）创建队列时需要指定ha参数，如果不指定x-ha-prolicy的话将无法复制
 
        下面C#代码片段
        using ( var bus = RabbitHutch.CreateBus(ConfigurationManager .ConnectionStrings["RabbitMQ"].ToString()))
            {
                bus.Subscribe< TestMessage>("word_subscriber" , message => RunTable(message),x=>x.WithArgument("x-ha-policy" , "all"));
                Console.WriteLine("Subscription Started. Hit any key quit" );
                Console.ReadKey();
            }
    （9）从集群中移除节点
        # rabbitmqctl stop_app仅仅关闭应用。
        # rabbitmqctl reset   #这里关键是reset，reset命令将清空节点的状态，并将其恢复到空白状态。这没错，只不过当重设的节点是集群的一部分时，该命令也会和集群中的磁盘节点进行通信，并告诉他们该节点正在离开集群。
    （10）使用haproxy集群搭建高可用
        *生产环境应该使用两台机器搭建高可用集群，分别按照haproxy
        # yum -y install haproxy   #只是做分发，所有可以直接yum安装
        # vim /etc/haproxy/haproxy.cfg
            listen rabbitmq_cluster 0.0.0.0:5672
            mode tcp
            balance  roundrobin
            server   rqslave1 192.168.12.20:5672 check inter 2000 rise 2 fall 3   
            server   rqslave2 192.168.12.21:5672 check inter 2000 rise 2 fall 3 
三、rabbitmq使用命令详解
[root@node1 ~]# rabbitmqctl list_queues -p /www    #查看vhost为/www的消息队列数
    应用和集群管理
    1、停止rabbitmq应用，关闭节点：rabbitmqctl stop
    2、停止rabbitmq应用：rabbitmqctl stop_app
    3、启动rabbitmq应用：rabbitmqctl start_app
    4、显示rabbitmq中间件各种信息：rabbitmqctl status
    5、重置rabbitmq节点：
        rabbitmqctl reset
        rabbitmqctl force_reset
        从它属于的任何集群中移除，从管理数据库中移除所有数据，例如配置过的用户和虚拟宿主，删除所有持久化的消息。force_reset命令和reset的区别是无条件重置节点，不管当前管理数据库状态以及集群的配置。如果数据库或者集群配置发生错误才使用这个最后的手段。
        *注意：只有在停止rabbitmq应用后，reset和force_reset才能成功。
        *也可在某个节点移除集群中其他节点
        如继续在rabbit@VMS00781上移除rabbit@VMS00782
        rabbitmqctl forget_cluster_node rabbit@VMS00782


    6、循环日志文件：rabbitmqctl rotate_logs [suffix]
    7、加入到某个节点中：rabbitmqctl join_cluster {clusternode} [--ram] 默认是ram类型，也可以使disc类型
    8、集群目前的状态：rabbitmqctl cluster_status
    9、改变当前节点的类型：rabbitmqctl change_cluster_node_type {disc|ram}使用此命令的时候必须先把该节点stop。
    10、同步某个队列（建立镜像队列）：rabbitmqctl sync_queue {queue-name}
    11、取消同步某个队列：rabbitmqctl cancel_sync_queue{queue-name}
    用户管理
    1、添加用户：rabbitmqctl add_user username password
    2、删除用户：rabbitmqctl delete_user username
    3、修改密码：rabbitmqctl change_password username newpassword
    4、清除密码：rabbitmqctl clear_password {username}
    5、设置用户标签：rabbitmqctl set_user_tags {username} {tag...}如果tag为空则表示清除这个用户的所有标签
    6、列出所有用户：rabbitmqctl list_users
    权限管理
    1、创建虚拟主机：rabbitmqctl add_vhost vhostpath
    2、删除虚拟主机：rabbitmqctl delete_vhost vhostpath
    3、列出所有虚拟主机：rabbitmqctl list_vhosts
    4、设置用户权限：rabbitmqctl chear_permissions [-p vhostpath] {username} {conf} {write} {read}
             例如：rabbitmqctl set_permissions -p huoban bjwf125 ".*" ".*" ".*"
                    -p huoban：这告诉了set_permissions条目应该应用到哪个vhosts上
                    bjwf125：被授予权限的用户
                    ".*" ".*" ".*"：这是授予的权限。这些值分别映射到配置，以及写和读
    5、清除用户权限：rabbitmqctl clear_permissions [-p vhostpath] {username}
        *如果想修改用户权限，直接重新设置即可
    6、列出虚拟主机上的所有权限：rabbitmqctl list_permissions [-p vhostpath]
    7、列出用户权限：rabbitmqctl list_user_permissions {username}
    协议管理
    1、设置协议：rabbitmqctl set_policy [-p vhostpath] [--priority priority] [--apply-to apply-to] {name} {pattern} {definition}
    a)name：协议的名字
    b)pattern：匹配的正则表达式
    c)definition：json term的形式来定义这个协议
    d)priority：优先级，数字越大优先级越高，默认为0
    e)apply-to：policy的类型，有三种：queues exchanges all 默认为all，具体定义可以去官网看文档
    2、清除协议：rabbitmqctl clear_policy [-p vhostpath] {name}
    3、列出协议列表：rabbitmqctl list_policies [-p vhostpath]
    服务器状态
    1、队列列表：rabbitmqctl list_queues [-p vhostpath] [queueinfoitem…]
        queueinfoitem:
            a) name
            b) durable
            c) auto_delete
            d) arguments
            e) policy
            f) pid
            g) owner_pid
            h) exclusive_consumer_pid
            i) exclusive_consumer_tag
            j) messages_ready
            k) messages_unacknowledged
            l) messages
            m) consumers
            n) active_consumers
            o) memory
            p) slave_pids
            q) synchronized_slave_pids
            r) status
    2、交换机列表：rabbitmqctl list_exchanges [-p vhostpath] [exchangeinfoitem…]
        exchangeinfoitem:
            a) name
            b) type
            c) durable
            d) auto_delete
            e) internal
            f) arguments
            g) policy
    3、绑定列表：rabbitmqctl list_bindings [-p vhostpath] [bindinginfoitem…]
        bindinginfoitem:
            a) source_name
            b) source_kind
            c) destination_name
            d) destination_kind
            e) routing_key
            f) arguments
    4、连接列表：rabbitmqctl list_connections不常用，具体去官网看文档
    5、通道列表：rabbitmqctl list_channels不常用，具体去官网看文档
    6、消费者列表：rabbitmqctl list_consumers
    7、当前状态：rabbitmqctl status
    8、当前环境：rabbitmqctl environment
    9、相关报告：rabbitmqctl report

    一些其他的命令
    后台开启rabbitmq服务：rabbitmq-server –detached
    声明队列：rabbitmqadmin declare queue name=queue-name durable={false | true}
    发布消息：rabbitmqadmin publish exchange=exchange-name routing_key=key payload=”context”
    命令安装方法：
        # wget http://localhost:55672/cli/rabbitmqadmin
        # chmod +x rabbitmqadmin

四、测试集群生产者和消费者信息传递
# wget https://github.com/barryp/py-amqplib/archive/master.zip
# unzip master.zip
# cd master
# python setup.py build
# python setup.py install
使用循环生产数据，另外一边接收数据
# for i in {1..10000};do python demo_send.py hello,world,$i; done
# python demo_receive.py    #生产者生产数据到haproxy上后，关闭其中一个rabbitmq-server，消费者还可以继续接收数据。

五、rabbitmq的web管理界面无法使用guest用户登陆
安装最新版本rabbitmq(3.6.5)，并启用management plugin后，使用默认的账号guest登陆管理控制台，却提示登陆失败。
查看官方的release文档后，得知由于账号guest具有所有的操作权限，并且又是默认账号，出于安全因素的考虑，guest用户只能通过localhost登陆使用，并建议修改guest用户的密码以及新建其他账号管理使用rabbitmq（该功能是在3.3.0版本引入的）。
虽然可以使用比较猥琐的方式：将ebin目录下rabbit.app中loopback_users里的<< "guest" >>删除，并重启rabbitmq，可通过任意IP使用guest账号登陆管理控制台，但始终是违背了设计者的初衷，所有总结一下。

如果要正常远程登录应该怎么做呢？处于安全考虑，guest这个默认的用户只能通过http://localhost:15672来登录，其他的IP无法直接用这个guest账号。这里我们可以通过配置文件来实现远程登录管理界面，只要编辑/etc/rabbitmq/rabbitmq.config文件（没有就新增）。
[
{rabbit,[{tcp_listeners,[5672]},{loopback_users,["huoban"]}]}
].
现在添加了一个新授权用户bjwf125,可以远程使用这个用户名。但是要先用命令添加这个用户才行：
    # cd /usr/lib/rabbitmq/bin/
    # rabbitmqctl add_user bjwf125 123456   #添加用户并创建密码
    用户设置为administrator才能远程访问
    # rabbitmqctl set_user_tags bjwf125 administrator
    # rabbitmqctl set_permissions -p / bjwf125 ".*" ".*" ".*"

1、用户管理
用户管理包括新增用户，删除用户，查看用户列表，修改用户密码。
    
    新增用户：rabbitmqctl add_user Username Password
    删除用户：rabbitmqctl delete_user Username
    修改用户密码：rabbitmqctl change_password Username Newpassword
    查看当前用户列表：rabbitmqctl list_users

2、用户角色
按照个人理解，用户角色可分为五类，超级管理员，监控者，策略制定者，普通管理员及其他。

(1)、超级管理员(administrator)
可登陆管理控制台(启用management plugin的情况下)，可查看所有的信息，并且可以对用户，策略(policy)进行操作。
(2)、监控者(monitoring)
可登陆管理控制台(启用management plugin的情况下)，同时可以查看rabbitmq节点的相关信息（进程数，内存使用情况，磁盘使用情况等）
(3)、策略制定者(policymaker)
可登陆管理控制台(启用management plugin的情况下)，同时可以对policy进行管理。但无法查看节点的相关信息。
(4)、普通管理者(mangement)
仅可登陆管理控制台(启动mangement plugin的情况下)，无法看到节点信息，也无法对策略进行管理。
(5)、其他
无法登陆管理控制台，通常就是普通的生产者和消费者。

设置用户角色：
# rabbitmqctl set_user_tags User Tag
    User为用户名，Tag为角色名(对应于上面的administrator，monitoring，policymaker，management，或其他自定义名称)。

3、用户权限
用户权限指的是用户对exchange，queue的操作权限，包括配置权限，读写权限。配置权限会影响到exchange，queue的声明和删除。读写权限影响到从queue里取消息，向exchange发消息以及queue和exchange的绑定(bind)操作。
例如：将queue绑定到某exchange上，需要具有queue的可写权限，以及exchange的可读权限；向exchange发送消息需要具有exchange的可写权限；从queue里取数据需要具有queue的可读权限。

设置命令为：
(1)、设置用户权限：rabbitmqctl set_permissions -p VHostPath User ConfP WriteP ReadP
(2)、查看所有用户的权限信息：rabbitmqctl list_permissions [ -p VHostPath]
(3)、查看指定用户的权限信息：rabbitmqctl list_user_permissions User
(4)、清除用户的权限信息：rabbitmqctl clear_permissions [ -p VHostPath] User


