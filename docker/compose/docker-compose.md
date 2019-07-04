一、安装
*使用官方安装方法
pip install -U docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

Centos7 安装docker-compose
	# yum install python-pip
	# pip install --upgrade pip
	# pip install docker-compose

	运行docker-compose
	出现报错

	pkg_resources.DistributionNotFound: backports.ssl-match-hostname>=3.5
	使用pip 更新backports.ssl-match-hostname的版本

	# pip install --upgrade backports.ssl_match_hostname 
	更新backports.ssl_match_hostname 到3.5版本后问题解决

*使用阿里云镜像直接下载
# wget http://mirrors.aliyun.com/docker-toolbox/linux/compose/1.9.0/docker-compose-Linux-x86_64  
# mv docker-compose-Linux-x86_64 /usr/bin/docker-compose && chmod +x /usr/bin/docker-compose


二、配置示例文件
# cat app-nginx.conf
server {
    listen      80;
    server_tokens  off;

    root /usr/share/nginx/html/;
    index  index.html index.htm;
    location ~* \.php$ {
            fastcgi_pass   app-php:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;

    }

    location /api {
        try_files $uri $uri/ /api/public/index.php?$query_string;
    }

    location / {
       root /usr/share/nginx/html/chart;
       index index.html index.htm;

       if (!-e $request_filename) {
            rewrite (.*) /index.html;
       }
    }


    error_page   500 502 503 504  /50x.html;
    access_log  /var/log/nginx/access.log  main;
}



# cat app-php.conf
[www]
user = www-data
group = www-data
listen = 127.0.0.1:9000
pm = dynamic
pm.max_children = 100
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20





# cat docker-compose.yaml
version: '2'
services:
  app-nginx:
    image: nginx
    volumes_from:
      - app-php
    ports:
     - "0.0.0.0:80:80"
    command: nginx -g 'daemon off;'
    links:
      - app-php
  app-php:
    image: php-fpm
    volumes:
     - /data/web/html:/usr/share/nginx/html
     - ./app-php.conf:/usr/local/etc/php-fpm.d/www.conf
     - ./app-nginx.conf:/etc/nginx/conf.d/default.conf
     - /etc/localtime:/etc/localtime:ro

三、使用方法
1、术语
  服务(service)：一个应用容器，实际上可以运行多个相同镜像的实例。
  项目(project)：由一组关联的应用容器组成的一个完整业务单元。
  *一个项目可以由多个服务（容器）关联而成，Compose面向项目进行管理。

2、运行项目(利用示例文档中的配置文件)

3、compose命令说明
  *大部分命令都可以运行在一个或多个服务上。如果没有特别的说明，命令应用于项目的所有服务上。
  基本使用格式为：
  # docker-compose [options] [COMMAND] [ARGS...]
  选项：
    --verbose：输出更多调试信息
    --version：打印版本信息并退出
    -f，--file FILE：使用特定的compose模板文件，默认为当前目录的docker-compose.ymal文件
    -p，--project-name NAME：指定项目名称，默认使用目录名称
  命令：
    build
      构建或重新构建服务
      服务一旦构建后，将会带上一个标记名，例如web_db。
      可以随时在项目下运行docker-compose build来重新构建服务。
    help
      获得帮助信息
    kill
      通过发送SIGKILL信号来强制停止服务容器，支持通过参数来指定发送的信号，例如
      $ docker-compose kill -s SIGINT
    logs
      查看服务的输出
    ports
      打印绑定的公共端口
    ps 
      列出所有容器
    pull
      拉取服务镜像
    rm 
      删除停止的服务容器
    run 
      在一个服务上执行一条命令
    示例：
      $ sudo docker-compose run ubuntu ping baidu.com
      将会启动一个ubuntu服务，执行ping baidu.com命令
      默认情况下，所有关联的服务将会自动被启动，除非这些服务已经在运行中
      该命令类似启动容器后运行指定的命令，相关卷、链接等等都将会按照期望创建。
      两个不同点：
        *给定命令将会覆盖原有的自动运行命令；
        *不会自动创建端口，以避免冲突；
      如果不希望自动启动关联的容器，可以使用 --no-deps选项，例如
      $ sudo docker-compose run --no-deps web python manage.py shell
      将不会启动web容器所关联的其它容器
    scale
      设置同一个服务运行的容器个数
      通过service=num的参数来设置数量。例如：
      $ docker-compose scale web=2 worker=3
    start
      启动一个已经存在的服务容器
    stop
      停止一个已经运行的容器，但不删除它。通过docker-compose start可以再次启动这些容器
    up
      构建，（重建）创建，启动，链接一个服务相关的容器
      链接的服务都将会启动，除非他们已经运行
      默认情况，docker-compose up将会整合所有容器的输出，并且退出时，所有容器将会停止。
      使用 docker-compose up -d 将会在后台启动并运行所有的容器
      默认情况，如果该服务的容器已经存在，docker-compose up将会停止并尝试重新创建他们（保持使用volumes-from挂载的卷），已保证docker-compose.yml的修改生效。如果你不想容器被停止并重新创建，可以使用docker-compose up --no-recreate。如果需要的话，这样将会启动已经停止的容器。
      选项：
        -d:在后台运行服务容器
        --no-color:不使用颜色来区分不同的服务的控制台输出
        --no-deps:不启动服务所链接的容器
        --force-recreate:强制重新创建容器，不能与--no-recreate同时使用
        --no-recreate:如果容器已经存在了，则不重新创建，不能与--force-recreate同时使用
        --no-build:不自动构建缺失的服务镜像
        -t,--timeout TIMEOUT:停止容器时候的超时（默认为10秒）
4、YAML模板文件
  默认的模板文件是docker-compose.yml，其中定义的每个服务都必须通过Image指令指定镜像或build指定（通过Dockerfile）来自动构建。
  其它大部分指令都跟docker run 中的类似。
  如果使用build指令，在Dockerfile中设置的选项（例如：CMD,EXPOSE,VOLUME,ENV等）将会自动被获取，无需在docker-compose.yml中再次设置。
    *image
    指定为镜像名称或镜像ID。如果镜像在本地不存在，Compose将会尝试拉取这个镜像。
    例如：
      image: ubuntu
      image: orchardup/postgresql
      image: a4bc65fd
    *build
    指定Dockerfile所在文件夹的路径。compose将会利用它自动构建这个镜像，然后使用这个镜像
      build: /home/bjwf125/php
    *command
    覆盖容器启动后默认执行的命令
      command： bundle exec thin -p 3000
    *links
    链接到其它服务中的容器。使用服务名称（同时作为别名）或服务名称：服务别名（SERVICE:ALIAS）格式都可以
      links:
       - db 
       - db:database
       - redis
    使用的别名将会自动在服务容器中的/etc/hosts里创建。例如：
      172.17.2.186 db
      172.17.2.186 database
      172.17.2.186 redis
    相应地环境变量也将会被创建
    *external_links
    链接到docker-compose.yml外部的容器，甚至并非Compose管理的容器。参数格式和links类似
      external_links:
       - redis_1
       - project_db_1:mysql
       - project_db_1:postgresql
    *ports
    暴露端口信息
    使用宿主：容器（HOST:CONTAINER）格式或者仅仅指定容器的端口（宿主机将会随机选择端口）都可以。
      ports:
       - "3000"
       - "8000:8000"
       - "49100:22"
       - "127.0.0.1:8001:8001"
    注：当使用HOST:CONTAINER格式来映射端口时，如果你使用的容器端口小于60你可能会得到错误的结果，因为YAML将会解析xx:yy这种数字格式为60进制。所以建议采用字符串格式。
    *expose 
    暴露端口，但不映射到宿主机，只被连接的服务访问。
    仅可以指定内部端口为参数
      expose:
       - "3000"
       - "8000"
    *volumes
    卷挂载路径设置。可以设置宿主机路径（HOST:CONTAINER）或加上访问模式
      volumes:
       - /var/lib/mysql
       - cache/:/tmp/cache
       - ~/configs:/etc/configs/:ro
    *volumes_from
    从另一个服务或容器挂载它的所有卷
      volumes_from:
       - service_name
       - container_name
    *environment
    设置环境变量。可以使用数组或字典两种格式。
    只给定名称的变量会自动获取它在Compose主机上得值，可以用来防止泄露不必要的数据。
      environment
        RACK_ENV: development
        SESSION_SECRET:

      environment
        - RACK_EVN=development
        - SESSION_SECRET
    *env_file
    从文件中获取环境变量，可以为单独的文件路径或列表。
    如果通过docker-compose -f FILE指定了模板文件，则env_file中路径会基于模板文件路径。
    如果有变量名称与environment指令冲突，则以后者为准。
      env_file: .env 

      env_file:
       - ./common.env
       - ./apps/web.env
       - /opt/secrets.env
    环境变量文件中每一行必须符合格式，支持#开头的注释行。
      # common.env: Set Rails/Rack environment
      RACK_ENV=development
    *extends
    基于已有的服务进行扩展。例如我们已经有了一个webapp服务，模板文件为common.yml 
      # common.yml
      webapp:
        build: ./webapp
        environment:
          - DEBUG=false
          - SEND_EMAILS=false
    编写一个新的development.yml文件，使用common.yml中得webapp服务进行扩展。
      # development.yml
      web:
        extends:
          file: common.yml
          service: webapp
        ports:
          - "8000:8000"
        links:
          - db
        environment:
          - DEBUG=true
      db:
        image: postgres
    后者会自动继承common.yml中得webapp服务及相关环境变量
    *net
    设置网络模式。使用和docker client 的 --net参数一样的值
      net: "bridge"
      net: "none"
      net: "container:[name or id]"
      net: "host"
    *pid
    跟主机系统共享进程命名空间。打开该选项的容器可以相互通过进程ID来访问和操作
      pid: "host"
    *dns
    配置DNS服务器。可以使一个值，也可以使一个列表。
      dns: 8.8.8.8
      dns:
        - 8.8.8.8
        - 9.9.9.9
    *cap_add,cap_drop
    添加或放弃容器的Linux能力（Capabiliity）。
      cap_add:
        - ALL
      cap_drop:
        - NET_ADMIN
        - SYS_ADMIN
    *dns_search
    配置DNS搜索域。可以使一个值，也可以是一个列表。
      dns_search: example.com
      dns_search: 
        - domain1.example.com
        - domain2.example.com
    *privileged
    允许容器中运行一些特权命令
      privileged: true
    *working_dir,entrypoint,user,hostname,domainname,mem_limit,privileged,restart,stdin_open,tty,cpu_shares
    这些都是和docker run支持的选项类似
      cpu_shares: 73

      working_dir: /code
      entrypoint: /code/entrypoint.share
      user: postgresql

      hostname: foo
      domainname: foo.com

      mem_limit: 1000000000
      privileged: true

      restart: always

      stdin_open: true
      tty: true
    *ulimits
    指定容器的ulimits限制值
    例如，指定最大进程数为65535，指定文件句柄数为20000（软限制，应用可以随时修改，不能超过硬限制）和40000（系统硬限制，只能root用户提高）。
      ulimits:

        nproc:65535
        nofile:
          soft:20000
          hard:40000













