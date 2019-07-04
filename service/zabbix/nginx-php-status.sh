nginx status 状态及其说明
	编译nginx时需要加上--with-http_stub_status_module参数即可在安装时编译出HttpStubStatusModule模块
	安装完成后，可以通过stub_status on开启状态查看项。如果想设置的安全，可以增加上IP控制和密码认证，配置如下
		location /nginx-status {
			stub_status on;
			auth_basic "NginxStatus"；
			allow 127.0.0.1/32;
			allow 123.57.12.123/32;
			deny all;
			access_log off;
			auth_basic_user_file /etc/nginx/conf/htpasswd;
		}
		住：密码文件生成需要依赖apache的htpasswd工具生成。
		

	配置完成，在浏览器访问http://127.0.0.1/nginx-status输入用户名密码可看到nginx状态
		Active connections:75
		server accepts handled requests
		1702064 1702064 2683321
		Reading:1 Writing:4 Waiting:70
	各个参数的具体含义：
	Active connetions：当前Nginx正处理的活动连接数，包括处于等待状态的连接数（对后端发起的活动连接数）。
	server accepts handled requests--总共处理了1702064个连接，成功创建了1702064个握手（证明中间没有失败的），总共处理了2683321个请求（平均每次握手处理了2683321/1702064=1.57个数据请求）。
	reading：nginx读取到客户端的Header信息数。
	writing：当前nginx正在将响应写到客户端的连接数量
	waiting--开启keep-alive的情况下，这个值等于active-(reading+writing),意思就是nginx已经处理完正在等候下一次请求指令的驻留连接

php-fpm状态详解
	1、启动php-fpm状态功能
	# cat /usr/local/php/etc/php-fpm.conf |grep status_path
	pm.status_path = /status
	默认情况下为/status，当然也可以改成其他的
	2、nginx配置
	在默认主机里面加上location或者你希望能访问到得主机里面
	server{
		listen *:80 default_server;
		server_name _;
		location ~ ^/(status|ping)$
		{
			include fastcgi_params;
			fastcgi_pass 127.0.0.1:9000;
			fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
		}
	}
	或者在location里面直接定义
	location /php-fpm_status {
			include fastcgi_params;
			fastcgi_pass 127.0.0.1:9000;
			fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
			access_log off;
			allow 127.0.0.1/32;
			allow 123.57.12.123/32;
			deny all;
		}
	3、重启nginx/php-fpm
	# service nginx restart
	# service php-fpm restart
	4、打开status页面
	# curl http://localhost/php-fpm_status
	pool:                 www         	#fpm池子名称，大多数为www
	process manager:      dynamic	  	#进程的管理方式
	start time:           13/Dec/2016:13:46:33 +0800  #启动时间，如果reload了php-fpm，时间会更新
	start since:          15	      	#运行时长
	accepted conn:        4				#当前池子接受的请求数
	listen queue:         0				#请求等待队列，如果这个值不为0，那么要增加FPM的进程数量
	max listen queue:     0				#请求等待队列最高的数量
	listen queue len:     128 			#socket等待队列长度
	idle processes:       4 			#空闲进程数量
	active processes:     1				#活跃进程数量
	total processes:      5				#总进程数量
	max active processes: 1				#最大的活跃进程数量（FPM启动开始算）
	max children reached: 0				#进程最大数量限制的次数，如果这个数量不为0，那么说明你的最大进程数量太小，需要改大一点。
	slow requests:        0				#启用了php-fpm slow-log，缓慢请求的数量
