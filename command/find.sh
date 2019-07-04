find
	实时查找工具，通过遍历指定路径下的文件系统完成文件查找；
	工作特点：
		查找速度略慢、
		精确查找
		实时查找
	语法：
		find [OPTION]...[查找路径] [查找条件] [处理动作]
			查找路径：指定具体目录路径；默认为当前路径；
			查找条件：指定的查找标准，可以是文件名、大小、类型、权限等标准进行。默认为指定路径下的所有文件；
			处理动作：对符合条件的文件做什么操作；默认输出到屏幕；

			查找条件：
				根据文件名查找：
					-name "文件名称"：支持使用glob（通配符）；
						  *:任意长度任意字符
					      ?:任意单个字符
					      []:范围内任意字符
					      [^]:范围外任意字符
					-iname "文件名称"：不区分字母大小写；
					-regex "PATIERN"：支持使用正则表达式，以PATIERN匹配整个文件路径字符串，而不仅仅是文件名称
				
				根据属主、属组查找：
					-user USERNAME：查找属主为指定用户的文件
					-group GROUPNAME：查找属组为指定组的文件
					
					-uid UserID：查找属主为指定UID的文件
					-git GroupID：查找属组为指定GID的文件

					-nouser：查找没有属主的文件；
					-nogroup：查找没有属组的文件；
				
				根据文件类型查找：
					-type TYPE：根据文件类型查找
					      f:普通文件
					      d:目录文件
					      l:符号链接
					      b:块设备
					      c:字符设备
					      s:套接字文件
					      p:命名管道
					-size [+|-]#UNIT：根据文件大小查找
					      常用单位：k,M,G
					      #UNIT：#-1<x<=#
					      -#UNIT:x<=#-1
					      +#UNIT:x>#
					      (x为匹配到的文件大小)

				组合条件：
					-a:与，同时满足
					-o：或，满足一个即可
					-not：！非，条件取反

					找出/tmp目录下，属主不是root,且文件名不是fstab的文件
					# find /tmp \( -not -user root -a -not -name 'fstab' \) -ls
					# find /tmp -not \( -user root -o -name 'fstab' \) -ls

				时间戳查找：
					以“天”为单位
					-atime(访问时间) [+|-]#
					       +#:x>=#+1
					       -#:x<#
					       #:#<=x<#+1
					       (x为匹配到的文件时间) 
					-mtime(修改时间)
					-ctime(改变时间)
					以“分钟”为单位
					-atime
					-mtime
					-ctime
					(用法同上)

				权限查找
				    -perm [+|-]MODE
					    MODE:与MODE精确匹配
					    +MODE: 任何一类用户的权限只要能包含对其指定的任何一位权限即可
					    -MODE：每类用户指定的检查权限都匹配

				处理动作：
					-print: 默认处理动作，显示
					-ls：类似于ls -l
					-fls /path/to/somefile：查找到的所有文件的长格式信息保存至指定文件中；
					-delete: 删除查找到的文件；
					-exec COMMAND {} \;
					-ok COMMAND {} \;   #find一次性查找符合条件的所有文件，并一同传递
					给-exec或-ok后面指定的命令，但有些命令不能接受过长的参数，此时使用另一种方式：
					find | xargs COMMAND

				*注意：find传递查找到的文件至后面指定的命令时，查找到的所有符合条件的文件一次性传递给后面的命令；	
	find实战
		1、查找/etc/init.d/目录中包含e并已s结尾的文件并复制到/tmp下
		[root@mail ~]# ls /etc/init.d/
		auditd     ip6tables  mdmonitor   network      ntpdate      rsyslog    sshd
		crond      iptables   messagebus  nginx        postfix      sandbox    svnserve
		functions  kdump      netconsole  nginx-debug  rdisc        saslauthd  udev-post
		halt       killall    netfs       ntpd         restorecond  single
		[root@mail ~]# find /etc/init.d/ -name "*e*s" -exec cp {} /tmp \;
		[root@mail ~]# ls /tmp
		ip6tables  iptables  messagebus  netfs  
		 
		2、查找/var/目录属主为root且属组为mail的所以文件
		[root@mail ~]# find /var/ -user root -group mail
		/var/spool/mail
		/var/spool/mail/root
		 
		3、查找/usr/目录下不属于root、bin或bjwf的所有文件
		[root@mail ~]# find /usr/ -not \( -user root -o -user bin -o -user bjwf \)
		/usr/local/nginx
		/usr/local/nginx/sbin
		/usr/local/nginx/sbin/nginx
		 
		4、查找/tmp目录下最近7天内修改过且不属于root和bjwf的文件并显示属性信息
		[root@mail ~]# find /tmp -mtime -7 -not \( -user root -o -user bjwf \) -ls
		262152    0 -rw-r--r--   1 nginx    nginx           0 5月 23 14:58 /tmp/sum.sh
		 
		5、查找当前系统上没有属主或属组，且最近1个月内曾被访问过的文件
		[root@mail ~]# find / \( -nouser -o -nogroup \) -a -atime -30
		 
		6、查找/etc/目录下大于1M且类型为普通文件的所有文件
		[root@mail ~]# find /etc/ -type f -size +1M
		/etc/pki/tls/certs/ca-bundle.trust.crt
		/etc/selinux/targeted/modules/active/policy.kern
		/etc/selinux/targeted/policy/policy.24
		 
		7、查找/etc/目录所有用户都没有写权限的文件
		[root@mail ~]# find /etc/ -not -perm +222
		/etc/openldap/certs/password
		/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
		/etc/pki/ca-trust/extracted/java/cacerts
		/etc/pki/ca-trust/extracted/pem/email-ca-bundle.pem
		/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
		/etc/pki/ca-trust/extracted/pem/objsign-ca-bundle.pem
		/etc/ld.so.conf.d/kernel-2.6.32-573.el6.x86_64.conf
		/etc/shadow
		/etc/gshadow
		/etc/shadow-
		/etc/sudoers
		 
		8、查找/etc/目录下至少有一类用户没有写权限
		[root@mail ~]# find /etc/ -not -perm -222 > /tmp/perm
		[root@mail ~]# wc -l /tmp/perm   #文件太多，所以追加到/tmp/perm下
		1019 /tmp/perm   
		 
		9、查找/etc/rc.d/目录下，所有用户都有执行权限且其它用户有写权限的文件
		[root@mail ~]# find /etc/rc.d -perm -113 > /tmp/perm.113 
		[root@mail ~]# wc -l /tmp/perm.113
		163 /tmp/perm.113
		 
		10、在/apps/audit目录下查找所有用户具有读、写和执行权限的文件，并收回相应的写权限
		# find /apps/audit -perm -7 -print | xargs chmod o-w