verdaccio

一、如何发布自己的npm包？

1、流程 
注册一个github账户用于托管代码 
注册一个npm账户 
开发module，更新至github 
发布module至npm 
2、命令 
npm init 
npm login 
npm publish 
npm unpublish (警告不推荐) 
【注意点1】不能和已有的包的名字重名 
【注意点2】npm包名限制：不能有大写字母/空格/下滑线 
二、怎么搭建自己的私有仓库？

1、安装docker,docker-compose 
2、下载配置文件 
# mkdir /data/verdaccio && cd /data/verdaccio 
# git clone https://github.com/verdaccio/docker-examples.git 
# cd docker-examples/docker-local-storage-volume/ 
 
 
# vim docker-compose.yaml 
 
version: '2.1' 
services: 
  verdaccio: 
    image: verdaccio/verdaccio:3 
    container_name: verdaccio-docker-local-storage-vol 
    restart: always 
    ports: 
      - "4873:4873" 
    volumes: 
        - "./storage:/verdaccio/storage" 
        - "./conf:/verdaccio/conf" 
volumes: 
  verdaccio: 
    driver: local 


# cd docker-examples/docker-local-storage-volume/  
# docker-compose up -d     (启动)
# docker-compose down      (停止)