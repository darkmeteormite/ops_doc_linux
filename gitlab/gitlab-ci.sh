gitlab-ci

名词解释
	
	进坑前先理清一些名词，以及他们之间的关系。

1、Gitlab
	
	GitLab是一个利用Ruby on Rails开发的开源应用程序，实现一个自托管的Git项目仓库，可通过Web界面进行访问公开的或者私人项目。它拥有与GitHub类似的功能，能够浏览源代码，管理缺陷和注释。可以管理团队对仓库的访问，它非常易于浏览提交过的版本并提供一个文件历史库。团队成员可以利用内置的简单聊天程序（Wall）进行交流。它还提供一个代码片段收集功能可以轻松实现代码复用，便于日后有需要的时候进行查找。

2、Gitlab-CI

	Gitlab-CI是GitLab Continuous Integration（Gitlab持续集成）的简称。
	从Gitlab的8.0版本开始，gitlab就全面集成了Gitlab-CI,并且对所有项目默认开启。
	只要在项目仓库的根目录添加.gitlab-ci.yml文件，并且配置了Runner（运行器），那么每一次合并请求（MR）或者push都会触发CI pipeline。

3、Gitlab-runner

	Gitlab-runner是.gitlab-ci.yml脚本的运行器，Gitlab-runner是基于Gitlab-CI的API进行构建的相互隔离的机器（或虚拟机）。GitLab Runner 不需要和Gitlab安装在同一台机器上，但是考虑到GitLab Runner的资源消耗问题和安全问题，也不建议这两者安装在同一台机器上。

	Gitlab Runner分为两种，Shared runners和Specific runners。
	Specific runners只能被指定的项目使用，Shared runners则可以运行所有开启 Allow shared runners选项的项目。

4、Pipelines

	Pipelines是定义于.gitlab-ci.yml中的不同阶段的不同任务。
	我把Pipelines理解为流水线，流水线包含有多个阶段（stages），每个阶段包含有一个或多个工序（jobs），比如先购料、组装、测试、包装再上线销售，每一次push或者MR都要经过流水线之后才可以合格出厂。而.gitlab-ci.yml正是定义了这条流水线有哪些阶段，每个阶段要做什么事。

5、Badges

	徽章，当Pipelines执行完成，会生成徽章，你可以将这些徽章加入到你的README.md文件或者你的网站。

	徽章的链接形如：
	http://example.gitlab.com/namespace/project/badges/branch/build.svg 


6、安装gitlab-ci-multi-runner
	
	如果想要使用docker runner，则需要安装docker。（可选）
	curl -sSL https://get.docker.com/ | sh
	因为docker需要linux内核在3.10或以上，安装前可以通过uname -r查看Linux内核版本。

	添加Gitlab的官方源：
	# For Debian/Ubuntu
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash

	# For CentOS
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.rpm.sh | sudo bash

7、安装

	# For Debian/Ubuntu
	sudo apt-get install gitlab-ci-multi-runner

	# For CentOS
	sudo yum install gitlab-ci-multi-runner

8、注册RunnerRunner需要注册到Gitlab才可以被项目所使用，一个gitlab-ci-multi-runner服务可以注册多个Runner。

	打开你 GitLab 中的项目页面，在项目设置中找到 runners
	运行 sudo gitlab-ci-multi-runner register
	输入 CI URL
	输入 Token
	输入 Runner 的名字
	选择 Runner 的类型，简单起见还是选 Shell 吧
	完成
	
	# gitlab-ci-multi-runner register
	
		Running in system-mode.

		Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
		http://mail.bjwf125.com/ci
		Please enter the gitlab-ci token for this runner:
		BxiVW6s5NH_u-smRzF9L
		Please enter the gitlab-ci description for this runner:
		[node1.bjwf125.com]: mail
		Please enter the gitlab-ci tags for this runner (comma separated):
		shell
		Whether to run untagged builds [true/false]:
		[false]:
		Whether to lock Runner to current project [true/false]:
		[false]:
		Registering runner... succeeded                     runner=BxiVW6s5
		Please enter the executor: docker+machine, docker-ssh+machine, docker, docker-ssh, parallels, ssh, shell, virtualbox, kubernetes:
		shell
		Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
	
	# cat /etc/gitlab-runner/config.toml  #查看授权配置文件
		
		concurrent = 1
		check_interval = 0

		[[runners]]
		  name = "mail"
		  url = "http://mail.bjwf125.com/ci"
		  token = "45de1b2ab9ef8d14ad38e0cbee040e"
		  executor = "shell"
		  [runners.cache]

	# gitlab-runner list 	#查看各runner的状态
	
		Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml
		mail                                                Executor=shell Token=45de1b2ab9ef8d14ad38e0cbee040e URL=http://mail.bjwf125.com/ci













