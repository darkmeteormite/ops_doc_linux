一、NTP（Network Time Protocol）
在计算机世界中，NTP（Network Time Protocol，网络时间协议）被广泛用于对时间的统一性和准确性要求非常高的场景，是用来使网络中得各个计算机时间同步的一种协议。它可以把计算机时钟同步到世界协调时UTC（Universal Time Coordinated，世界协议时）。UTC是由原子钟报时的国际标准时间，而NTP获得UTC的时间来源可以是原子钟、天文台、卫星，也可从Internet上面获取。在NTP协议中，定义了时间按照服务器等级传播，依据离外部UTC源的远近，将所有服务器归入不同的stratum（层）中，直接从时间源如GPRS（Global Positioning System，全球定位系统）获取时间的服务器称之为stratum-1，而后依次序递归传播给下层服务器stratum-2、stratum-3...，层的总数限制在15以内。
二、Linux时间相关
2.1、时区
现实生活中时间以时区的方式定义，地球绕太阳旋转的24小时中，世界各地的不同时间由UTC+地区所属时区决定，全球划分为24个不同的时区。比如中国标准时间晚上8点半，可以有以下两种方式表示：
  20:00 CST(Chinese Standard Time,中国标准时间)
  12:00 UTC(Universal Time Coordinated,世界协调时)
2.2、Linux中设置时区
  Linux中得glibc已提供许多编译好的时区文件，存放于/usr/share/zoneinfo中，包含大多数国家和城市的时区
  
  [root@www ~]# ls /usr/share/zoneinfo/
  Africa      Atlantic   Chile    Eire     GB       GMT+0      Indian       Japan      MST      Pacific     PRC      Singapore  UTC
  America     Australia  CST6CDT  EST      GB-Eire  Greenwich  Iran         Kwajalein  MST7MDT  Poland      PST8PDT  Turkey     WET
  Antarctica  Brazil     Cuba     EST5EDT  GMT      Hongkong   iso3166.tab  Libya      Navajo   Portugal    right    UCT        W-SU
  Arctic      Canada     EET      Etc      GMT0     HST        Israel       MET        NZ       posix       ROC      Universal  zone.tab
  Asia        CET        Egypt    Europe   GMT-0    Iceland    Jamaica      Mexico     NZ-CHAT  posixrules  ROK      US         Zulu

  可以用zdump命令查询对应时区的当前时间，例如香港时间：
  
  [root@www Asia]# zdump Hongkong
  Hongkong  Sun Dec 25 10:43:43 2016 HKT

  修改Linux系统时区有多种方式，本文介绍两种：
  第一种方法，修改/etc/localtime文件，这个文件定义了当前系统所在local time zone,将/usr/share/zoneinfo中的time zone文件符号链接至该文件即可。

  查看当前时区时间
  [root@www Asia]# date
  2016年 12月 25日 星期日 10:47:43 CST
  修改时区为Shanghai   #我的时区默认就是上海，所以看不出变化
  [root@www Asia]# ln -sf /usr/share/zoneinfo/posix/Asia/Shanghai /etc/localtime
  [root@www Asia]# date  
  2016年 12月 25日 星期日 10:48:52 CST

  第二种方法，使用tzselect命令修改TZ变量的值，注意这种方法所做更改会覆盖localtime中得时区设定，如果要使更改长期有效，可以将TZ变量的设置写入到/etc/profile中。

  将时区更改为上海时区
  [root@www Asia]# tzselect
  Please identify a location so that time zone rules can be set correctly.
  Please select a continent or ocean.
   1) Africa
   2) Americas
   3) Antarctica
   4) Arctic Ocean
   5) Asia
   6) Atlantic Ocean
   7) Australia
   8) Europe
   9) Indian Ocean
  10) Pacific Ocean
  11) none - I want to specify the time zone using the Posix TZ format.
  #? Asia
  Please enter a number in range.
  #? 5
  Please select a country.
   1) Afghanistan     18) Israel        35) Palestine
   2) Armenia     19) Japan       36) Philippines
   3) Azerbaijan      20) Jordan        37) Qatar
   4) Bahrain     21) Kazakhstan      38) Russia
   5) Bangladesh      22) Korea (North)     39) Saudi Arabia
   6) Bhutan      23) Korea (South)     40) Singapore
   7) Brunei      24) Kuwait        41) Sri Lanka
   8) Cambodia      25) Kyrgyzstan      42) Syria
   9) China     26) Laos        43) Taiwan
  10) Cyprus      27) Lebanon       44) Tajikistan
  11) East Timor      28) Macau       45) Thailand
  12) Georgia     29) Malaysia        46) Turkmenistan
  13) Hong Kong     30) Mongolia        47) United Arab Emirates
  14) India     31) Myanmar (Burma)     48) Uzbekistan
  15) Indonesia     32) Nepal       49) Vietnam
  16) Iran      33) Oman        50) Yemen
  17) Iraq      34) Pakistan
  #? 9
  Please select one of the following time zone regions.
  1) Beijing Time
  2) Xinjiang Time
  #? 1

  The following information has been given:

    China
    Beijing Time

  Therefore TZ='Asia/Shanghai' will be used.
  Local time is now:  Sun Dec 25 10:58:17 CST 2016.
  Universal Time is now:  Sun Dec 25 02:58:17 UTC 2016.
  Is the above information OK?
  1) Yes
  2) No
  #? 1

  You can make this change permanent for yourself by appending the line
    TZ='Asia/Shanghai'; export TZ
  to the file '.profile' in your home directory; then log out and log in again.

  Here is that TZ value again, this time on standard output so that you
  can use the /usr/bin/tzselect command in shell scripts:
  Asia/Shanghai

2.3、时间设置
  Linux系统环境中，值得注意的是，一台计算机上我们有两个时钟：硬件时钟RTC（Real Time Clock）和系统时钟（system Clock）。硬件时钟是指镶嵌在主板上得特殊电路，它可以使计算机关机之后仍然计算时间；系统时钟是操作系统kernel用来计算时间的时钟，其值是由1970年1月1日00:00:00 UTC时间至当前时间所经历的秒数总和。系统在开机时，会自动将系统时间同步为硬件时钟时间，而后各自独立运行，长时间运行两者将会产生误差。
  
  查看并对比当前系统硬件时间和系统时间
  [root@www ~]# date;hwclock
  2016年 12月 25日 星期日 11:06:28 CST
  2016年12月25日 星期日 11时06分29秒  -0.874704 seconds
  两者暂时一样，没有误差
  hwclock -w:同步系统时钟到硬件时钟
  hwclock -s:同步硬件时钟到系统时钟

三、安装时间服务器
1、安装NTP，可以使用rpm包安装或者yum工具自动安装

[root@localhost ~]# yum -y install ntp ntpdate tzdata
ntp相关文件说明：
/etc/ntp.conf        ntp server配置文件
/usr/sbin/ntpd       ntp server程序
/usr/sbin/ntpdate    ntp client校正工具
/etc/sysconfig/clock 时区配置文件

2./etc/ntp.conf配置文件说明，主要配置restrict和server

  #restrict设置格式：
  #restrict ［授权同步的网段］ mask ［netmask］ ［parameter］
  例：restrict 192.168.1.0 mask 255.255.255.0 nomodify
   
  parameter说明：
  kod         kod技术可以阻止“Kiss of Death “包对服务器的破坏
  nomodity    client可通过ntp进行时间同步，但不能更改server参数
  notrap      不提供trap远程登陆功能
  nopeer      不与其它同一层的ntp server进行时间同步
  noquery     拒绝ntp时间同步
  notrust     拒绝无认证的client
  ignore      拒绝连接到ntp server
   
  ＃server设置格式
  ＃server ［hostname｜ip］［parameter］
  例：server   server asia.pool.ntp.org prefer
  parameter说明:
  prefer      最高优先级
  burst       当一个运程NTP服务器可用时，向它发送一系列的并发包进行检测。
  iburst      当一个运程NTP服务器不可用时，向它发送一系列的并发包进行检测。

3.ntp配置实例 server端

1)配置/etc/ntp.conf
[root@localhost ~]# vim /etc/ntp.conf
  1 # For more information about this file, see the man pages
  2 # ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).
  3 
  4 driftfile /var/lib/ntp/drift
  5 
  6 # Permit time synchronization with our time source, but do not
  7 # permit the source to query or modify the service on this system.
  8 restrict default kod nomodify notrap nopeer noquery
  9 restrict -6 default kod nomodify notrap nopeer noquery
 10 
 11 # Permit all access over the loopback interface.  This could
 12 # be tightened as well, but to do so would effect some of
 13 # the administrative functions.
 14 restrict 127.0.0.1
 15 restrict -6 ::1
 16 
 17 # Hosts on local network are less restricted.
 18 #restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap
 19 restrict 192.168.1.0 mask 255.255.250.0 nomodify
 20 
 21 # Use public servers from the pool.ntp.org project.
 22 # Please consider joining the pool (http://www.pool.ntp.org/join.html).
 23 #server 0.centos.pool.ntp.org iburst
 24 #server 1.centos.pool.ntp.org iburst
 25 #server 2.centos.pool.ntp.org iburst
 26 #server 3.centos.pool.ntp.org iburst
 27 server asia.pool.ntp.org prefer
 28 server 0.asia.pool.ntp.org
 29 server 1.asia.pool.ntp.org
 30 server 2.asia.pool.ntp.org
 31 server time.nist.gov
 32 
 33 #broadcast 192.168.1.255 autokey        # broadcast server
 ...
 
2)NTP启动与端口检查：
[root@localhost ~]# service ntpd start
Starting ntpd:
[root@localhost ~]# chkconfig ntpd on
[root@localhost ~]# chkconfig --list |  grep ntp
ntpd             0:关闭    1:关闭    2:启用    3:启用    4:启用    5:启用    6:关闭
ntpdate         0:关闭    1:关闭    2:关闭    3:关闭    4:关闭    5:关闭    6:关闭
[root@localhost ~]# netstat -nutlp | grep ntp
udp        0      0 192.168.1.213:123           0.0.0.0:*                               21798/ntpd          
udp        0      0 192.168.6.213:123           0.0.0.0:*                               21798/ntpd          
udp        0      0 127.0.0.1:123               0.0.0.0:*                               21798/ntpd          
udp        0      0 0.0.0.0:123                 0.0.0.0:*                               21798/ntpd          
udp        0      0 fe80::221:f6ff:fed4:d502:123 :::*                                    21798/ntpd          
udp        0      0 fe80::221:f6ff:fed4:d501:123 :::*                                    21798/ntpd          
udp        0      0 ::1:123                     :::*                                    21798/ntpd          
udp        0      0 :::123                      :::*                                    21798/ntpd  
 
3)ntp server与上联是否同步
#查看server与上联是否同步，时间校正约8279ms，每64s轮循更新一次。
[root@localhost ~]# ntpstat 
synchronised to NTP server (62.201.225.9) at stratum 3   ＃==>上层ntp
   time correct to within 8279 ms                        ＃==>校正时间差
   polling server every 64 s                             ＃==>下次同步时间
    
＃查看server与上联的状态
[root@localhost ~]# ntpq -ps
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*time.iqnet.com  62.201.214.162   2 u  146   64  124  393.411  -101.29  40.435
-220.231.122.105 123.204.45.116   4 u   20   64  377  341.475   58.745  47.945
+vps.jre655.com  10.84.87.146     2 u   24   64  377  211.095    0.177  38.002
 web10.hnshostin 158.43.128.33    2 u   17   64  177  392.506  -134.76  39.146
+24.56.178.140   .ACTS.           1 u   27   64  377  282.739  -59.521  42.959
 
参数说明：
reomte    server上联的ntp主机名或ip；
          注意最左端符号；＊表示当前正使用的上层ntp；＋代表与本机server也有连接，作为侯选ntp
refid     给上层ntp提供时间校对的服务器
st        上层npt stratum级别
when      上一次与上层ntp同步的时间，单位为秒。
poll      下一次与上层ntp同步的时间
reach     已经同上层ntp同步更新的次数
delay     网络传输过程中的延迟时间，单位为10^(-6)s
offset    时间补偿，单位为10^(-3)s
jitter    系统时间与bios硬件时间差，单位为10^(-6)s
4.ntp配置实例client端


通过crontab设置更新时间
[root@dns-2-253 ~]# crontab -l
*/5 * * * * /usr/sbin/ntpdate 192.168.1.213 &> /dev/null
 
client测试是否同步成功
[root@dns-2-253 ~]# ntpdate 192.168.1.213
10 Nov 21:25:43 ntpdate[26381]: step time server 192.168.6.213 offset 1.318393 sec
 
备注：如果无法同步，需查是否开启了防火墙。
 