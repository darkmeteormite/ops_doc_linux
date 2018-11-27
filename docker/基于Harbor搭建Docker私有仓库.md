什么是Harbor？
Harbor 是 VMware 公司开源的企业级 DockerRegistry 项目，项目地址为 https://github.com/vmware/harbor。其目标是帮助用户迅速搭建一个企业级的Docker registry 服务。它以 Docker 公司开源的 registry 为基础，提供了管理UI，基于角色的访问控制(Role Based Access Control)，AD/LDAP集成、以及审计日志(Auditlogging) 等企业用户需求的功能，同时还原生支持中文。Harbor 的每个组件都是以 Docker 容器的形式构建的，使用 Docker Compose 来对它进行部署。

环境准备
1、阿里云服务器(Centos7.4)
2、Docker版本(18.06.0.ce-3.el7)
3、Docker-compose(1.22.0)
4、Harbor

1、安装Docker
```
# wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# yum -y install docker-ce
使用国内镜像加速
# vim /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://registry.docker-cn.com"
        ]
}
# systemctl daemon-reload
# systemctl start docker
```
2、安装docker-compose
```
# sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
# docker-compose --version
docker-compose version 1.22.0, build f46880fe  #这种方式在国内特别慢
```
3、安装Harbor
```
# wget https://storage.googleapis.com/harbor-releases/harbor-offline-installer-v1.5.2.tgz
# tar xf harbor-offline-installer-v1.5.2.tgz -C /usr/local/
# cd /usr/local/harbor
# vim harbor.cfg   (修改配置文件)
    hostname = hub.huoban.com
    ui_url_protocol = http
    ssl_cert = /data/cert/server.crt
    ssl_cert_key = /data/cert/server.key
    harbor_admin_password = Harbor12345
# ./install.sh    
```
启动Harbor，修改配置文件后，在当前目录执行./install.sh，Harbor服务就会根据当前目录下的docker-compose.yml开始导入依赖的镜像，检测并按照顺序依次启动各个服务。
启动完成后，我们访问刚设置的hostname既可，http://hub.huoban.com，默认是80端口，如果端口暂用，我们可以修改docker-compose.yml文件，对应的端口映射。

我们可以看到系统各个模块如下：

    项目：新增/删除项目，查看镜像仓库，给项目添加成员、查看操作日志、复制项目等
    日志：仓库各个镜像create、push、pull等操作日志
    系统管理
    用户管理：新增/删除用户、设置管理员等
    复制管理：新增/删除从库目标、新建/删除/启停复制规则等
    配置管理：认证模式、复制、邮箱设置、系统设置等
    其他设置
    用户设置：修改用户名、邮箱、名称信息
    修改密码：修改用户密码
    注意：非系统管理员用户登录，只能看到有权限的项目和日志，其他模块不可见。

我们要尝试下能不能把自己 Docker 里面的镜像 push 到 Harbor 的 library 里来（默认这个 library 项目是公开的，所有人都可以有读的权限，都不需要 docker login 进来，就可以拉取里面的镜像）。

4、创建并提交镜像到仓库
```
# vim /etc/docker/daemon.json
{
    "insecure-registries":["http://hub.huoban.com"],
    "registry-mirrors":["https://registry.docker-cn.com/"]
}
# systemctl daemon-reload && systemctl restart docker
登录到仓库
# docker login hub.huoban.com
    Username: admin
    Password: Huoban2017
    WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store
    Login Succeeded
# docker tag registry:latest hub.huoban.com/library/registry:latest   #打tag
# docker push hub.huoban.com/library/registry:latest   #PUSH到仓库
The push refers to repository [hub.huoban.com/library/registry]
00b6cd9831d7: Pushed
5030e231e2c6: Pushed
7a2efe6c629c: Pushed
f824ed3a5fe3: Pushed
4da3a15c1916: Pushed
latest: digest: sha256:003a106b827ab7f5bd7140d08020b16c87cd6bcac024b01fe6247f87632f2978 size: 1364
```
