centos7搭建openvpn

1、github项目地址

https://github.com/Chocobozzz/OpenVPN-Admin 

2、环境准备

# LNMP环境使用伙伴文档搭建 
 
系统版本：      CentOS release 7.6 (Final) 
内核版本：       3.10.0
Nginx版本：     nginx/1.12.0                 
PHP版本：       7.0.6 
MySQL版本：     5.6 
OpenVPN版本：   2.4.7 
Nodejs版本：    v6.14.3 
npm版本：       3.10.10 
 
# yum -y install openvpn nodejs npm 
# npm install -g bower

3、安装

# mkdir /data/web && chown -R nobody.nobody /data/web
# mkdir /root/software 
# cd /root/software 
# git clone https://github.com/Chocobozzz/OpenVPN-Admin openvpn-admin 
# cd openvpn-admin/ 
# ./install.sh /data/web nobody nobody 
# 会让你输入你的openvpn的端口、协议、域名；CA证书的国家、城市、组织等 

4、Nginx配置

# vim /data/conf/nginx/vhosts/vpn.huoban.com.conf 
server { 
    listen 80; 
    server_name vpn.huoban.com; 
 
 
       location / { 
        root         /data/web/openvpn-admin; 
        index index.php index.html index.htm; 
        } 
 
        location ~ \.php$ { 
 
                fastcgi_pass 127.0.0.1:9000; 
 
                fastcgi_index index.php; 
                fastcgi_param SCRIPT_FILENAME  /data/web/openvpn-admin$fastcgi_script_name; 
                include fastcgi_params; 
 
        } 
 
 
    access_log /data/logs/nginx/vpn.huoban.com_access.log combined; 
    error_log  /data/logs/nginx/vpn.huoban.com_error.log; 
} 
5、运行环境配置

# 修改PHP连接参数 
# vim /data/web/openvpn-admin/include/config.php 
<?php 
        $host = '127.0.0.1'; 
        $port = '3306'; 
        $db   = 'openvpn-admin'; 
        $user = 'openvpn'; 
        $pass = 'huoban.com'; 
?> 
 
 
# vim /etc/openvpn/scripts/config.sh 
#!/bin/bash 
# MySQL credentials 
HOST='127.0.0.1' 
PORT='3306' 
USER='openvpn' 
PASS='huoban.com' 
DB='openvpn-admin' 
 
 
# MySQL授权 
# mysql 
mysql> grant all on `openvpn-admin`.* to openvpn@'127.0.0.1' identified by "huoban.com"; 
mysql> flush privileges; 
 
 
# 修改web脚本，把/etc/openvpn/scripts下所有涉及php和mysql命令的脚本都改为绝对路径 
# egrep  "php|mysql" ./* 
./connect.sh:/usr/local/mysql/bin/mysql -h$HOST -P$PORT -u$USER -p$PASS $DB -e "INSERT INTO log (log_id, user_id, log_trusted_ip, log_trusted_port, log_remote_ip, log_remote_port, log_start_time, log_end_time, log_received, log_send) VALUES(NULL, '$common_name','$trusted_ip', '$trusted_port','$ifconfig_pool_remote_ip', '$remote_port_1', now(),NULL, '$bytes_received', '$bytes_sent')" 
./connect.sh:/usr/local/mysql/bin/mysql -h$HOST -P$PORT -u$USER -p$PASS $DB -e "UPDATE user SET user_online=1 WHERE user_id='$common_name'" 
./disconnect.sh:/usr/local/mysql/bin/mysql -h$HOST -P$PORT -u$USER -p$PASS $DB -e "UPDATE user SET user_online=0 WHERE user_id='$common_name'" 
./disconnect.sh:/usr/local/mysql/bin/mysql -h$HOST -P$PORT -u$USER -p$PASS $DB -e "UPDATE log SET log_end_time=now(), log_received='$bytes_received', log_send='$bytes_sent' WHERE log_trusted_ip='$trusted_ip' AND log_trusted_port='$trusted_port' AND user_id='$common_name' AND log_end_time IS NULL" 
./login.sh:user_pass=$(/usr/local/mysql/bin/mysql -h$HOST -P$PORT -u$USER -p$PASS $DB -sN -e "SELECT user_pass FROM user WHERE user_id = '$username' AND user_enable=1 AND (TO_DAYS(now()) >= TO_DAYS(user_start_date) OR user_start_date IS NULL) AND (TO_DAYS(now()) <= TO_DAYS(user_end_date) OR user_end_date IS NULL)") 
./login.sh:result=$(/usr/local/php7/bin/php -r "if(password_verify('$password', '$user_pass') == true) { echo 'ok'; } else { echo 'ko'; }") 
 
 
# 访问页面进行初始化 
http://host/index.php?installation 

6、OpenVPN配置

# egrep -v "^#|^;|^$" /etc/openvpn/server.conf 
mode server 
proto tcp               协议 
port 443                端口 
dev tun                 模式 
ca ca.crt               证书 
cert server.crt         证书 
key server.key          证书 
dh dh.pem                
tls-auth ta.key 0 
cipher AES-256-CBC 
server 172.16.0.0 255.255.255.0            客户端分发地址 
push "redirect-gateway"                     客户端所有流量走vpn 
push "route 10.0.0.0 255.0.0.0"
push "route 192.168.0.0 255.255.0.0"
push "dhcp-option DNS 114.114.114.114"
keepalive 10 120                 
reneg-sec 18000 
user nobody 
group nobody 
persist-key 
persist-tun 
comp-lzo 
verb 4 
mute 20 
status openvpn-status.log 
log-append /var/log/openvpn.log 
client-config-dir ccd 
script-security 3 
username-as-common-name 
verify-client-cert none 
auth-user-pass-verify scripts/login.sh via-env 
max-clients 50 
client-connect scripts/connect.sh 
client-disconnect scripts/disconnect.sh 

# 启动服务
# systemctl -f enable openvpn@server.service
# systemctl start openvpn@server.service


7、设置iptables、route

# 设置包转发 
# iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -j MASQUERADE
# iptables-save > /etc/sysconfig/iptables
# 内核开启转发
# sysctl -w net.ipv4.ip_forward=1
# 修改配置文件使其永久生效
# vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
# sysctl -p    重读配置文件
 
8、登录网页，管理用户和客户端配置文件

用户名：admin 
密码：huoban.com 
和数据库授权一致
