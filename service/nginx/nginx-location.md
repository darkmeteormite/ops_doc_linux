nginx-location

	语法规则: location [=|~|~*|^~] /uri/ { ... }
		= 表示精确匹配,这个优先级也是最高的
		^~ 表示 uri 以某个常规字符串开头，理解为匹配 url 路径即可。nginx 不对 url 做编码，因此请求为 /static/20%/aa，可以被规则^~ /static/ /aa 匹配到(注意是空格)。
		~ 表示区分大小写的正则匹配
		~* 表示不区分大小写的正则匹配(和上面的唯一区别就是大小写) !~和!~*分别为区分大小写不匹配及不区分大小写不匹配的正则
		/ 通用匹配，任何请求都会匹配到，默认匹配.
		下面讲讲这些语法的一些规则和优先级
		
	多个 location 配置的情况下匹配顺序为:
		优先级=>^~>
		首先匹配 =，其次匹配^~, 其次是按文件中顺序的正则匹配，最后是交给 / 通用匹配。当有匹配成功时候，停止 匹配，按当前匹配规则处理请求。
		例子，有如下匹配规则:
		location / {
		echo "/"; //需要安装 echo 模块才行,这边大家可以改成各自的规则
		}
		location = / {
		echo "=/"; }
		location = /nginx {
		   echo "=/nginx";
		}
		location ~ \.(gif|jpg|png|js|css)$ {
		echo "small-gif/jpg/png"; }
		location ~* \.png$ {
		   echo "all-png";
		}
		location ^~ /static/ {
		   echo "static";
		}
	匹配静态文件

		location ~* .*\.(js|css)?$ {
			expires 7d; 		#7天过期
			access_log off;   	#不保存日志
		}

		location ~* .*\.(zip|rar|exe|msi|iso|gho|mp3|rmvb|mp4|wma|wmv|rm)?$ {
			deny all;    #禁止这些文件下载
		}


隐藏版本号
	1、在nginx.conf中的http段中加上server_tokens off;
	2、在fastcgi.conf中
		找到：
		fastcgi_param SERVER_SOFTWARE nginx/$nginx_version;
		改为：
		fastcgi_param SERVER_SOFTWARE nginx;
	3、关闭php错误日志(php.ini)
		display_errors = off
	4、关闭Php信息 (php.ini)
		expose_php = Off  #不轻易透露自己 php 版本信息，防止黑客针对这个版本的 php 发动攻击.

CPU配置段
	user www-data;
	worker_processes 8;
	worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;
	worker_rlimit_nofile 60000;

nginx编译参数详解
		
	./configure \
    --user=nobody \
    --group=nobody \
    --prefix=/usr/local/nginx \   #指定nginx安装目录
    --conf-path=/data/conf/nginx/nginx.conf \    #指定配置文件路径
    --with-http_stub_status_module \		#启用Server status页
    --with-http_ssl_module \                  #声明启用HTTP的ssl模块
    --add-module=../nginx-push-stream-module-master \    #使用http技术来实现连接管道，在项目里主要用于即时消息的推送，比如聊天功能
    --with-pcre \ 			#重写功能
    --with-pcre-jit \		#使用“即时编译”支持构建PCRE库
    --with-http_gzip_static_module \	#允许使用gzip压缩发送数据
    --add-module=../ngx_http_secure_download-master \
    --with-debug \      #声明启用nginx的调试日志


nginx配置多证书支持
	
	#vim /etc/nginx/nginx.conf

	server {
		server_name www.bjwf125.com;
		listen  443 ssl;

		index index.html index.htm index.php;
		root /data/web/bjwf125;

		ssl on;
		ssl_certificate bjwf125.crt;
		ssl_certificate_key bjwf125.key;
	}

	server {
		server_name www.bjwf.com;
		listen  443;

		index index.html index.htm index.php;
		root /data/web/bjwf;
		
		ssl on;
		ssl_certificate bjwf.crt;
		ssl_certificate_key bjwf.key;
	}






