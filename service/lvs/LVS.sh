LVS概述
1、LVS（Linux Virtual Server）Linux虚拟服务器：是一个虚拟的服务器集群系统。本项目在1998年5月有章文嵩博士成立，是中国国内最早出现的自由软件项目之一。通过LVS提供的负载均衡技术和Linux操作系统可实现一个高性能、高可用的服务器集群，从而以低成本实现最优的服务性能。
2、集群简介：集群（Cluster）是一组相互独立的、通过高速网络互联的计算机，它们构成了一个组，并以单一系统的模式加以管理。一个客户与集群相互作用时，集群像是一个独立的服务器。集群配置是用于提高可用性和可缩放性。集群系统的主要优点：高可扩展性、高可用性、高性能、高性价比。
3、集群类型
    LB：Load Balancing 高可拓展，伸缩集群
    HA ：High Availability 高可用集群
    HP：High Performance 高性能集群
LVS详解
一、LVS组成：LVS其实由两个组件组成，在用户空间的ipvsadm和内核空间的ipvs，ipvs工作于INPUT链上，如果有请求报文被ipvs事先定义，就会将请求报文直接截取下根据其特定的模型修改请求报文，再转发到POSTROUTING链上送出TCP/IP协议栈。


二、LVS的实现模型：LVS在不同场景中提供了4种实现模型：分别是NAT，DR，TUN，FULLNAT。
1、NAT工作模式
实现原理：NAT模型其实就是一个多路的DNAT，客户端对VIP进行请求，Director通过事先指定好的调度算法计算出应该转发到那台RS上，并修改请求报文的目标地址为RIP，通过DIP送往RS。当RS响应客户端报文给CIP，在经过Director时，Director又会修改源地址为VIP并将响应报文发送给客户端，这段过程对于用户来说是透明的。
NAT特性：
1）RS和Director必须要在同一个IP网段中。
2）RS的网关必须指向DIP
3）可以实现端口映射
4）请求报文和响应报文都会经过Director
5）RS可以是任意OS
6）DIP和RIP只能是内网IP


NAT工作流程：
1）客户端将请求发送前端的负载均衡器，请求报文源地址是CIP(客户端IP），目标地址为VIP(负载均衡器前端地址)；
2）负载均衡器收到报文后，发现请求的是在规则里面存在的地址，做DNAT，把目标IP转换为任意后端RS的RIP，然后发送到后端服务器。
3）报文送到Real Server，进行响应，响应报文源IP为RIP，目标IP还是CIP，但是网关指向DIP。
4）Dirctor接收到响应报文后，自动进行源地址转换，把RIP转换为VIP，发往互联网，到达客户端。
2、DR工作模式

DR模型是一个比较复杂的模型，因为VIP在Director和每一个RS上都存在，客户端对VIP（Director）请求时，Director接收到请求，会将请求报文的源MAC地址和目标MAC地址修改为本机DIP所在网卡的MAC地址和指定的RS的RIP所在网卡的MAC地址，RS接收到请求报文后直接对CIP发出响应报文，而不需要经过Director。
DR特性：
1）RS和Director可以不在同一IP网段中，但是一定要在同一物理网络中。（最好同一网段）
2）RS可以使用公网地址，此时可以直接通过互联网连入，配置监控RS服务器。
3）RS的网关一定不能指向Director。
4）客户端请求报文必须经过Director，但是响应报文一定不能通过Director。
5）不能实现端口映射。
6）RS可以是大部分操作系统。
DR模型的问题（客户请求VIP怎么到达Director）：
1）网络设备（路由器）中设置VIP地址和Director的MAC地址进行绑定。（前提：路由器的配置权限；缺点：Director故障转移，无法更新此绑定；）
2）arptables（前提：在各RS安装arptables程序，并编写arptables规则；缺点：依赖于独特功能的应用程序；）
3）修改Linux内核参数，arp_ignore，arp_announce（前提：RS必须是Linux；缺点：适用性差；）
 两个参数的取值含义：
    arp_announce：定义通告模式
            0：default，只要主机接入网络，则自动通告所有网卡MAC地址。
            1：尽力不通告非直接连入网络的网卡MAC地址。
            2：只通告直接进入网络的网卡MAC地址。
    arp_ignore：定义收到arp请求时的响应模式                        
            0：只有arp广播请求，马上响应，并且响应所有本机网卡的mac地址。
            1：只响应，接受arp广播请求的网卡接口mac地址。
            2：只响应，接受arp广播请求的网卡接口mac地址，并且需要请求广播于接口地址属于同一网段。
            3：主机范围（Scope host）内生效的接口，不予响应，只响应全局生效于外网能通信的网卡接口。
            4-7：保留位
            8：不响应一切arp广播请求。

DR工作流程：
DR模型，当RIP，DIP，VIP全部为公网地址时：
1）客户端对VIP发送请求。
2）Director接收请求，发现是请求后端的集群服务，然后对后端集群RIP发起ARP请求。
3）Director得到后方RS的MAC地址后，选择一个把请求通过MAC地址发送给后端服务器。
4）RS接收到请求后，进行响应，使用隐藏的VIP进行封装报文，但使用RIP所在网卡进行向外发送。
5）RS发出的响应报文由于是使用VIP隐藏网卡封装，因此源IP为VIP，目标IP为CIP，所以报文直接发往互联网路由器，到达客户端。
DR模型，当RIP，DIP，VIP全部为私有地址时：
1）客户端对VIP发送请求。
2）Director接收请求，发现是请求后端集群服务，然后对后端集群RIP发起ARP请求。
3）Director得到后方RS的MAC地址后，现在一个把请求通过MAC地址发送给后端服务器。
4）RS接收到请求后，进行响应，使用隐藏的VIP网卡进行封装报文，但使用RIP所在网卡进行向外发送。
5）RS发出的响应报文由于是使用VIP隐藏网卡封装，因此源IP为VIP，目标IP为CIP。
6）由于RS的通信RIP地址为私有地址，因此网关需要指向并发往转发服务器同网段地址网卡。
7）转发服务器将响应报文发往互联网，最终到达客户端。
3、TUN：IP隧道，IP报文中套IP报文
TUN模型通过隧道的方式在公网中实现请求报文的转发，客户端请求VIP（Director），Director不修改请求报文的源IP和目标IP，而是在IP首部前附加DIP和对应的RIP地址并转发到RIP上，RS收到请求报文，RS的本地接口上也有VIP，遂直接响应报文给CIP。
TUN特性
1）RIP，DIP，VIP都必须是公网地址。
2）RS网关不会指向DIP。
3）请求报文必须经过Director，但响应报文一定不经过Director。
4）不支持端口映射。
5）RS的OS(操作系统)必须得支持隧道功能。
wKiom1eiuNOwSGRfAABi8Ue00Oc447.jpg
TUN模型，通常为异地容灾策略：
1）客户端对VIP发送请求。
2）Director接收请求，发现是请求后端集群服务，由于和RS在异地网络，因此在原请求报文的基础上，在加上一层，源IP为DIP，目标IP为RIP的层。
3）Director将加了包装的报文发往互联网，互联网路由将TUN报文路由发往响应的RS。
4）RS接收到请求后，拆掉外出IP首部，发现里面还有一层IP首部，并且目标地址为自己的VIP，因此接收报文并响应。
5）RS通过隐藏VIP包装响应报文，目标IP仍然是原CIP。
6）RS将响应报文发往互联网路由器，并最终路由至客户端。
4、FullNAT：NAT的增强版
FULLNAT是最近几年才出现的，客户端请求VIP（Director），Director修改请求报文的源地址（DIP）和目标地址（RIP）并转发给RS，FULLNAT模型一般是Director和RS处于复杂的内网环境中的实现。
FULLNAT特性：
1）VIP是公网地址，DIP和RIP是内网地址，但是无需在同一网络中。
2）请求报文需要经过Director，响应报文也要经过Director。
3）RIP接收到的请求报文的源地址为DIP，目标地址为RIP。
4）支持端口映射。
5）RS可以是任意的OS（操作系统）。
wKioL1ei0aqycTbtAADmPDSGm14147.png
三、LVS的调度算法
静态方法：仅根据调度算法本身进行调度

rr：round robin，轮流，轮训，轮叫，轮调
wrr：weighted round robin，加强轮询
sh：source hashing，session绑定
dh：destination hashing,目标地址hash
动态方法：根据算法及各RS当前的负载状况进行调度

lc：least connection，最少连接
wlc：weighted lc，加权最少连接
sed：shortest expection delay，最少期望延迟
nq：never queue，永不排队
lblc：Locality-Based Least Connection，基于局部性的最少连接
lblcr：Replicated lblc，基于局部性的带复制功能的最少连接
LVS缺陷：不能检查后端服务器的健康情况，总是发送连接到后端。
session持久机制：
1、session绑定：始终将同一个请求者的连接定向至同一个RS（第一次请求时仍由调度方法选择）；没有容错能力，有损负载均衡效果。
2、session复制：在RS之间同步session，因此，每个RS中都有集群中所有的session；对于大规模集群环境不适用。
3、session服务器：利用单独部署的服务器来同一管理session。
四、LVS使用方法（ipvsadm）

命令格式：
ipvsadm -A|E -t|u|f service-address [-s scheduler]
              [-p [timeout]] [-M netmask]
      ipvsadm -D -t|u|f service-address
      ipvsadm -C
      ipvsadm -R
      ipvsadm -S [-n]
      ipvsadm -a|e -t|u|f service-address -r server-address
              [-g|i|m] [-w weight] [-x upper] [-y lower]
      ipvsadm -d -t|u|f service-address -r server-address
      ipvsadm -L|l [options]
      ipvsadm -Z [-t|u|f service-address]
      ipvsadm --set tcp tcpfin udp
      ipvsadm --start-daemon state [--mcast-interface interface]
              [--syncid syncid]
      ipvsadm --stop-daemon state
      ipvsadm -h
       
命令详解：
    定义集群服务：
        -A 添加一个集群服务
        -D -t|u|f service-address：删除指定的集群服务 
        -E 修改一个集群服务
        -t VIP:端口 定义集群服务的类型为TCP的某个端口
        -u VIP:端口 定义集群服务的类型为UDP的某个端口
        -f 防火墙标记 定义集群服务的类型为防火墙标记
        -s 调度算法 指定集群服务的调度算法 
        -p timeout：persistent connection，持久连接
    定义集群节点：
        -a 添加一个节点到集群服务
            -t|-u|-f service-address：指明将RS添加至那个Cluster-service中
            -r：指定RS，可包含｛IP[:port]｝，只有支持端口映射的lvs类型才能使用跟集群服务中不同的端口
        -d 从集群服务中删除一个节点
        -e 修改集群服务器中的节点
        -r 节点IP:端口  定义节点的IP及类型
        -m 定义为NAT模型
        -g 定义为DR模型
        -i 定义为TUN模型
        -w 权重 定义服务器的权重
    查看已经定义的集群服务及RS：
        ipvsadm -L [options]
                -c：查看各连接
                -n：数字格式显示IP地址
                --stats: 显示统计数据
                --rate:　速率
                --exact: 显示统计数据的精确值
                --timeout：超时时间
             -Z：计数器清零；
    从集群服务中删除RS：
        ipvsadm -d -t|u|f service-address -r server-address
    删除集群服务：
        ipvsadm -D -t|u|f service-address
    清空所有的集群服务：
        ipvsadm -C 
    保存集群服务定义：
        ipvsadm -S > /path/to/some_rule_file
        ipvsadm-save > /path/to/some_rule_file
    让规则文件中的规则生效：
        ipvsadm -R < /path/from/some_rule_file
        ipvsadm-restore < /path/from/some_rule_file
五、LVS各种模型的实现
1、LVS NAT模型的实现

1、集群环境，一台Director，两台后端Real server RS1，RS2
    Director：两张网卡
        eth0:192.168.120.100/24     #VIP地址
        eth1:172.16.10.1/16
    RS1:   eth1:172.16.10.11/16
    RS2:   eth1:172.16.10.12/16
    Director的eth1和RS1，RS2的eth1模拟在同一网络，使用物理机
    Windows7作为客户端在192.168.120.0/24网段中
2、为RS添加网关指向Director
    RS1：
        # ifconfig eth1 172.16.10.11/16 up
        # route add default gw 172.16.10.1
    RS2：
        # ifconfig eth1  172.16.10.12/16 up
        # route add default gw 172.16.10.1
3、修改内核参数，开启转发功能
    # echo 1 > /proc/sys/net/ipv4/ip_forward
4、在RS1和RS2上分别创建测试页，并在Director验证服务
    [root@node2 ~]# echo node2.bjwf.com > /var/www/html/index.html
    [root@node2 ~]# systemctl start httpd.service
    [root@node3 ~]# echo node3.bjwf.com > /var/www/html/index.html
    [root@node3 ~]# systemctl start httpd.service
    Director上验证：
    [root@node1 ~]# curl http://172.16.10.11
    node2.bjwf.com
    [root@node1 ~]# curl http://172.16.10.12
    node3.bjwf.com
5、在Director添加集群服务
    [root@node1 ~]# yum -y install ipvsadm    #安装集群管理软件
    # ipvsadm -A -t 192.168.120.210:80 -s rr
    # ipvsadm -a -t 192.168.120.210:80 -r 172.16.10.11:80 -m -w 1
    # ipvsadm -a -t 192.168.120.210:80 -r 172.16.10.12:80 -m -w 1
2、LVS DR模型的实现

1、集群环境，一台Director，两台后端Real server RS1，RS2
    Director：    eth0:192.168.120.100/24  
       配置VIP：ifconfig eth0:0 192.168.120.110 netmask 255.255.255.255 broadcast 192.168.120.110
    RS1:       eth0:192.168.120.211/24  
    RS2:       eth0:192.168.120.212/24  
    VIP:          192.168.120.100
2、修改RS1，RS2的内核参数，关闭lo的arp通告和lo的arp响应，并配置隐藏地址
    # echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
    # echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
    # echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore 
    # echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
    # ifconfig lo:1 192.168.120.100 netmask 255.255.255.255 broadcast 192.168.120.100
3、在RS1和RS2上分别创建测试页，并在Director验证服务
    [root@node2 ~]# echo node2.bjwf.com > /var/www/html/index.html
    [root@node2 ~]# systemctl start httpd.service
    [root@node3 ~]# echo node3.bjwf.com > /var/www/html/index.html
    [root@node3 ~]# systemctl start httpd.service
    Director上验证：
    [root@node1 ~]# curl http://192.168.120.101
    node2.bjwf.com
    [root@node1 ~]# curl http://192.168.120.102
    node3.bjwf.com
4、为RS1和RS2添加路由条目，保证其发出报文经过eth0之前，还要进过lo:0，保证源地址为VIP
    # route add 192.168.120.110 dev lo:1
5、在Director添加集群服务
    # ipvsadm -A -t 192.168.120.110:80 -s rr
    # ipvsadm -a -t 192.168.120.110:80 -r 192.168.120.101:80 -g -w 1
    # ipvsadm -a -t 192.168.120.110:80 -r 192.168.120.102:80 -g -w 1