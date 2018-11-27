Cobbler自动部署主机系统
```
Cobbler由python语言开发，是对PXE和 Kickstart以及DHCP的封装。
融合很多特性，提供了CLI和Web的管理形式。更加方便的实行网络安装。
同时，Cobbler也提供了API接口，使用其它语言也很容易做扩展。
它不仅可以安装物理机，同时也支持kvm、xen虚拟化、Guest OS的安装。
更多的是它还能结合Puppet等集中化管理软件，实现自动化的管理。
PXE 预启动执行环境（Preboot eXecution Environment，PXE，也被称为预执行环境)是让计算机通过网卡独立地使用数据设备(如硬盘)或者安装操作系统。
Cobbler提供以下服务集成：
* PXE服务支持
* DHCP服务管理
* DNS服务管理
* 电源管理
* Kickstart服务支持
* yum仓库管理
```
```
1.安装cobbler
 #rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-X-Y.noarch.rpm
 rpm -Uvh wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
 yum -y install httpd rsync tftp-server xinetd dhcp python-ctypes cman pykickstart syslinux
 yum -y install cobbler* debmirror*

 2.cobbler命令说明
 cobbler check：检查cobbler配置
 cobbler list：列出所有的cobbler元素
 cobbler report：列出元素的详细信息
 cobbler distro:查看导入的发行版系统信息
 cobbler system：查看添加的系统信息
 cobbler profile：查看配置信息
 cobbler sync：同步cobbler配置
 cobbler reposync：同步yum仓库

 3.cobbler配置文件说明：
 /etc/cobbler/seetings cobbler的主配置文件
 /etc/cobbler/users.digest 用于web访问的用户名密码配置文件
 /etc/cobbler/modules.conf 模块配置文件
 /etc/cobbler/users.conf cobbler webui/web服务授权配置文件
 /etc/cobbler/iso/ buildiso模板配置文件
 /etc/cobbler/power 电源配置文件
 /etc/cobbler/pxe pxeprofile配置模板
 /etc/cobbler 此目录包含rsync,dhcp,dns,pxe,等服务的模板配置文件

 4.系统镜像数据目录/var/www/cobbler
 导入的系统发行版，repos镜像和kickstart文件都放置在/var/www/cobbler目录下
 /var/www/cobbler/images存储所有导入发行版的kernel和initrd镜像用于远程网络启动
 /var/www/cobbler/ks_mirror存储导入的发行版系统数据
 /var/www/cobbler/repo_mirror 仓库存储目录
 /var/log/cobbler cobbler日志文件

 5.cobbler数据目录/var/lib/cobbler
 /var/lib/cobbler/config/存放distros，repos，systems，和profile等信息配置文件，一般是json文件
 /var/lib/cobbler/snippets存放ks文件可以导入的脚本小片段
 /var/lib/cobbler/triggers存放用户定义的cobbler命令
 /var/lib/cobbler/kickstarts/存放kictstart配置文件

 6.配置cobbler
 vim /etc/cobbler/setting 
242 manage_dhcp: 1           ##启用cobbler管理DHCP功能 
261 manage_rsync: 1          ##启用cobbler管理rsync功能 
246 manage_dns: 0            ##启用cobbler管理dns,这里没有开启 
272 next_server: 192.168.10.128    ##DHCP服务地址 
292 pxe_just_once: 1          ##预防将机器中的安装循环配置为始终从网络引导 
384 server: 192.168.10.128      ##cobbler服务器地址 


7.配置tftp，rsync
 vim /etc/xinetd.d/tftp 
  disable = no
 vim //rsync
  disable = noetc/xinetd.d


8.启用wsgi模块：python应用程序或框架和web服务器之间的一种接口
  cat  /etc/httpd/conf.d/wsgi.conf  
LoadModule wsgi_module modules/mod_wsgi.so 


9.生成cobbler安装系统root的初始密码  #  这里生成密钥和配置默认密钥，后面ks文件引用
openssl passwd -1 -salt 'random-phrase-here' 'password'  
$1$random-p$sFftrCTxKKsDZ.Sdr8mDG0 
vim /etc/cobbler/settings +101 
101 default_password_crypted: "$1$random-p$sFftrCTxKKsDZ.Sdr8mDG0" 


10.配置DHCP
vim /etc/cobbler/dhcp.template      
 subnet 192.168.32.0 netmask 255.255.255.0 {        # 分配所属网段 
     option routers             192.168.32.1;      # 默认网关 
      option domain-name-servers 192.168.32.200;      #dns ip 
      option subnet-mask         255.255.255.0;     #掩码 
      range dynamic-bootp        192.168.32.:x200 192.168.32.254;   # 分配地址段 
        filename                   "/pxelinux.0";   ##指定的网络引导程序 
      default-lease-time         21600;             #租约时间，秒 
       max-lease-time             43200;             #最大租约时间，秒 
       next-server                192.168.32.200;   #指定的TFTP服务器的地址 


11。编辑dhcp配置文件，不然可能无法启动dhcp
vim /etc/dhcp/dhcpd.conf
ddns-update-style interim; 
allow booting; 
allow bootp; 
ignore client-updates; 
set vendorclass = option vendor-class-identifier; 
option pxe-system-type code 93 = unsigned integer 16; 
subnet 192.168.32.0 netmask 255.255.255.0{
     option routers             192.168.30.200;
     option domain-name-servers :x192.168.30.200;
     option subnet-mask         255.255.255.0; 
     range dynamic-bootp        192.168.30.200 192.168.32.254;
     filename            "/pxelinux.0"; 
     default-lease-time         21600; 
     max-lease-time             43200; 
     next-server                192.168.30.200;
     } 
启动服务：
/etc/init.d/xinetd start 
/etc/init.d/dhcpd start 
/etc/init.d/cobblerd start 
/etc/init.d/httpd restart 


12.管理cobbler
cobbler get-loaders


13.编辑debmiror
vim /etc/debmirror.conf
28 #@dists="sid"; 
30 #@arches="i386"; 


14.检查cobbler配置
cobbler check

15.运行cobbler sync命令使配置生效

16.挂载镜像
mount /dev/sr0 /media

17.导入安装文件
cobbler import --path=/mnt/ --name=centos6.5x86_64 导出的文件在/var/www/下
cobbler import --name=centos-6.5-x86_64-minimal --arch=x86_64 --path=/mnt/

18.列出导入后的配置
cobbler list  列出详细信息可以使用cobbler report 
查看配置是否存在
cobbler profile find --distro=centos6.5X86_64-x86_64

19.定义ks文件
cd /var/lib/cobbler/kickstarts 
cp sample.ks centos6.5X86_64-x86_64.cfg
cobbler profile edit --name=centos6.5X86_64-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos6.5x86_64.cfg
查看系统列表
cobbler distro list 

20.同步Cobbler配置 ##建议先执行cobbler check进行配置检查再执行cobbler sync，修改cobbler配置后都需要执行此步骤

21.现在就可以装机了

22.现在用web界面管理cobbler服务
在浏览器输入：https://192.168.32.200/cobber_web

23.此时，编辑/etc/cobbler/module.conf，其中有一行：
module = authn_denyall   ，将这行改为module=authn_configfile,也可以改为authn_pam（这是基于系统用户进行认证）
我现在将其改为module=authn_pam
添加用户，并设置密码：useradd cobbleruser    echo "redhat" | passwd --stdin cobbleruser
然后编辑/etc/cobbler/user.conf，找到admin=""，改为：admin="cobbleruser" // 这是我刚刚添加的用户
重启cobbler服务，登录web界面
```
