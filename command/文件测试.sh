文件测试
	存在性测试
		-a FILE
		-e FILE：文件存在性测试，存在为真，否则为假；
	存在性及类别测试
		-b FILE：是否存在且为块设备文件；
		-c FILE：是否存在且为字符设备文件；
		-d FILE：是否存在且为目录文件；
		-f FILE：是否存在且为普通文件；
		-h FILE 或 -L FILE：存在且为符号链接文件；
		-p FILE：是否存在且为命名管道文件；
		-S FILE：是否存在且为套接字文件；
	文件权限测试：
		-r FILE：是否存在且可读；
		-w FILE：是否存在且可写；
		-x FILE：是否存在且可执行；
	文件特殊权限测试：
		-g FILE：是否存在且拥有sgid权限；
		-u FILE：是否存在且拥有suid权限；
		-k FILE：是否存在且拥有sticky权限；
	文件大小测试：
		-s FILE：是否存在非空；
	文件是否打开：
		-t fd：fd表示文件描述符是否已经打开且与某终端相关

		-N FILE：文件自动上一次被读取之后是否被修改过；
		-O FILE：当前有效用户是否为文件属主；
		-G FILE：当前有效用户是否为文件属组；

	双目测试：
		FILE1 -ef FILE2：FILE1与FILE2是否指向同一个设备上的相同inode;
		FILE1 -nt FILE2: FILE1是否新于FILE2；
		FILE1 -ot FILE2：FILE1是否旧于FILE2；

组合测试条件
	逻辑运算：
		第一种方式：
		COMMAND1 && COMMAND2
		COMMAND1 || COMMAND2
		! COMMAND

		[ -e FILE ] && [ -r FILE ]
		第二种方式：
		EXPRESSION1 -a EXPRESSION2
		EXPRESSION1 -o EXPRESSION2
		! EXPRESSION

		