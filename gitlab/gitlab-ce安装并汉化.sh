源码安装 GitLab 步骤繁琐：需要安装依赖包，Mysql，Redis，Postfix，Ruby，Nginx……安装完毕还得一个个手动配置这些软件。源码安装容易出错，不顺利的话，一天都搞不定。源码最大的好处是私人定制，如果不做定制化，还是使用官方推荐的 omnibus packages 方式安装，网络好的话，一个小时内搞定。

参照官方安装文档，分别在 Ubuntu 14 和 CentOS 6 两个机器上安装，过程非常顺利，没有错误。

在 Ubuntu 14 安装

使用国内安装源镜像，加快安装速度。修改/etc/apt/sources.list.d/gitlab-ce.list，添加以下行

deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/debian jessie main
开始安装：

# 安装依赖包
sudo apt-get install curl openssh-server ca-certificates postfix
# 安装 GitLab 社区版
apt-get install gitlab-ce
# 初始化，初始化完自动启动 GitLab
sudo gitlab-ctl reconfigure
在 CentOS 6 安装

使用国内镜像安装，新建 /etc/yum.repos.d/gitlab-ce.repo，添加以下内容

[gitlab-ce]
name=gitlab-ce
baseurl=http://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el6
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packages.gitlab.com/gpg.key
安装步骤：

# 安装依赖包
sudo yum install curl openssh-server openssh-clients postfix cronie
# 启动 postfix 邮件服务
sudo service postfix start
# 检查 postfix
sudo chkconfig postfix on
# 安装 GitLab 社区版
sudo yum install gitlab-ce
# 初始化 GitLab
sudo gitlab-ctl reconfigure
修改 host

添加访问的 host，修改/etc/gitlab/gitlab.rb的external_url

external_url 'http://git.home.com'
vi /etc/hosts，添加 host 映射

127.0.0.1 git.home.com
每次修改/etc/gitlab/gitlab.rb，都要运行以下命令，让配置生效

sudo gitlab-ctl reconfigure
配置本机的 host，如：192.168.113.59 git.home.com。最后，在浏览器打开网址http://git.home.com，登陆。默认管理员：

用户名: root
密码: 5iveL!fe
安装中文语言包（汉化）

以下汉化步骤参考此篇文章，首先确认当前安装版本

cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
当前安装版本是8.5.7，因此中文补丁需要打8.5版本。

克隆 GitLab 源码仓库：

# 克隆 GitLab.com 仓库
git clone https://gitlab.com/larryli/gitlab.git
＃或 Gitcafe.com 镜像，速度更快
git clone https://gitcafe.com/larryli/gitlab.git
运行汉化补丁：

# 8.5 版本的汉化补丁（8-5-stable是英文稳定版，8-5-zh是中文版，两个 diff 结果便是汉化补丁）
sudo git diff origin/8-5-stable..8-5-zh > /tmp/8.5.diff
# 停止 gitlab
sudo gitlab-ctl stop
# 应用汉化补丁
cd /opt/gitlab/embedded/service/gitlab-rails
git apply /tmp/8.5.diff  
# 启动gitlab
sudo gitlab-ctl start

#或者另外一种方式（需要先克隆或者下载gitlab源码）
# cp -r /opt/gitlab/embedded/service/gitlab-rails{,.ori}     #备份
# gitlab-ctl stop    #关闭服务
# \cp -rf /data/gitlab/* /opt/gitlab/embedded/service/gitlab-rails/   #复制克隆的汉化版本到目标目录
    cp: cannot overwrite non-directory ‘/opt/gitlab/embedded/service/gitlab-rails/log’ with directory ‘/root/gitlabhq/log’
    cp: cannot overwrite non-directory ‘/opt/gitlab/embedded/service/gitlab-rails/tmp’ with directory ‘/root/gitlabhq/tmp’
#会报错忽略，因为之前已经设置过gitlab的root密码了
# gitlab-ctl start  #启动服务
至此，汉化完毕。打开地址http://git.home.com，便会看到中文版的GitLab。如下


安装完成。

备份

如果是生产环境，备份是必须的。需要备份的文件：配置文件和数据文件。

备份配置文件

配置文件含密码等敏感信息，不要和数据备份文件放在一起。

sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%s.tar") -C /etc/gitlab'
备份数据文件

默认数据备份目录是/var/opt/gitlab/backups，手动创建备份文件：

# Omnibus 方式安装使用以下命令备份
sudo gitlab-rake gitlab:backup:create
日常备份，添加 crontab，运行crontab -e

# 每天2点执行备份
0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1
如要修改备份周期和目录，在/etc/gitlab/gitlab.rb中修改以下两个选项

# 设置备份周期为7天 - 604800秒
gitlab_rails['backup_keep_time'] = 604800
# 备份目录
gitlab_rails['backup_path'] = '/mnt/backups'
恢复

恢复之前，确保备份文件所安装 GitLab 和当前要恢复的 GitLab 版本一致。首先，恢复配置文件：

sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# 将下面配置备份文件的时间戳改为你所备份的文件的时间戳
sudo tar -xf etc-gitlab-1399948539.tar -C /
恢复数据文件

# 将数据备份文件拷贝至备份目录
sudo cp 1393513186_gitlab_backup.tar /var/opt/gitlab/backups/

# 停止连接数据库的进程
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# 恢复1393513186这个备份文件，将覆盖GitLab数据库！
sudo gitlab-rake gitlab:backup:restore BACKUP=1393513186

# 启动 GitLab
sudo gitlab-ctl start

# 检查 GitLab
sudo gitlab-rake gitlab:check SANITIZE=true
持续集成(GitLab-CI)

GitLab 从 8.0 之后就集成了GitLab-CI，所以不需要再另外安装 CI。但需要安装Runner

1.添加 Runner 安装源

# For Debian/Ubuntu
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash

# For CentOS
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.rpm.sh | sudo bash
安装gitlab-ci-multi-runner

# For Debian/Ubuntu
apt-get install gitlab-ci-multi-runner

# For CentOS
yum install gitlab-ci-multi-runner
2.注册 Runner。获取Token：以管理员身份登录GitLab，进入管理区域，点击侧边栏的Runner，如下图，“注册授权码”后的字符串便是Token。


sudo gitlab-ci-multi-runner register

Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/ci):
http://git.home.com/ci
Please enter the gitlab-ci token for this runner:
xxxx             # 输入Token
Please enter the gitlab-ci description for this runner:
[xxy-web-test-02]: test-runner  # 输入runner的名称
Please enter the gitlab-ci tags for this runner (comma separated):
test,php         # 输入runner的标签，以区分不同的runner，标签间逗号分隔
Registering runner... succeeded                     runner=YDPz2or3
Please enter the executor: ssh, shell, parallels, docker, docker-ssh, virtualbox:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!