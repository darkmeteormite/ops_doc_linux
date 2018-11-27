1、系统环境初始化
```
# systemctl stop firewalld
# setenforce 0
```
2、配置docker yum源仓库并安装启动
```
# wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
# yum -y install docker-ce
# systemctl start docker
```
3、安装docker-compose
```
# wget https://mirrors.aliyun.com/docker-toolbox/linux/compose/1.21.2/docker-compose-Linux-x86_64 -O /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
```
4、创建配置文件目录
```
# mkdir /data/conf/registry -pv
# cd /data/conf/registry
# mkdir -p auth data
```
5、编写docker-compose配置文件
```
# vim /data/conf/registry/docker-compose.yaml
nginx:
  image: "nginx:alpine"
  ports:
    - 443:443
  links:
    - registry:registry
  volumes:
    - ./auth:/etc/nginx/conf.d
    - ./auth/nginx.conf:/etc/nginx/nginx.conf:ro
  restart: always

registry:
  image: registry:2
  ports:
    - 127.0.0.1:5000:5000
  volumes:
    - /data/docker:/var/lib/registry
  restart: always
```
6、编写nginx配置文件（证书需要提前准备好）
```
# vim /data/conf/registry/auth/nginx.conf
events {
    worker_connections  1024;
}

http {

  upstream docker-registry {
    server registry:5000;
  }

  map $upstream_http_docker_distribution_api_version $docker_distribution_api_version {
    '' 'registry/2.0';
  }

  server {
    listen 443 ssl;
    server_name hub.huoban.com;

    # SSL
    ssl_certificate /etc/nginx/conf.d/server.crt;
    ssl_certificate_key /etc/nginx/conf.d/server.key;

    # Recommendations from https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    client_max_body_size 0;

    chunked_transfer_encoding on;

    location /v2/ {
      if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" ) {
        return 404;
      }

      # To add basic authentication to v2 use auth_basic setting.
      #auth_basic "Registry realm";
      #auth_basic_user_file /etc/nginx/conf.d/nginx.htpasswd;

      add_header 'Docker-Distribution-Api-Version' $docker_distribution_api_version always;

      proxy_pass                          http://docker-registry;
      proxy_set_header  Host              $http_host;   # required for docker client's sake
      proxy_set_header  X-Real-IP         $remote_addr; # pass on real client's IP
      proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header  X-Forwarded-Proto $scheme;
      proxy_read_timeout                  900;
    }
  }
}
```
7、启动
```
# docker-compose up -d
```
8、验证
```
# docker login hub.huoban.com

# docker tag nginx:latest hub.huoban.com/nginx:latest
# docker push hub.huoban.com/nginx:latest
The push refers to repository [hub.huoban.com/nginx]
d1bade4185fe: Pushed
190f3188c8aa: Pushed
cdb3f9544e4c: Pushed
latest: digest: sha256:42e8199b5eb4a9e4896308cabc547740a0c9fc1e1a1719abf31cd444d426fbc8 size: 948
# curl --user admin:admin https://hub.huoban.com/v2/_catalog
{"repositories":["centos","nginx","registry"]}
```
