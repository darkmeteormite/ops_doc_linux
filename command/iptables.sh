iptables
防火墙最重要的任务就是规划出：
	切割被信任（如子域）与不被信任（如Internet）的网段；
	划分出可提供Internet的服务与必须受保护的服务；
	分析出可接受与不可接受的封包状态；
3表
	filter(过滤器)：主要跟进入Linux本机的封包有关，这个是预设的table.
		INPUT：主要与想要进入我们Linux本机的封包有关；
		OUTPUT：主要与我们Linux本机所要送出的封包有关；
		FORWORD：转发到后端服务器中，与本机没有关系；
	nat(地址转换)：主要进行来源于目的IP或PORT的转换，与Linux本机无关，主要与Linux主机后的局域网络内计算机较有相关。
		PREROUTING：在进行路由判断之前所要进行的规则（DNAT/REDIRECT）
		POSTROUTING：在进行路由判断之后所要进行的规则（SNAT/MASQUERADE）
		OUTPUT：与发送出去的封包有关
	mangle(破坏者)：主要与特殊的封包的路由旗标有关。

一、 iptables 查看链表，创建链表，清除链表类命令
    1. iptables [-t table] -N chain ：创建一条自定义规则的链 
    # iptables -t filter -N clean_in 
    注： 自定义链在没有被引用之前是不起作用的。
    2. iptables [-t filter] -X [chain] ：删除一个自定义链
    # iptables -t filter -X clean_in
    3. iptables [-t table] -E old-chain-name new-chain-name：为一个自定义链修改名字
    # iptables -t filter -E clean_in clean_in_httpd
    4. iptables [-t table] {-F|-L|-Z} [chain [runlenum]] [options…] ：查看修改规则命令组 
	    -L：list,列出表中的所有规则 
	        -n: 数字格式显示IP和Port 
	        -v: 详细格式显示 
	            pkts    bytes    target    prot    opt    in    out    source    destination 
	            每个字段的含义： 
	            pkts: packets, 被本规则所匹配到的报文的个数；
	            bytes: 被本规则所匹配到的所有报文的大小之和，会执行单位换算；
		        target: 目标，即处理机制;
		        prot: 协议，一般为{TCP|UDP|ICMP}; 
		        opt: 可选项
		        in: 数据包的流入接口；
		        out: 数据包的流出接口；
		        source: 源地址；
		        destination: 目标地址；
		    --line-number: 显示各规则的行号 
	    -X：exactly, 精确值，不执行单位换算，杀掉所有使用者“自定义”的chain（应该说的是table）。
	    -F：清空链中的规则，规则具有编号，从上到下，从1开始
	    -Z：将所有的chain的计数与流量统计都归零
	*这三个指令会将本机防火墙的所有规则都清除，但却不会改变预设政策（policy），所有对本机下达这三条指令时，很可能被自己挡在家门外（若INPUT设定为DROP时）！必须小心！
	5. iptables [-t table] -P [INPUT,OUTPUT,FORWARD] [ACCEPT,DROP]：为链指定默认策略，指定默认规则
    	-P：定义政策(Policy)。注意，这个P为大写。
    		ACCEPT:该封包可接受。
    		DROP:该封包直接丢弃，不会让client端知道为何被丢弃。
	清除规则之后，接下来就是设定规则的政策了(当你封包不在你设定的规则之内时，则该封包的通过与否，是以policy的设定为准)

二、 iptables 添加和编辑规则相关命令 

    1. iptables [-t table] {-A | -D} chain rule-specification 
	   -A: append，附加一条规则
	   -D chain [rulenum] rule-specification：删除一条规则
	   -I chain [rulenum] rule-specification：插入规则，如果没有指定规则的顺序，则默认添加为第一条
	   -R chain [rulenum] rule-specification：替换指定规则
	   -S chain [rulenum] 只显示链上的规则添加
		    chain：在那一个链上进行操作
		    rulenum：插入位置，这块一般是数字，指定插入或者修改那一条
		    rule-specification格式:
			    匹配条件 -j 处理机制  
			    通用匹配条件：
		        -s: 匹配原地址，可以IP，也可以是网络地址，可以使用！操作符取反，！192.168.0.0/16; -s 相当于 --src 或 --source 
		        -d: 匹配目标地址 
		        -p: 匹配协议，通常只使用{tcp|udp|icmp}三者之一或者all； 
		        -i：数据报文流入的接口：通常用于INPUT, FORWARD, PREROUTING
		        -o：流出接口，通常只用于OUTPUT，FORWARD,和POSTROUTING
	    -j target 
	        RETURN:返回调用链
	        ACCEPT:放行 
  
    举例：
    1. 允许192.168.98.0/24网段ping通，当前192.168.98.128主机
    # iptables -t filter -A INPUT  -i eth0 -s 192.168.98.0/24 -d 192.168.98.128/24 -p ICMP -j ACCEPT 
    # iptables -t filter -A OUTPUT -s 192.168.98.128 -d 192.168.98.0/24 -p ICMP -j ACCEPT   
     
    结果； ICMP INPUT和OUTPUT链都有匹配到      
    Chain INPUT (policy ACCEPT 57 packets, 4188 bytes)
    pkts bytes target     prot opt in     out     source               destination         
    29   2436  ACCEPT     icmp --  eth0   *       192.168.98.0/24      192.168.98.0/24 
    
    Chain OUTPUT (policy ACCEPT 41 packets, 4980 bytes)
    pkts bytes target     prot opt in     out     source               destination         
    29   2436  ACCEPT     icmp --  *      *       192.168.98.128       192.168.98.0/24
    
    2. iptables规则保存 
    # service iptables save: 默认会被保存在/etc/sysconfig/iptables文件中，start的时候也会从这里读取 
    下面两种方式也可以存取
    # iptables-save > /path/to/some_rulefile
    # iptables-restore < /path/from/some_rulefile

	3. iptables隐含扩展配置

    1）tcp协议的隐含扩展
    -p tcp 
        --dport m[-n]:匹配的目标端口，可以使连续的多个端口
        --sport: 源端口 
        --tcp-flags rst,syn,ack,fin syn : 空格之前表示匹配哪些标识位，空格之后是哪些标识位为1 
        --syn：单独匹配某一项标识位
        所有使用的值: URG, PSH, RST, SYN, ACK, FIN,ALL, NONE
         
        举例： 释放所有192.168.98.0/24网段的ssh服务
        # iptables -t filter -A INPUT -s 192.168.98.0/24 -d 192.168.98.128/24 -p tcp --dport 22 -j ACCEPT 
        # iptables -t filter -A OUTPUT -s 192.168.98.128/24 -d 192.168.98.0/24 -p tcp --sport 22 -j ACCEPT 
        # iptables -t filter -P INPUT DROP
        # iptables -t filter -P OUTPUT DROP
         
        结果： ssh链接不会断开，可以看见进出都有报文匹配，而ping报文会被drop 
            Chain INPUT (policy DROP 45 packets, 3588 bytes)
            pkts bytes target     prot opt in     out     source               destination         
            967 70220 ACCEPT     tcp  --  *      *       192.168.98.0/24      192.168.98.0/24     tcp dpt:22        
 
            Chain OUTPUT (policy DROP 22 packets, 5608 bytes)
            pkts bytes target     prot opt in     out     source               destination         
            426 48420 ACCEPT     tcp  --  *      *       192.168.98.0/24      192.168.98.0/24     tcp spt:22
    2）udp 协议的隐含扩展
  	-p udp : udp报文相关的拓展匹配
        --dport 
        --sport 
        放行本机的tftp服务
        # iptables -t filter -A INPUT -s 192.168.98.0/24 -d 192.168.98.128/24 -p udp --dport 69 -j ACCEPT 
        # iptables -t filter -A OUTPUT -s 192.168.98.128/24 -d 192.168.98.0/24 -p udp --sport 69 -j ACCEPT 
         
        放行本机DNS服务
        # iptables -t filter -A INPUT -s 192.168.98.0/24 -d 192.168.98.128/24 -p udp --dport 53 -j ACCEPT 
        # iptables -t filter -A INPUT -s 192.168.98.128/24 -d 192.168.98.0/24 -p udp --sport 53 -j ACCEPT
    3）icmp 协议的隐含扩展 
    -p icmp : icmp协议相关拓展 
        --icmp-type
            8: ping 请求 
            0：ping 响应 
             
        释放本机的ping请求 
        # iptables -t filter -A INPUT -s 192.168.98.0/24 -d 192.168.98.128/24 -p icmp --icmp-type 8 
        # iptables -t filter -A INPUT -s 192.168.98.128/24 -d 192.168.98.0/24 -p icmp --icmp-type 0
    
    4. 显示扩展：必须指定的扩展模块

        -m    扩展模块名称    –专用选项1    –专用选项2

    1）multiport：多端口匹配模块，一次可以指定最多15离散端口。 
    -m multiport 
       --source-ports,--sports port[,port|,port:port] ： 指定源端口
       --destination-port, --dports: 指定目标端口 
       --ports: 指定源端口和目标端口
    
    举例： 
    开放本机所在网络，ssh和web服务。 
    # iptables -t filter -A INPUT -s 192.168.98.0/24 -d 192.168.98.128/24 -p tcp -m multiport --dport 22,80 -j ACCEPT 
    # iptables -t filter -A OUTPUT -s 192.168.98.128/24 -d 192.168.98.0/24 -p tcp  -m multiport --sport 22.80 -j ACCEPT
    
    2) iprange：匹配ip地址范围
    -m iprange: 
        [!] --src-range from[-to]
        [!] --dst-range from[-to]
     
    举例：
    开放本机ssh给192.168.98.1-192.168.98.120访问
    # iptables -t filter -A INPUT -d 192.168.98.128 -p tcp --dport 22 -m iprange --src-range 192.168.98.1-192.168.98.120 -j ACCEPT
    # iptables -t filter -A OUTPUT -s 192.168.98.128 -p tcp --dport 22 -m iprange --dst-range 192.168.98.1-192.168.98.120 -j ACCEPT
        
    3）time：指定时间范围匹配
    -m time 
        --datestart YYYY[-MM[-DD[Thh[:mm[:ss]]]]]
        --datestop YYYY[-MM[-DD[Thh[:mm[:ss]]]]]
        --timestart hh:mm[:ss]
        --timestop hh:mm[:ss]
        [!] --weekdays day[,day...]
         
    举例，在工作日时间开放samba（tcp, 901端口） 服务
    # iptables -t filter -A INPUT -d 192.168.98.128 -p tcp --dport 901 -m time --weekdays Mon,Tus,Wed,Thu,Fri --timestart 08:00:00 --time-stop 18:00:00 -j ACCEPT
    # iptables -t filter -A OUTPUT -s 192.168.98.128 -p tcp --sport 901 -j ACCEPT
        
    4) string：字符串过滤
    -m string 
        --algo {bm|kmp}:字符匹配查找时使用的算法
        --string "STRING" : 要查找的字符串
        --hex-string "HEX-STRING": 要查找的字符，先编码成16进制格式，可以提高查询效率
     
    举例： 禁止本机的web报文，包含‘hello’字符
    # iptables -t filter -A OUTPUT -s 192.168.98.128 -p tcp --dport 80 -j ACCEPT 
    # iptables -t filter -A INPUT -d 192.168.98.128 -p tcp --sport 80 -m string --algo bm --string "hello" -j DROP
        
    5）connlimit：每个ip对指定服务的最大并发链接数
    -m connlimit 
        --connlimit-above [0]：此选项用于，坚定某个IP是正常访问还是发起攻击
        
    6）limit：报文速率控制 
    -m limit 
        --limit #/[/second|/minute|/hour|/day]  限制速率
        --limit-burst # 峰值速率
     
    举例: 防御DDos攻击
    # iptables -t filter -I INPUT -d 192.168.98.128 -p icmp --icmp-type 8 -m limit --limit 2/second --limit-burst 10 -j ACCEPT
    在另一台主机上，使用hping3命令发起攻击 
    # hping -1 -c 10000 -i u1  192.168.98.128
     
    结果： 
    Chain INPUT (policy DROP 9990 packets, 280K bytes)
    pkts bytes target     prot opt in     out     source               destination
    10   280 ACCEPT     icmp --  *      *       0.0.0.0/0            192.168.98.128    icmp type 8 limit: avg 2/sec burst 10
     
    可以看到只有10个报文通过，其他的icmp请求全被drop了
        
    7）state：状态匹配

    -m state 
        --state 
            NEW：新建连接
            ESTABLISHED：已经建立的连接  
            RELATED：与现有连接有关联的连接 
            INVALID： 异常连接
               
    状态匹配是由ip_conntrack, nf_conntrack两个模块实现的。 
    # cat /proc/sys/net/nf_conntrack_max 
     定义了连接追踪的最大值，因此，建议按需调大此值；
    # cat /proc/net/nf_conntrack
     记录了当前追踪的所有连接
    # cat /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established
     记录建立的连接超时时间
      
    法则：
        1. 对于进入的状态为ESTABLISHED都应该放行；
        2. 对于出去的状态为ESTABLISHED都应该放行；
        3. 严格检查进入的状态为NEW的连接；
        4. 所有状态为INVALIED都应该拒绝；
    
   举例：放行工作于被动模式下的FTP服务
      1. 确保iptables加载ftp协议支持的模块：ip_nat_ftp, ip_conntrack_ftp
        编辑/etc/sysconfig/iptables-config文件，定义如下参数：
        IPTABLES_MODULES="ip_nat_ftp ip_conntrack_ftp"
      2. 开放命令连接端口，tcp 21号端口 
        # iptables -t filter -A INPUT -d 192.168.98.128 -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT 
      3. 放行请求报文的RELATED和ESTABLISHED状态，放行响应报文的ESTABLISHED状态；
        # iptables -t filter -A INPUT -d 192.168.98.128 -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT 
        # iptables -t filter -A OUTPUT -s 192.168.98.128 -p tcp -m state --state ESTABLISHED -j ACCEPT
      如果只开放命令连接的话，依然可以进行身份认证，但是无法下载，或者查看目录
       
   启动服务时的最后一个服务通常是/etc/rc.d/rc.local (/etc/rc.local)，这事实上是一个脚本，但凡写在此脚本中的命令或脚本调用都在系统运行至此服务被执行



























