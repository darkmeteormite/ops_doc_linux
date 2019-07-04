rsync命令是一个远程数据同步工具，可通过LAN/WAN快速同步多台主机间的文件。rsync使用所谓的“rsync算法”来使本地和远程两个主机之间的文件达到同步，这个算法只传送两个文件的不同部分，而不是每次都整份传送，因此速度相当快。 rsync是一个功能非常强大的工具，其命令也有很多功能特色选项.
	
语法：
	rsync [OPTION]... SRC DEST 
	rsync [OPTION]... SRC [USER@]host:DEST 
	rsync [OPTION]... [USER@]HOST:SRC DEST 
	rsync [OPTION]... [USER@]HOST::SRC DEST 
	rsync [OPTION]... SRC [USER@]HOST::DEST 
	rsync [OPTION]... rsync://[USER@]HOST[:PORT]/SRC [DEST]

对于以上六种命令格式，rsync有六种不同的工作模式：

1、拷贝本地文件，当SRC和DEST路径都不包含有单个冒号":"分隔符时就启动这种工作模式。
	如：rsync -a /data /backup

2、使用一个远程shell程序(如rsh、ssh)来实现将本地机器的内容拷贝到远程机器。当DEST地址路径包含单个冒号":"分隔符时启动该模式。
	如：rsync -avz *.c foo:src

3、使用一个远程shell程序(如rsh、ssh)来实现将远程机器的内容拷贝到本地机器。当SRC地址路径包含单个冒号":"分隔符时启动该模式。
	如：rsync -avz foo:src/bar /data

4、从远程rsync服务器中拷贝文件到本地机器。当SRC路径信息包含"::"分隔符启用该模式。
	如：rsync -av root@mail::www /data/web/www

5、从本地机器拷贝文件到远程rsync服务器中。当DST路径信息包含"::"分隔符启用该模式。
	如：rsync -av /data/web/www root@mail::www

6、列远程机的文件列表。这类似于rsync传输，不过只要在命令中省略掉本地机信息即可。
	如：rsync -v rsync://mail/www

工作模式：
1、shell模式，也称为本地模式
2、远程shell模式，可以利用ssh协议承载其远程传输过程
3、列表模式，仅列出源中的内容，-nv
4、服务模式，此时rsync工作为守护进程，能接收客户端的数据同步请求

选项：
	-n: 同步测试，不执行真正的同步过程；
	-v: 详细输出模式
	-q: 静默模式
	-c: checksum，开启校验功能
	-r: 递归复制
	-a: 归档，保留文件的原有属性；
	-p: 保留文件的权限；
	-t: 保留文件的时间戳；
	-l: 保留符号链接
	-g: 保留属组
	-o: 保留属主
	-D：保留设备文件
	-e ssh: 使用ssh作为传输承载；
	-z: 压缩后传输；
	--progress: 显示进度条
	--stats: 显示如何执行压缩和传输

注意：rsync命令中，如果源路径为目录，且给复制路径时末尾有/，则会复制目录中得内容，而非目录本身；如果末尾没有/，则会同步目录本身及目录中得所有文件。
	如:	rsync -r /var/log/ /tmp #复制/var/log目录下的所有文件，不包含log本身。
		rsync -r /var/log /tmp  #复制/var/log整个目录。






























































































































