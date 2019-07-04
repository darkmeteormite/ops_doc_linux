一、安装docker
1、检查安装环境
[root@mail ~]# uname -r
3.10.0-327.el7.x86_64
2、确保现有的包都是最新的
$ sudo yum update -y
3、增加yum源
$ sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[docker]
name=Docker repo
baseurl=http://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
国内yum源
[docker]
name=docker
baseurl=http://mirrors.aliyun.com/docker-engine/yum/repo/experimental/centos/7/
enable=1
gpgcheck=0
4、安装docker项目
$ sudo yum install docker-engine
5、添加到系统开机启动列表
$ sudo systemctl enable docker.service
6、后台启动docker
$ sudo systemctl start docker
7、docker加速器，使用国内镜像
# 如果使用centos7，修改/etc/systemd/system/multi-user.target.wants/docker.service文件中
	ExecStart=/usr/bin/dockerd --registry-mirror=https://jxus37ad.mirror.aliyuncs.com
*修改完成之后重启服务，可使用ps -ef|grep docker查看加速是否生效
	# ps -ef|grep docker
	root      7754     1  0 16:51 ?   00:00:07 /usr/bin/dockerd --registry-mirror=https://jxus37ad.mirror.aliyuncs.com
8、查看虚悬镜像（虚悬镜像可删除）
$ sudo docker images  -f dangling=true
$ sudo docker rmi $(docker images -q -f dangling=true)   #删除虚悬镜像

二、使用docker编译php
1、下载镜像
$ sudo  docker pull centos
2、运行
$ sudo  docker run -it --rm centos /bin/bash
	-it:这是两个参数
		-i：交互式操作
		-t：终端
	--rm：这个参数是说容器退出后随之将其删除
	当利用docker run来创建容器时，Docker在后台运行的标准操作包括
		检查本地是否存在指定的镜像，不存在就从公有仓库下载
		利用镜像创建并启动一个容器
		分配一个文件系统，并在只读的镜像层外面挂载一层可读写层
		从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中去
		从地址池配置一个ip地址给容器
		执行用户指定的应用程序
		执行完毕后容器被终止
3、查看docker运行过得镜像
$ docker ps -a  #运行过得所有镜像
$ docker ps     #正在运行的镜像
4、启动经过编辑的镜像
$ sudo docker start containerID
$ sudo docker attach containerID
5、查看镜像的详细信息
$ sudo docker inspect 7ffb44f148ef
6、删除镜像
$ sudo docker rmi  c2590ac4d8ea
			  -f  强制删除
7、创建镜像
$ sudo docker commit
				-a,--author=""作者信息。
				-m,--message=""提交消息。
				-p,--pause=true提交时暂停容器运行。
$ sudo  docker commit -m "make php5.5" -a "bjwf125" 7ffb44f148ef centos-php55  #根据ID创建一个编译了php55得centos镜像
sha256:0c274d9a43e8d75bbca2aefe4567e6bd1bfa1e0df9b2aa7cd1b12c34c69c18ed
$ sudo docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
centos-php55        latest              0c274d9a43e8        27 seconds ago      890.3 MB
8、上传镜像(到官方网站，需要先到官网镜像注册)
$ sudo docker tag centos-php55:latest user/centos-php55:lastst
$ sudo docker push user/centos/centos-php55:latest
Please login prior to push:
Username:
Password:
Email:xx@xx.com
第一次上传，需要登录用户信息

三、创建容器
1、根据已经存在镜像创建（新创建或者启动）
$ sudo docker create -it centos:latest
a2cbb52e01ae7f03799d0780071d96262966cc6a3a1bb5767114444b5d1db22b
# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                      PORTS               NAMES
a2cbb52e01ae        centos:latest       "/bin/bash"         25 seconds ago      Created                                         determined_kilby
使用docker create命令新建的容器处于停止状态，可以使用docker start命令来启动它
2、让容器后台运行
# 让docker在后台运行，可以通过添加-d参数来实现
$ sudo docker ps -a -q    #查看docker所有运行或停止容器的ID
3、exec命令
$ sudo docker exec -ti a2cbb52e01ae /bin/bash   #进入容器，并启动一个bash
4、nsenter工具(应该是有点问题)
$ wget https://www.kernel.org/pub/linux/utils/util-linux/v2.29/util-linux-2.29.tar.xz
$ tar xf util-linux-2.29.tar.xz
$ cd util-linux-2.29
$ ./configure --without-ncurses
$ make nsenter
$ sudo cp nsenter /usr/local/bin
$ PID=$(docker inspect --format "{ { .State.Pid } }" <container>)
$ nsenter --target $PID --mount --uts --ipc --net --Pid
5、删除容器
$ docker rm a2cbb52e01ae
   			-f,--force=false强行终止并删除一个运行中的容器
   			-l,--link=false删除容器的连接，但保留容器
   			-v,--volumes=false删除容器挂载的数据卷
$ sudo docker ps -a  (先查看所有运行过的容器)
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS               NAMES
a2cbb52e01ae        centos:latest       "/bin/bash"         19 hours ago        Up 18 minutes                                 determined_kilby
7ffb44f148ef        centos              "/bin/bash"         46 hours ago        Exited (0) 20 hours ago                       hungry_golick
c2590ac4d8ea        centos              "/bin/bash"         46 hours ago        Exited (0) 46 hours ago                       pensive_morse
[zhangqiang@mail ~]$ docker rm c2590ac4d8ea   #删除已经停止的容器
c2590ac4d8ea
[zhangqiang@mail ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS               NAMES
a2cbb52e01ae        centos:latest       "/bin/bash"         19 hours ago        Up 19 minutes                                 determined_kilby
7ffb44f148ef        centos              "/bin/bash"         46 hours ago        Exited (0) 20 hours ago                       hungry_golick
#可以看到已经删除所选ID的容器了（还可以删除处于运行中的容器）
[zhangqiang@mail ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS               NAMES
a2cbb52e01ae        centos:latest       "/bin/bash"         19 hours ago        Up 24 minutes                                 determined_kilby
7ffb44f148ef        centos              "/bin/bash"         46 hours ago        Exited (0) 20 hours ago                       hungry_golick
[zhangqiang@mail ~]$ docker rm -f a2cbb52e01ae
a2cbb52e01ae
[zhangqiang@mail ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS               NAMES
7ffb44f148ef        centos              "/bin/bash"         46 hours ago        Exited (0) 20 hours ago                       hungry_golick
#删除所有没有在运行中的容器
$ sudo docker rm $(docker ps -a -q)
6、导入和导出容器
# 先实现导出容器到文件
$ sudo docker save -o centos7.tar centos
$ sudo docker save alpine | gzip > alpine.tar.gz
# 利用文件导入到容器中
$ sudo docker load --input centos7.tar
$ sudo docker load -i alpine.tar.gz


四、创建仓库
$ sudo docker pull registry    #下载一个registry容器，创建本地私有仓库服务
$ sudo docker run -d -p 5000:5000 -v /data/docker/registry/:/tmp/registry registry
a586ed434315f76b13c365609774c85773f015172496366ed099dfb95abdc239
#默认情况下，会将仓库创建在容器的/tmp/registry目录下，使用-v参数来将镜像文件存放在本地的指定路径上
$ sudo docker tag ubuntu 192.168.12.20:5000/ubuntu  
#使用docker tag命令将这个镜像标记为192.168.12.20:5000/ubuntu
（？未完，还没测试成功）

*--privileged=true  容器加特权



五、数据管理
容器中管理数据主要由两种方式：
	数据卷（Data Volumes）
	数据卷容器（Data Volume Dontainers）

1、数据卷：数据卷是一个可供容器使用的特殊目录，它绕过文件系统，可以提供很多有用的特性
	数据卷可以在容器之间共享和重用。
	对数据卷的修改会立马生效。
	对数据卷的更新，不会影响镜像。
	卷会一直存在，直到没有容器使用。
		挂载一个主机目录作为数据卷
		$ ll /data/web/html
	    -rw-r--r-- 1 root root 13 12月 16 13:52 index.html
	    # docker run -it -v /data/web/html:/usr/local/html centos /bin/bash
		[root@2129eac3e535 /]# ls /usr/local/html
		index.html
2、数据卷容器
#如果用户需要在容器之间共享一些持续更新的数据，最简单是方式是使用数据卷容器，数据卷容器其实就是一个普通的容器，专门用它提供数据卷供其他容器挂载使用
	首先，创建一个数据卷容器dbdata，并在其中创建一个数据卷挂载到/dbdata
	[root@mail ~]# docker run -it -v /dbdata --name dbdata ubuntu
	root@bdeff1b474b3:/# ls   #查看所有目录
	bin  boot  dbdata  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
	然后，可以在其它容器中使用--volumes-from来挂载dbdata中的数据卷，例如创建db1和db2两个容器，并从dbdata容器挂载数据卷
	$ sudo docker run -it --volumes-from dbdata --name db1 ubuntu
	$ sudo docker run -it --volumes-from dbdata --name db2 ubuntu
	#在dbdata上面创建一个文件
	root@bdeff1b474b3:/# cd /dbdata/
	root@bdeff1b474b3:/dbdata# touch index.php
	root@bdeff1b474b3:/dbdata# ls
	index.php
	#启动db1容器，验证是否成功
	[root@mail ~]# docker run -it --volumes-from dbdata --name db1 ubuntu
	root@ea94216b298b:/# ls /dbdata/
	index.php
	*注意：如果删除了挂载的容器（包括dbdata、db1），数据卷并不会被自动删除。如果要删除一个数据卷，必须在删除最后一个还挂载着它的容器时显式使用docker rm -v命令来指定同事删除关联的容器
	*使用数据卷容器可以让用户在容器之间自由地升级和移动数据卷
3、利用数据卷容器迁移数据(这块还有点问题，过段时间研究)
    备份
    $ sudo docker run --volumes-from dbdata -v $(pwd):/backup --name worker ubuntu tar cvf /backup/backup.tar /dbdata
    # ll
    -rw-r--r--   1 root root    10240 12月 16 15:43 backup.tar
    *命令作用：首先利用ubuntu镜像创建了一个容器worker。使用--volumes-from dbdata参数来让
    worker容器挂载dbdata容器的数据卷（即dbdata数据卷);使用-v $(pwd):/backup参数来挂载本地
	的当前目录。worker容器启动后，使用tar cvf /backup/backup.tar /dbdata命令来将/dbdata
	下内容备份为容器的/backup/backup.tar，即宿主主机当前目录下的backup.tar.
	恢复
	如果要恢复数据到一个容器
	# docker run -v /dbdata --name dbdata ubuntu /bin/bash
	# docker run --volumes-from dbdata -v $(pwd):/backup ubuntu tar xvf /backup/backup.tar
	dbdata/
	dbdata/index.php

六、网络配置
1、端口映射实现访问容器
	*从外部访问容器应用
	在启动容器的时候，如果不指定对应参数，在容器外部是无法通过网络来访问容器内的网络应用和服务的。
	当容器中运行一些网络应用，要让外部访问这些应用时，可以通过-P或-p参数来指定端口映射。
		-P：docker会随机映射一个48000-49900的端口至容器内部开放的网络端口
		-p：指定映射的端口，并且，在一个指定的端口上只可以绑定一个容器
			映射所有接口地址：使用hostPort:container格式将本地的80端口映射到容器的80端口
			$ sudo docker run -d -p 80:80 centos-nginx python app.py
			此时默认会绑定本地所有接口上的所有地址。多次使用-p标记可以绑定多个端口。例如
			$ sudo docker run -d -p 80:80 -p 9000:9000 centos-nginx python app.py
			映射到指定地址的指定端口：使用ip:hostPort:containerPort格式指定映射使用一个特定地址
			$ sudo docker run -d -p 127.0.0.1:5000:5000 centos-nginx python app.py 
			映射到指定地址的任意端口：使用ip:hostPort绑定localhost的任意端口到容器的5000端口，本机会自动分配一个端口
			$ sudo docker run -d -p 127.0.0.1:5000 centos-nginx python app.py
			还可以使用udp标记来指定udp端口
			$ sudo docker run -d -p 127.0.0.1:5000:5000/udp centos-nginx python app.py
	*查看映射端口配置
			$ sudo docker port name 5000
2、容器互联实现容器间通信
	*容器的连接系统是除了端口映射另一种可以与容器中应用进行交互的方式。它会在源和接收容器之间创建一个隧道，接收容器可以看到源容器指定的信息。
	*自定义容器命名
		连接系统依据容器名称来执行。因此，首先需要自定义一个好记得容器命名。
		虽然当创建容器的时候，系统默认会分配一个名字，但自定义命名容器有两个好处：
			自定义的命名，比较好记，比如作为一个有用的Web应用容器，我们可以给它起名叫web。
			当要连接其他容器的时候，可以作为一个有用的参考点。
	使用--name标记可以为容器自定义命名：
		$ sudo docker run -it -p 80:80 --name web centos7-nginx
	使用docker ps来验证设定的命名：
		$ sudo docker ps
		CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                NAMES
		4f073dd9b927        centos7-nginx       "/bin/bash"         37 seconds ago      Up 37 seconds       0.0.0.0:80->80/tcp   web
	*容器互联（暂时没有弄懂）
		使用--link参数可以让容器之间安全的进行交互。
		例如：
			$ sudo docker run -d --name db centos-mysql   #创建一个数据库容器
			$ sudo docker run -d -P --name web --link db:db centos-nginx python app.py #创建一个新的Web容器，并将它连接到db容器
		此时，db容器和web容器建立互联关系
			--link参数的格式为--link name:alias，其中name是要连接的容器的名称，alias是这个连接的别名。

七、使用DockerFile创建镜像
	*Dockerfile是一个文本格式的配置文件，用户可以使用DockerFile快速创建自定义的镜像
	注意：Dockerfile中每一个指令都会建立一层，例如RUN，每一个RUN的行为，就和手工建立的镜像一样；新建立一层，在其上执行这些命令，执行结束后，commit这一层的修改，构成新的镜像。
		 而这种写法。运行太多RUN，就会创建多层镜像，只是完全没有意义的，而且很多运行时不需要的东西，都被装进了镜像里，比如编译环境、更新的软件包等等。结果就是产生非常臃肿、非常多层的镜像，不仅仅增加了构建部署的时间，也很容易出错。
		 Union FS是有最大层数限制的，比如AUFS，曾经最大不超过42层，现在最大不超过127层。
	1、基本结构
	Dockerfile由一行行命令语句组成，并且支持以#开头的注释行
	一般而言，Dockerfile分为四部分：基础镜像信息、维护者信息、镜像操作指令和容器启动时指定指令。
		*例如：
		FROM centos 	#第一行必须指定基础镜像
		MAINTAINER docker_user docker_user@email.com     #维护者信息
		RUN yum -y install nginx   	#镜像的操作指令，可以多条
		RUN echo "hello,world!" > /usr/local/nginx/html/index.html      
		CMD /etc/init.d/nginx start      #容器启动时执行命令
	2、指令
	指令的一般格式为INSTRUCTION arguments，指令包括FROM、MAINTAINER、RUN等。
		*FROM
		格式为FROM <images> 或 FROM <images>:<tag>
		第一条指令必须为FROM指令。并且，如果在同一个Dockerfile中创建多个镜像时，可以使用多个FROM指令（每个镜像一次）。
		(docker还存在一个特殊的镜像，名为scratch,这个镜像是虚拟的概念，并不实际存在，它表示一个空白的镜像)
		*MAINTAINER
		格式为MAINTAINER <name>，指定维护者信息
		*RUN
		格式为RUN <command> 或 RUN ["executable","param1","param2"]
		前者将在shell终端中运行命令，即/bin/sh -c;后者则使用exec执行。指定使用其他终端可以通过第二种方式实现，例如RUN ["/bin/bash","-c","echo hello"]
		每条RUN指令将在当前镜像基础上执行指定命令，并提交为新的镜像。当命令较长时可以使用\来换行。
	    	使用RUN指令时，应该用一个RUN指令，并使用&&将各个所需命令串联起来简化为一层，并且，为了格式化或者清晰明了，Dockerfile支持shell类的行尾添加\的命令进行换行，以及行首#进行注释的格式。良好的格式，比如换行、缩进、注释等，会让维护、排障更为容易，这是一个比较好的习惯。
	        此外，还要注意每一组命令结束之前，应该有清理工作的指令，删除下载的安装包，展开的文件和编译构建之内的文件，并且应该清楚安装的缓存文件。这是很重要的一步，镜像是多层存储，每一层的东西并不会被下一层删除，会一直跟着镜像，因此构建镜像时，一定要确保每一层只添加真正需要的东西，任何无关的东西都应该清理掉。

	    *CMD
	    支持三种格式：
	    CMD ["executable","param1","param2"]使用exec执行，推荐方式。
	    CMD command param1 param2 在/bin/sh中执行，提供给需要交互的应用。
	    CMD ["param1","param2"]提供给ENTRYPOINT的默认参数。
	    指定启动容器时执行的命令，每个Dockerfile只能有一条CMD命令，如果指定了多条命令，只有最后一条会被执行。
	    如果用户启动容器时候制定了运行的命令，则会覆盖掉CMD指定的命令。
	    对于容器而言，其启动程序就是容器应用进程。容器就是为了主进程而存在的，主进程退出，容器就失去了存在的意义，从而退出，其他辅助进程不是它需要关心的东西。
	    *EXPOSE
	    格式为EXPOSE <port> [<port>...]
	    例如：EXPOSE 22 80 443
	    告诉Docker服务端容器暴露的端口号，供互联系统使用。在启动容器时需要通过-P，Docker主机会自动分配一个端口转发到指定的端口；使用-p，则可以具体指定哪个本地端口映射过来。
	    EXPOSE指令是声明运行时容器提供服务端口，这只是一个声明，在运行时并不会因为这个声明应用就会开启这个端口的服务。
	    *ENV
	    格式为ENV <key> <value>。指定一个环境变量，会被后续RUN指令使用，并在容器运行时保持。例如：
	    ENV PG_MAJOR 9.3
	    ENV PG_VERSION 9.3.4
	    RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && ...
	    ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
	    *ARG构建参数
	    格式为ARG <参数名> [=<默认值>]
	    构建参数和ENV的效果一样，都是设置环境变量。所不同的时，ARG所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的，但是不要因此就是用ARG保存密码之内的信息，因为docker history还是可以看到所有值的。
	    *ADD
	    格式为ADD <src> <dest>
	    该命令将复制指定的<src>到容器中的<dest>。其中<src>可以是Dockerfile所在目录的一个相对路径(文件或目录)；也可以是一个URL；还可以是一个tar文件（自动解压为目录）。
	    *COPY
	    格式为COPY <src> <dest>
	    复制本地的<src>(为Dockerfile所在目录的相对路径，文件或目录)为容器中的<dest>。目标路径不存在时，会自动创建。
	    使用COPY命令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。
	    当使用本地目录为源目录时，推荐使用COPY。
	    *ENTRYPOINT 
	    有两种格式：
	    ENTRYPOINT ["executable","param1","param2"]
	    ENTRYPOINT command param1 param2 (shell中执行)
	    配置容器启动后执行的命令，并且不可被docker run提供的参数覆盖
	    每个Dockerfile中只能有一个ENTRYPOINT，当指定多个ENTRYPOINT，只有最后一个生效。
	    注意：当ENTRYPOINT存在时，CMD的内容将会作为参数传给ENTRYPOINT。
	    *VOLUME 
	    格式为VOLUME ["<路径1>"，"<路径2>"]    VOLUME <路径>
	    创建一个可以从本地主机或其他容器挂载的挂载点，一般用来存放数据库和需要保持的数据等。
	    *USER 
	    格式为USER daemon
	    指定运行容器时的用户名或UID，后续的RUN也会使用指定用户。
	    当服务不需要管理员权限时，可以通过该命令指定运行用户。并且可以在之前创建所需要的用户，例如：
	    RUN groupadd -r postgres && useradd -r -g postgres postgres。要临时获取管理员权限可以使用gosu，而不推荐sudo。
	    *WORKDIR
	    格式为WORKDIR /path/to/workdir。
	    为后续的RUN、CMD、ENTRYPOINT指令配置工作目录。
	    可以使用多个WORKDIR指令，后续命令如果参数是相对路径，则会基于之前命令指定的路径。例如：
	    WORKDIR /a
	    WORKDIR b
	    WORKDIR c
	    RUN pwd
	    则最终路径为/a/b/c
	    *HEALTHCHECK
	    格式为HEALTHCHECK [选项] CMD <命令>：设置检查容器健康状态的命令
	    HEALTHCHECK NONE：如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令。当在一个镜像指定了HEALTHCHECK指令后，用其启动容器，初始状态会为starting，在HEALTHCHECK指令检查成功后变为healthy，如果连续一定次数失败，则会变为unhealthy。
	    	支持的选项：
	    		--interval=<间隔>：两次健康检查的间隔，默认为30秒。
	    		--timeout=<时长>：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认为30秒；
	    		--retries=<次数>：当连续失败指定次数后，则将容器状态视为unhealthy，默认3次。
	    	注意：HEALTHCHECK只可以出现一次，如果写了多个，只有最后一个生效。
	    *ONBUILD
	    格式为ONBUILD [INSTRUCTION]
	    配置当所创建的镜像作为其他新创建镜像的基础镜像时，所执行的操作指令。例如，Dockerfile使用如下的内容创建了镜像image-A。
	    [...]
	    ONBUILD ADD . /app/src
	    ONUBILD RUN /usr/local/bin/python-build --dir /app/src
	    [...]
	    如果基于image-A创建新的镜像时，新的Dockerfile中使用FROM image-A指定基础镜像时，会自动执行ONBUILD指令内容，等价于在后面添加了两条指令。

	    FROM image-A
	    #Automatically run the following
	    ADD ./app/src
	    RUN /usr/local/bin/python-build --dir /app/src
	    使用ONBUILD指令的镜像，推荐在标签中注明，例如ruby:1.9-onbuild。
	3、创建镜像
		编写完Dockerfile之后，可以通过docker build命令来创建镜像。
		*基本的格式为docker build[选项]路径，该命令将读取指定路径下（包含子目录）的Dockerfile，并将该路径下所有内容发送给Docker服务端，由服务端来创建镜像。因此一般建议放置Dockerfile的目录为空目录。
		用docker build构建镜像时，它会将制定路径下地所有内容打包然后发给Docker引擎。这样Docker引擎收到这个上下文包后，展开就会获得构建镜像所需的一切文件。
		另外，可以通过 .dockerignore文件（每一行添加一条匹配模式）来让Docker忽略路径下的目录和文件。
		要指定镜像的标签信息，可以通过-t选项。
		例如，指定Dockerfile所在路径为/tmp/docker_builder/，并且希望生成镜像标签为build_repo/first_image，可以使用下面的命令：
		$ sudo docker build -t build_repo/first_image /tmp/docker_builder/


八、私有仓库
1、安装运行docker-registry
	$ sudo docker pull registry
	$ sudo docker run -d -p 5000:5000 registry
2、本地安装
	$ sudo yum install -y python-devel libevent-devel python-pip gcc xz-devel
	$ sudo python-pip install docker-registry
3、模板
	在 config_sample.yml 文件中，可以看到一些现成的模板段:
      	common:基础配置
      	local:存储数据到本地文件系统
		s3:存储数据到 AWS S3 中
		dev:使用 local 模板的基本配置
		test:单元测试使用
		prod:生产环境配置(基本上跟s3配置类似) 
		gcs:存储数据到 Google 的云存储
		swift:存储数据到 OpenStack Swift 服务
		glance:存储数据到 OpenStack Glance 服务，本地文件系统为后备
		glance-swift:存储数据到 OpenStack Glance 服务，Swift 为后备 
		elliptics:存储数据到 Elliptics key/value 存储	

⑩、安装docker-compose
# curl -L https://github.com/docker/compose/releases/download/1.9.0/run.sh > /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

