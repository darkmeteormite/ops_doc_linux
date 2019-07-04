OpenSSH
一、 简介
	使用SSH可以在本地主机和远程服务器之间进行加密地传输数据，实现数据的安全。而Openssh是SSH协议的免费开源实现，它采用安全、加密的网络连接工具代替了telnet、ftp等传输工具。
	SSH（secure shell）是建立在应用层和传输层基础上得安全协议。SSH是目前较可靠，专为远程登陆会话和其他网络服务提供的安全性协议。利用ssh协议可以有效防止远程管理过程中得信息泄露问题。
	SSH可以将所有的传输数据加密，这样“中间人”这种攻击方式就不可能实现了，而且也可以防止DNS和IP欺骗。还有一个额外的好处就是传输的数据经过压缩的，可以加快传输的速度。

二、 SSH工作原理

	SSH是由服务端和客户端的软件组成，服务端是一个守护进程，它在后台运行并响应来自客户端的连接请求。
	SSH的工作机制大体是：本地客户端发送一个连接请求到远程的服务端，服务端检查申请的包和IP地址再发送密钥给SSH客户端，本地再将密钥发回给服务端，到此为止，连接建立。
	启动SSH服务器后，sshd进程运行并在默认的22端口进行监听。安全验证方式：
	基于口令的安全验证（账号密码），也有可能受到中间人攻击
	基于密钥的安全验证，就是提供一对密钥，把公钥放在需要访问的服务器上，如果连接到SSH服务器上，客户端就会向服务器发出请求，请求用密钥进行安全验证，服务器收到请求之后，先在改服务器的主目录下寻找公钥，然后把它和发送过来的公钥进行比较。如果两个密钥一致，服务器就用公钥加密“质询”并把它发送给客户端。客户端收到“质询”之后就可以用私钥解密再把它发给服务器端。基于这种方式，相对比较安全。

三、OpenSSH配置

1、客户端配置
	ssh:配置文件 /etc/ssh/ssh_config

	ssh [options] [user@]host [COMMAND]
	ssh [-l user] [options] host [COMMAND]

	常用选项：
	-l user：以指定的用户登录远程主机；
	-p port：用于指明远程服务器的端口；远程服务器端口可变。
	-X：支持 X11 转发；
	-Y：支持信任的 X11 转发；
	    X：协议； x-window, C/S
	    X11 转发的作用：在本地显示远程主机上的图形窗口；
	    前提：本地是 X 图形界面，或者提供了 x service；
	-o StrictHostKeyChecking=no  是不是要对主机严格检查，建议no。


	ssh 支持的用户认证方式：
	    基于口令的认证；
	    基于密钥的认证；
	(1) 在本地主机生成一对儿密钥：
	    ssh-keygen [-q] [-b bits] [-t type] [-f output_keyfile] [-P passphrase]

	    -t {rsa|ecdsa|dsa}：公钥加密算法类型；
	    -b bits：指明密钥长度；
	    -P passphrase：私钥加密密码；
	    -f output_keyfile：生成密钥的保存位置；

	(2) 在本地主机上，将公钥复制到要登录的远程主机的某用户的家目录下的特定文件中(~/.ssh/authorized_keys)

	    ssh-copy-id [-i [identity_file]] [-p port] [-o ssh_option][user@]hostname

	(3) 测试
	    ssh user@host

2、服务器端配置
	sshd：配置文件 /etc/ssh/sshd_config
	几个主要的配置如下：
	Port 22   					#服务器监听的端口，默认为22
	ListenAddress 0.0.0.0   	#服务器端的ip地址
	Protocol 2              	#ssh protocol有两个版本，1不安全
	PermitRootLogin yes 		#设置root用户能否使用ssh登陆  建议用no
	UseDNS no   				#要不要反解用户的主机名
	PasswordAuthentication no  	#不允许密码登陆

	限制可登录的用户（配置文件）：
	    AllowUsers user1 user2 user3 ...   白名单
	    AllowGroups grp1 grp2 ...
	    DenyUsers user1 user2 ...
	    DenyGroups grp1 grp2 ...        黑名单

	CentOS 6：
	    服务脚本：/etc/rc.d/init.d/sshd
	CentOS 7：
	    Systemd Unit File：/usr/lib/systemd/system/sshd.service

	配置文件详解：

	AcceptEnv
             指定客户端发送的哪些环境变量将会被传递到会话环境中。[注意]只有SSH-2协议支持环境变量的传递。
             细节可以参考 ssh_config(5) 中的 SendEnv 配置指令。
             指令的值是空格分隔的变量名列表(其中可以使用'*'和'?'作为通配符)。也可以使用多个 AcceptEnv 达到同样的目的。
             需要注意的是，有些环境变量可能会被用于绕过禁止用户使用的环境变量。由于这个原因，该指令应当小心使用。
             默认是不传递任何环境变量。

     AddressFamily
             指定 sshd(8) 应当使用哪种地址族。取值范围是："any"(默认)、"inet"(仅IPv4)、"inet6"(仅IPv6)。

     AllowGroups
             这个指令后面跟着一串用空格分隔的组名列表(其中可以使用"*"和"?"通配符)。默认允许所有组登录。
             如果使用了这个指令，那么将仅允许这些组中的成员登录，而拒绝其它所有组。
             这里的"组"是指"主组"(primary group)，也就是/etc/passwd文件中指定的组。
             这里只允许使用组的名字而不允许使用GID。相关的 allow/deny 指令按照下列顺序处理：
             DenyUsers, AllowUsers, DenyGroups, AllowGroups

     AllowTcpForwarding
             是否允许TCP转发，默认值为"yes"。
             禁止TCP转发并不能增强安全性，除非禁止了用户对shell的访问，因为用户可以安装他们自己的转发器。

     AllowUsers
             这个指令后面跟着一串用空格分隔的用户名列表(其中可以使用"*"和"?"通配符)。默认允许所有用户登录。
             如果使用了这个指令，那么将仅允许这些用户登录，而拒绝其它所有用户。
             如果指定了 USER@HOST 模式的用户，那么 USER 和 HOST 将同时被检查。
             这里只允许使用用户的名字而不允许使用UID。相关的 allow/deny 指令按照下列顺序处理：
             DenyUsers, AllowUsers, DenyGroups, AllowGroups

     AuthorizedKeysFile
             存放该用户可以用来登录的 RSA/DSA 公钥。
             该指令中可以使用下列根据连接时的实际情况进行展开的符号：
             %% 表示'%'、%h 表示用户的主目录、%u 表示该用户的用户名。
             经过扩展之后的值必须要么是绝对路径，要么是相对于用户主目录的相对路径。
             默认值是".ssh/authorized_keys"。

     Banner
             将这个指令指定的文件中的内容在用户进行认证前显示给远程用户。
             这个特性仅能用于SSH-2，默认什么内容也不显示。"none"表示禁用这个特性。

     ChallengeResponseAuthentication
             是否允许质疑-应答(challenge-response)认证。默认值是"yes"。
             所有 login.conf(5) 中允许的认证方式都被支持。

     Ciphers
             指定SSH-2允许使用的加密算法。多个算法之间使用逗号分隔。可以使用的算法如下：
             "aes128-cbc", "aes192-cbc", "aes256-cbc", "aes128-ctr", "aes192-ctr", "aes256-ctr",
             "3des-cbc", "arcfour128", "arcfour256", "arcfour", "blowfish-cbc", "cast128-cbc"
             默认值是可以使用上述所有算法。

     ClientAliveCountMax
             sshd(8) 在未收到任何客户端回应前最多允许发送多少个"alive"消息。默认值是 3 。
             到达这个上限后，sshd(8) 将强制断开连接、关闭会话。
             需要注意的是，"alive"消息与 TCPKeepAlive 有很大差异。
             "alive"消息是通过加密连接发送的，因此不会被欺骗；而 TCPKeepAlive 却是可以被欺骗的。
             如果 ClientAliveInterval 被设为 15 并且将 ClientAliveCountMax 保持为默认值，
             那么无应答的客户端大约会在45秒后被强制断开。这个指令仅可以用于SSH-2协议。

     ClientAliveInterval
             设置一个以秒记的时长，如果超过这么长时间没有收到客户端的任何数据，
             sshd(8) 将通过安全通道向客户端发送一个"alive"消息，并等候应答。
             默认值 0 表示不发送"alive"消息。这个选项仅对SSH-2有效。

     Compression
             是否对通信数据进行加密，还是延迟到认证成功之后再对通信数据加密。
             可用值："yes", "delayed"(默认), "no"。

     DenyGroups
             这个指令后面跟着一串用空格分隔的组名列表(其中可以使用"*"和"?"通配符)。默认允许所有组登录。
             如果使用了这个指令，那么这些组中的成员将被拒绝登录。
             这里的"组"是指"主组"(primary group)，也就是/etc/passwd文件中指定的组。
             这里只允许使用组的名字而不允许使用GID。相关的 allow/deny 指令按照下列顺序处理：
             DenyUsers, AllowUsers, DenyGroups, AllowGroups

     DenyUsers
             这个指令后面跟着一串用空格分隔的用户名列表(其中可以使用"*"和"?"通配符)。默认允许所有用户登录。
             如果使用了这个指令，那么这些用户将被拒绝登录。
             如果指定了 USER@HOST 模式的用户，那么 USER 和 HOST 将同时被检查。
             这里只允许使用用户的名字而不允许使用UID。相关的 allow/deny 指令按照下列顺序处理：
             DenyUsers, AllowUsers, DenyGroups, AllowGroups

     ForceCommand
             强制执行这里指定的命令而忽略客户端提供的任何命令。这个命令将使用用户的登录shell执行(shell -c)。
             这可以应用于 shell 、命令、子系统的完成，通常用于 Match 块中。
             这个命令最初是在客户端通过 SSH_ORIGINAL_COMMAND 环境变量来支持的。

     GatewayPorts
             是否允许远程主机连接本地的转发端口。默认值是"no"。
             sshd(8) 默认将远程端口转发绑定到loopback地址。这样将阻止其它远程主机连接到转发端口。
             GatewayPorts 指令可以让 sshd 将远程端口转发绑定到非loopback地址，这样就可以允许远程主机连接了。
             "no"表示仅允许本地连接，"yes"表示强制将远程端口转发绑定到统配地址(wildcard address)，
             "clientspecified"表示允许客户端选择将远程端口转发绑定到哪个地址。

     GSSAPIAuthentication
             是否允许使用基于 GSSAPI 的用户认证。默认值为"no"。仅用于SSH-2。

     GSSAPICleanupCredentials
             是否在用户退出登录后自动销毁用户凭证缓存。默认值是"yes"。仅用于SSH-2。

     HostbasedAuthentication
             这个指令与 RhostsRSAAuthentication 类似，但是仅可以用于SSH-2。推荐使用默认值"no"。
             推荐使用默认值"no"禁止这种不安全的认证方式。

     HostbasedUsesNameFromPacketOnly
             在开启 HostbasedAuthentication 的情况下，
             指定服务器在使用 ~/.shosts ~/.rhosts /etc/hosts.equiv 进行远程主机名匹配时，是否进行反向域名查询。
             "yes"表示 sshd(8) 信任客户端提供的主机名而不进行反向查询。默认值是"no"。

     HostKey
             主机私钥文件的位置。如果权限不对，sshd(8) 可能会拒绝启动。
             SSH-1默认是 /etc/ssh/ssh_host_key 。
             SSH-2默认是 /etc/ssh/ssh_host_rsa_key 和 /etc/ssh/ssh_host_dsa_key 。
             一台主机可以拥有多个不同的私钥。"rsa1"仅用于SSH-1，"dsa"和"rsa"仅用于SSH-2。

     IgnoreRhosts
             是否在 RhostsRSAAuthentication 或 HostbasedAuthentication 过程中忽略 .rhosts 和 .shosts 文件。
             不过 /etc/hosts.equiv 和 /etc/shosts.equiv 仍将被使用。推荐设为默认值"yes"。

     IgnoreUserKnownHosts
             是否在 RhostsRSAAuthentication 或 HostbasedAuthentication 过程中忽略用户的 ~/.ssh/known_hosts 文件。
             默认值是"no"。为了提高安全性，可以设为"yes"。

     KerberosAuthentication
             是否要求用户为 PasswordAuthentication 提供的密码必须通过 Kerberos KDC 认证，也就是是否使用Kerberos认证。
             要使用Kerberos认证，服务器需要一个可以校验 KDC identity 的 Kerberos servtab 。默认值是"no"。

     KerberosGetAFSToken
             如果使用了 AFS 并且该用户有一个 Kerberos 5 TGT，那么开启该指令后，
             将会在访问用户的家目录前尝试获取一个 AFS token 。默认为"no"。

     KerberosOrLocalPasswd
             如果 Kerberos 密码认证失败，那么该密码还将要通过其它的认证机制(比如 /etc/passwd)。
             默认值为"yes"。

     KerberosTicketCleanup
             是否在用户退出登录后自动销毁用户的 ticket 。默认值是"yes"。

     KeyRegenerationInterval
             在SSH-1协议下，短命的服务器密钥将以此指令设置的时间为周期(秒)，不断重新生成。
             这个机制可以尽量减小密钥丢失或者黑客攻击造成的损失。
             设为 0 表示永不重新生成，默认为 3600(秒)。

     ListenAddress
             指定 sshd(8) 监听的网络地址，默认监听所有地址。可以使用下面的格式：

                   ListenAddress host|IPv4_addr|IPv6_addr
                   ListenAddress host|IPv4_addr:port
                   ListenAddress [host|IPv6_addr]:port

             如果未指定 port ，那么将使用 Port 指令的值。
             可以使用多个 ListenAddress 指令监听多个地址。

     LoginGraceTime
             限制用户必须在指定的时限内认证成功，0 表示无限制。默认值是 120 秒。

     LogLevel
             指定 sshd(8) 的日志等级(详细程度)。可用值如下：
             QUIET, FATAL, ERROR, INFO(默认), VERBOSE, DEBUG, DEBUG1, DEBUG2, DEBUG3
             DEBUG 与 DEBUG1 等价；DEBUG2 和 DEBUG3 则分别指定了更详细、更罗嗦的日志输出。
             比 DEBUG 更详细的日志可能会泄漏用户的敏感信息，因此反对使用。

     MACs
             指定允许在SSH-2中使用哪些消息摘要算法来进行数据校验。
             可以使用逗号分隔的列表来指定允许使用多个算法。默认值(包含所有可以使用的算法)是：
             hmac-md5,hmac-sha1,umac-64@openssh.com,hmac-ripemd160,hmac-sha1-96,hmac-md5-96

     Match
             引入一个条件块。块的结尾标志是另一个 Match 指令或者文件结尾。
             如果 Match 行上指定的条件都满足，那么随后的指令将覆盖全局配置中的指令。
             Match 的值是一个或多个"条件-模式"对。可用的"条件"是：User, Group, Host, Address 。
             只有下列指令可以在 Match 块中使用：AllowTcpForwarding, Banner,
             ForceCommand, GatewayPorts, GSSApiAuthentication,
             KbdInteractiveAuthentication, KerberosAuthentication,
             PasswordAuthentication, PermitOpen, PermitRootLogin,
             RhostsRSAAuthentication, RSAAuthentication, X11DisplayOffset,
             X11Forwarding, X11UseLocalHost

     MaxAuthTries
             指定每个连接最大允许的认证次数。默认值是 6 。
             如果失败认证的次数超过这个数值的一半，连接将被强制断开，且会生成额外的失败日志消息。

     MaxStartups
             最大允许保持多少个未认证的连接。默认值是 10 。
             到达限制后，将不再接受新连接，除非先前的连接认证成功或超出 LoginGraceTime 的限制。

     PasswordAuthentication
             是否允许使用基于密码的认证。默认为"yes"。

     PermitEmptyPasswords
             是否允许密码为空的用户远程登录。默认为"no"。

     PermitOpen
             指定TCP端口转发允许的目的地，可以使用空格分隔多个转发目标。默认允许所有转发请求。
             合法的指令格式如下：
                   PermitOpen host:port
                   PermitOpen IPv4_addr:port
                   PermitOpen [IPv6_addr]:port
             "any"可以用于移除所有限制并允许一切转发请求。

     PermitRootLogin
             是否允许 root 登录。可用值如下：
             "yes"(默认) 表示允许。"no"表示禁止。
             "without-password"表示禁止使用密码认证登录。
             "forced-commands-only"表示只有在指定了 command 选项的情况下才允许使用公钥认证登录。
                                   同时其它认证方法全部被禁止。这个值常用于做远程备份之类的事情。

     PermitTunnel
             是否允许 tun(4) 设备转发。可用值如下：
             "yes", "point-to-point"(layer 3), "ethernet"(layer 2), "no"(默认)。
             "yes"同时蕴含着"point-to-point"和"ethernet"。

     PermitUserEnvironment
             指定是否允许 sshd(8) 处理 ~/.ssh/environment 以及 ~/.ssh/authorized_keys 中的 environment= 选项。
             默认值是"no"。如果设为"yes"可能会导致用户有机会使用某些机制(比如 LD_PRELOAD)绕过访问控制，造成安全漏洞。

     PidFile
             指定在哪个文件中存放SSH守护进程的进程号，默认为 /var/run/sshd.pid 文件。

     Port
             指定 sshd(8) 守护进程监听的端口号，默认为 22 。可以使用多条指令监听多个端口。
             默认将在本机的所有网络接口上监听，但是可以通过 ListenAddress 指定只在某个特定的接口上监听。

     PrintLastLog
             指定 sshd(8) 是否在每一次交互式登录时打印最后一位用户的登录时间。默认值是"yes"。

     PrintMotd
             指定 sshd(8) 是否在每一次交互式登录时打印 /etc/motd 文件的内容。默认值是"yes"。

     Protocol
             指定 sshd(8) 支持的SSH协议的版本号。
             '1'和'2'表示仅仅支持SSH-1和SSH-2协议。"2,1"表示同时支持SSH-1和SSH-2协议。

     PubkeyAuthentication
             是否允许公钥认证。仅可以用于SSH-2。默认值为"yes"。

     RhostsRSAAuthentication
             是否使用强可信主机认证(通过检查远程主机名和关联的用户名进行认证)。仅用于SSH-1。
             这是通过在RSA认证成功后再检查 ~/.rhosts 或 /etc/hosts.equiv 进行认证的。
             出于安全考虑，建议使用默认值"no"。

     RSAAuthentication
             是否允许使用纯 RSA 公钥认证。仅用于SSH-1。默认值是"yes"。

     ServerKeyBits
             指定临时服务器密钥的长度。仅用于SSH-1。默认值是 768(位)。最小值是 512 。

     StrictModes
             指定是否要求 sshd(8) 在接受连接请求前对用户主目录和相关的配置文件进行宿主和权限检查。
             强烈建议使用默认值"yes"来预防可能出现的低级错误。

     Subsystem
             配置一个外部子系统(例如，一个文件传输守护进程)。仅用于SSH-2协议。
             值是一个子系统的名字和对应的命令行(含选项和参数)。比如"sft /bin/sftp-server"。

     SyslogFacility
             指定 sshd(8) 将日志消息通过哪个日志子系统(facility)发送。有效值是：
             DAEMON, USER, AUTH(默认), LOCAL0, LOCAL1, LOCAL2, LOCAL3, LOCAL4, LOCAL5, LOCAL6, LOCAL7

     TCPKeepAlive
             指定系统是否向客户端发送 TCP keepalive 消息。默认值是"yes"。
             这种消息可以检测到死连接、连接不当关闭、客户端崩溃等异常。
             可以设为"no"关闭这个特性。

     UseDNS
             指定 sshd(8) 是否应该对远程主机名进行反向解析，以检查此主机名是否与其IP地址真实对应。默认值为"yes"。

     UseLogin
             是否在交互式会话的登录过程中使用 login(1) 。默认值是"no"。
             如果开启此指令，那么 X11Forwarding 将会被禁止，因为 login(1) 不知道如何处理 xauth(1) cookies 。
             需要注意的是，login(1) 是禁止用于远程执行命令的。
             如果指定了 UsePrivilegeSeparation ，那么它将在认证完成后被禁用。

     UsePrivilegeSeparation
             是否让 sshd(8) 通过创建非特权子进程处理接入请求的方法来进行权限分离。默认值是"yes"。
             认证成功后，将以该认证用户的身份创建另一个子进程。
             这样做的目的是为了防止通过有缺陷的子进程提升权限，从而使系统更加安全。

     X11DisplayOffset
             指定 sshd(8) X11 转发的第一个可用的显示区(display)数字。默认值是 10 。
             这个可以用于防止 sshd 占用了真实的 X11 服务器显示区，从而发生混淆。

     X11Forwarding
             是否允许进行 X11 转发。默认值是"no"，设为"yes"表示允许。
             如果允许X11转发并且sshd(8)代理的显示区被配置为在含有通配符的地址(X11UseLocalhost)上监听。
             那么将可能有额外的信息被泄漏。由于使用X11转发的可能带来的风险，此指令默认值为"no"。
             需要注意的是，禁止X11转发并不能禁止用户转发X11通信，因为用户可以安装他们自己的转发器。
             如果启用了 UseLogin ，那么X11转发将被自动禁止。

     X11UseLocalhost
             sshd(8) 是否应当将X11转发服务器绑定到本地loopback地址。默认值是"yes"。
             sshd 默认将转发服务器绑定到本地loopback地址并将 DISPLAY 环境变量的主机名部分设为"localhost"。
             这可以防止远程主机连接到 proxy display 。不过某些老旧的X11客户端不能在此配置下正常工作。
             为了兼容这些老旧的X11客户端，你可以设为"no"。

     XAuthLocation
             指定 xauth(1) 程序的绝对路径。默认值是 /usr/X11R6/bin/xauth

    ChallengeResponseAuthentication
             挑战任何的密码认证！所有，任何Login.conf规定的认证方式，均可使用。
