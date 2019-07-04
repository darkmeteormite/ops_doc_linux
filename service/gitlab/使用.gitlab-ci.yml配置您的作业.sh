 使用.gitlab-ci.yml配置您的作业

 使用.gitlab-ci.yml配置您的作业 
本文档描述了.gitlab-ci.ymlGitLab Runner用于管理项目作业的文件的用法。

如果您想快速介绍GitLab CI，请按照我们的 快速入门指南。

.gitlab-ci.yml 
从版本7.12，GitLab CI使用YAML 文件（.gitlab-ci.yml）进行项目配置。它放置在存储库的根目录中，并包含如何构建项目的定义。

YAML文件定义了一组具有约束的作业，说明何时应该运行它们。作业被定义为具有名称的顶级元素，并且必须至少包含script子句：

job1:
  script: "execute-script-for-job1"

job2:
  script: "execute-script-for-job2"
上述示例是具有两个单独作业的最简单的CI配置，其中每个作业执行不同的命令。

当然，命令可以直接（./configure;make;make install）执行代码，也可以test.sh在存储库中运行一个script（）。

工作由跑步者拾起并在跑步者的环境中执行。重要的是每项工作都是独立运作的。

YAML语法允许使用比上述示例中更复杂的作业规范：

image: ruby:2.1
services:
  - postgres

before_script:
  - bundle install

after_script:
  - rm secrets

stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - execute-script-for-job1
  only:
    - master
  tags:
    - docker
有一些保留keywords是不能被用作作业名：

关键词	需要	描述
图片	没有	使用泊坞窗图像，满身是使用泊坞窗
服务	没有	使用泊坞窗服务，覆盖在使用泊坞窗
阶段	没有	定义构建阶段
类型	没有	别名stages（已弃用）
before_script	没有	定义在每个作业的脚本之前运行的命令
after_script	没有	定义在每个作业的脚本之后运行的命令
变量	没有	定义构建变量
缓存	没有	定义应该在后续运行之间缓存的文件列表
形象和服务 
这允许指定一个自定义的Docker映像和一个可以用于作业时间的服务列表。此功能的配置在 单独的文档中介绍。

before_script 
before_script用于定义在所有作业（包括部署作业）之前但在恢复工件之后应运行的命令。这可以是数组或多行字符串。

after_script 
在GitLab 8.7中引入，需要Gitlab Runner v1.2

after_script用于定义将在所有作业之后运行的命令。这必须是一个数组或多行字符串。

阶段 
stages用于定义作业可以使用的阶段。的说明书stages允许具有灵活的多阶段流水线。

元素stages的排序定义作业的执行顺序：

相同阶段的工作并行运行。
上一阶段的工作成功完成后，下一阶段的工作就会运行。
我们考虑下面的例子，它定义了3个阶段：

stages:
  - build
  - test
  - deploy
首先，所有工作build都是并行执行的。
如果所有作业build成功，则test并行执行作业。
如果所有作业test成功，则deploy并行执行作业。
如果所有作业deploy成功，则提交将被标记为success。
如果以前任何一个作业失败，则提交将被标记为failed并且不执行进一步的作业。
还有两个值得一提的边缘案例：

如果没有stages被定义.gitlab-ci.yml，那么build， test和deploy允许被用作默认作业的阶段。
如果作业未指定stage作业，则将作业分配给test舞台。
类型 
已弃用，并将在10.0中删除。使用阶段来代替。

别名为阶段。

变量 
在GitLab Runner v0.5.0中引入。

GitLab CI允许您添加.gitlab-ci.yml在作业环境中设置的变量。变量存储在Git存储库中，旨在存储非敏感项目配置，例如：

variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
这些变量可以在以后在所有执行的命令和脚本中使用。YAML定义的变量也设置为所有创建的服务容器，从而允许对其进行微调。也可以在作业层面定义变量 。

除了用户定义的变量，还有由Runner本身设置的变量。一个例子是CI_COMMIT_REF_NAME具有构建项目的分支或标签名称的值。除了可以设置的变量之外.gitlab-ci.yml，还有所谓的秘密变量，可以在GitLab的UI中设置。

了解有关变量的更多信息。

缓存 
在GitLab Runner v0.7.0中引入。

cache用于指定应该在作业之间缓存的文件和目录的列表。您只能使用项目工作区内的路径。

默认情况下，从GitLab 9.0开始，管道和作业之间启用缓存并共享

如果cache被定义在作业范围之外，则意味着它在全局设置，并且所有作业将使用该定义。

缓存的所有文件binaries和.config：

rspec:
  script: test
  cache:
    paths:
    - binaries/
    - .config
缓存所有Git未跟踪的文件：

rspec:
  script: test
  cache:
    untracked: true
缓存所有Git未跟踪的文件和文件binaries：

rspec:
  script: test
  cache:
    untracked: true
    paths:
    - binaries/
本地定义的高速缓存覆盖全局定义的选项。以下rspec 作业将仅缓存binaries/：

cache:
  paths:
  - my/files

rspec:
  script: test
  cache:
    key: rspec
    paths:
    - binaries/
请注意，由于缓存在作业之间共享，如果您为不同作业使用不同的路径，那么还应该设置不同的缓存：key 否则缓存内容可以被覆盖。

缓存是尽力而为的，所以不要指望缓存将始终存在。有关实施细节，请查看GitLab Runner。

缓存：键 

在GitLab Runner v1.0.0中引入。

该key指令允许您定义作业之间缓存的亲和度，允许为所有作业，每个作业缓存，每个分支缓存或任何其他您认为正确的方式拥有单个缓存。

这允许您微调缓存，允许您在不同的作业甚至不同的分支之间缓存数据。

该cache:key变量可以使用任何预定义的变量。

项目默认的默认键是默认的，因此默认情况下，每个管道和作业之间共享一切，从GitLab 9.0开始。

示例配置

启用每个作业的缓存：

cache:
  key: "$CI_JOB_NAME"
  untracked: true
启用每分支缓存：

cache:
  key: "$CI_COMMIT_REF_NAME"
  untracked: true
启用每个作业和每个分支缓存：

cache:
  key: "$CI_JOB_NAME/$CI_COMMIT_REF_NAME"
  untracked: true
启用每个分支和每个阶段的缓存：

cache:
  key: "$CI_JOB_STAGE/$CI_COMMIT_REF_NAME"
  untracked: true
如果您使用Windows Batch来运行您的shell脚本，则需要替换 $为%：

cache:
  key: "%CI_JOB_STAGE%/%CI_COMMIT_REF_NAME%"
  untracked: true
工作 
.gitlab-ci.yml允许您指定无限数量的作业。每个作业必须有一个唯一的名称，这不是上述关键字之一。作业由定义作业行为的参数列表定义。

job_name:
  script:
    - rake spec
    - coverage
  stage: test
  only:
    - master
  except:
    - develop
  tags:
    - ruby
    - postgres
  allow_failure: true
关键词	需要	描述
脚本	是	定义由Runner执行的shell脚本
图片	没有	使用Docker图像，使用Docker图像
服务	没有	使用Docker Images使用码头服务
阶段	没有	定义一个工作阶段（默认：test）
类型	没有	别名为 stage
变量	没有	在作业级别定义作业变量
只要	没有	定义创建作业的git参考列表
除	没有	定义未创建作业的git参考列表
标签	没有	定义用于选择Runner的标签列表
allow_failure	没有	允许作业失败。失败的作业无助于提交状态
什么时候	没有	定义何时运行作业。可以是on_success，on_failure，always或者manual
依赖关系	没有	定义作业所依赖的其他作业，以便您可以在它们之间传递工件
文物	没有	定义作业文件列表
缓存	没有	定义应该在后续运行之间缓存的文件列表
before_script	没有	覆盖在作业之前执行的一组命令
after_script	没有	覆盖在作业后执行的一组命令
环境	没有	定义此作业完成部署的环境名称
覆盖面	没有	定义给定作业的代码覆盖率设置
脚本 
script是由Runner执行的shell脚本。例如：

job:
  script: "bundle exec rspec"
此参数还可以包含使用数组的多个命令：

job:
  script:
    - uname -a
    - bundle exec rspec
有时，script命令需要用单引号或双引号括起来。例如，包含冒号（:）的命令需要用引号括起来，以便YAML解析器知道将整个事物解释为字符串而不是“key：value”对。使用特殊字符时要小心： :，{，}，[，]，,，&，*，#，?，|，-，<，>，=，!，%，@，`。

阶段 
stage允许将作业分组到不同的阶段。stage 执行相同的作业parallel。有关使用stage请查看 阶段的更多信息。

只有和除外 
only并且except是设置参考策略限制作业构建时的两个参数：

only 定义作业将要运行的分支和标签的名称。
except定义作业不能运行的分支和标签的名称 。
有一些适用于参考资料政策使用的规则：

only并且except是包容性的 如果同时only并except在作业规范中定义，裁判通过过滤only和except。
only并except允许使用正则表达式。
only并except允许使用特殊的关键字：branches，tags，和triggers。
only并except允许指定一个存储库路径来过滤叉子的作业。
在下面的示例中，job将只针对以开头的参数运行issue-，而所有分支将被跳过。

job:
  # use regexp
  only:
    - /^issue-.*$/
  # use special keyword
  except:
    - branches
在这个例子中，job将仅对标记的引用运行，或者通过API触发器明确地请求构建。

job:
  # use special keywords
  only:
    - tags
    - triggers
存储库路径可用于仅为父存储库执行作业，而不是叉：

job:
  only:
    - branches@gitlab-org/gitlab-ce
  except:
    - master@gitlab-org/gitlab-ce
上述示例将运行job于gitlab-org/gitlab-ce除master之外的所有分支。

工作变量 
可以使用variables作业级别的关键字来定义作业变量。它的工作原理与其全局级别的方法基本相同，但允许您定义作业特定的变量。

当在variables作业级使用关键字时，它将覆盖全局YAML作业变量和预定义作业变量。要关闭作业中的全局定义变量，请定义一个空数组：

job_name:
  variables: []
作业变量优先级在变量文档中定义。

标签 
tags 用于从允许运行此项目的所有跑步者列表中选择特定的赛跑者。

在一个亚军的注册，您可以指定亚军的标签，例如ruby，postgres，development。

tags 允许您运行具有分配给它们的指定标签的运行器的作业：

job:
  tags:
    - ruby
    - postgres
上面的规范将确保job由一个具有两个rubyAND postgres标签的Runner构建。

allow_failure 
allow_failure当您要允许作业失败而不影响其余的CI套件时使用。失败的作业无助于提交状态。

启用并且作业失败时，对于所有意图和目的，流水线将成功/绿色，但是在合并请求或提交或作业页面上将显示“通过警告的CI构建”消息。这被允许失败的作业使用，但是如果失败表示其他地方应采取其他（手动）步骤。

在下面的示例中，job1并且job2将并行运行，但是如果job1 失败，则不会停止运行的下一个阶段，因为它标记为 allow_failure: true：

job1:
  stage: test
  script:
  - execute_script_that_will_fail
  allow_failure: true

job2:
  stage: test
  script:
  - execute_script_that_will_succeed

job3:
  stage: deploy
  script:
  - deploy_to_staging
什么时候 
when 用于实现在出现故障或运行失败时运行的作业。

when 可以设置为以下值之一：

on_success - 只有当前一个阶段的所有工作成功时才​​执行工作。这是默认值。
on_failure - 仅当前一个阶段的至少一个作业发生故障时才执行作业。
always - 无论前一阶段的工作状况如何，执行工作。
manual - 手动执行作业（在GitLab 8.10中添加）。阅读 下面的手动操作。
例如：

stages:
- build
- cleanup_build
- test
- deploy
- cleanup

build_job:
  stage: build
  script:
  - make build

cleanup_build_job:
  stage: cleanup_build
  script:
  - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
  - make test

deploy_job:
  stage: deploy
  script:
  - make deploy
  when: manual

cleanup_job:
  stage: cleanup
  script:
  - cleanup after jobs
  when: always
以上脚本将：

cleanup_build_job仅在build_job失败时执行。
始终执行cleanup_job作为流水线的最后一步，无论成功或失败。
允许您deploy_job从GitLab的UI 手动执行。
手动操作 

在GitLab 8.10中介绍。

手动操作是不自动执行的特殊类型的作业; 他们需要由用户明确地启动。可以从管道，构建，环境和部署视图启动手动操作。

手动操作的示例使用是部署到生产。

阅读更多在环境文档。

手动操作可以是可选的或阻止的。阻止手动操作将在此操作定义的阶段阻止流水线的执行。当有人通过单击播放按钮执行阻止手动操作时，可以恢复管道的执行。

当管道被阻止时，如果管道成功设置时合并，则不会合并管道。封闭的管道也有一个特殊的状态，称为手动。

默认情况下，手动操作不阻止。如果要进行手动操作阻止，则需要添加allow_failure: false到作业的定义中.gitlab-ci.yml。

allow_failure: true默认情况下，可选手动操作已设置。

可选操作的状态对总体管道状态无贡献。

GitLab 9.0中引入了禁止手动操作

环境 
笔记：

在GitLab 8.9中引入。
你可以阅读更多有关的环境，并找到更多的例子 有关环境的文档。
environment用于定义作业部署到特定环境。如果environment被指定，并且没有该名称下的环境，则将自动创建一个新的名称。

在最简单的形式中，environment关键字可以定义如下：

deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
在上述示例中，deploy to production作业将被标记为对环境进行production部署。

环境：名称 

笔记：

在GitLab 8.11中引入。
在GitLab 8.11之前，环境的名称可以被定义为一个字符串 environment: production。现在推荐的方法是在name关键字下定义它 。
该environment名称可以包含以下内容：

信件
数字
空格
-
_
/
$
{
}
通用名称是qa，staging和production，但您可以使用与工作流程相匹配的任何名称。

除了在environment 关键字之后定义环境的名称之外，还可以将其定义为单独的值。为此，请使用以下name关键字environment：

deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
环境：url 

笔记：

在GitLab 8.11中引入。
在GitLab 8.11之前，该URL只能在GitLab的UI中添加。现在推荐的方法是定义它.gitlab-ci.yml。
这是一个可选的值，当设置时，它会暴露GitLab中各个位置的按钮，当单击时，您可以访问定义的URL。

在下面的示例中，如果作业成功完成，它将在合并请求和将指向的环境/部署页面中创建按钮https://prod.example.com。

deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
    url: https://prod.example.com
environment：on_stop 

笔记：

介绍在GitLab 8.13。
从GitLab 8.14开始，当您有一个定义了停止动作的环境时，GitLab会在关联的分支被删除时自动触发停止动作。
关闭（stoping）环境可以通过下面on_stop定义的关键字 来实现environment。它宣布了一个不同的工作，以便关闭环境。

阅读本environment:action节为例。

环境：行动 

介绍在GitLab 8.13。

该action关键字与on_stop被称为关闭环境的作业结合使用并定义。

例如：

review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  script: make delete-app
  when: manual
  environment:
    name: review
    action: stop
在上面的例子中，我们设置了review_app部署到环境中的review 工作，我们也定义了一个新的stop_review_app工作on_stop。一旦review_app作业成功完成，它将stop_review_app根据下面的定义触发 作业when。在这种情况下，我们设置它，manual因此需要通过GitLab的Web界面进行手动操作才能运行。

该stop_review_app作业需要定义以下关键字：

when- 参考
environment:name
environment:action
stage应该是相同的review_app，以便环境在分支被删除时自动停止
动态环境 

笔记：

介绍在GitLab 8.12和GitLab亚军1.6。
在$CI_ENVIRONMENT_SLUG被介绍在GitLab 8.15。
environment也可以用name和表示一个配置哈希url。这些参数可以使用任何定义的CI变量 （包括预定义的安全变量和.gitlab-ci.yml变量）。

例如：

deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
该deploy as review app作业将被标记为部署以动态创建review/$CI_COMMIT_REF_NAME环境，其中由Runner设置$CI_COMMIT_REF_NAME 的环境变量在哪里。该 $CI_ENVIRONMENT_SLUG变量基于环境名称，但适合包含在URL中。在这种情况下，如果deploy as review app作业是在命名的分支中运行的pow，那么这个环境将可以通过一个URL访问 https://review-pow.example.com/。

这当然意味着承载应用程序的底层服务器被正确配置。

常见的用例是为分支创建动态环境，并将其用作Review Apps。您可以在https://gitlab.com/gitlab-examples/review-apps-nginx/上查看使用Review Apps的简单示例 。

文物 
笔记：

在非Windows平台的GitLab Runner v0.7.0中引入。
GitLab Runner v.1.0.0中添加了Windows支持。
目前并不是所有的执行者都被支持。
默认情况下，作业工件仅针对成功的作业进行收集。
artifacts用于指定成功后应附加到作业的文件和目录的列表。您只能使用项目工作区内的路径。要在不同的作业之间传递工件，请参阅依赖关系。以下是一些例子。

发送所有文件binaries和.config：

artifacts:
  paths:
  - binaries/
  - .config
发送所有Git未跟踪的文件：

artifacts:
  untracked: true
发送所有Git未跟踪的文件和文件binaries：

artifacts:
  untracked: true
  paths:
  - binaries/
要禁用工件传递，请使用空的依赖关系定义作业：

job:
  stage: build
  script: make build
  dependencies: []
您可能只想为标记的版本创建工件，以避免使用临时构建工件填充构建服务器存储。

仅为标签创建工件（default-job不会创建工件）：

default-job:
  script:
    - mvn test -U
  except:
    - tags

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
    - target/*.war
  only:
    - tags
工作完成后，工件将发送到GitLab，并可在GitLab UI中下载。

文物：名称 

在GitLab 8.6和GitLab Runner v1.1.0中引入。

该name指令允许您定义创建的工件存档的名称。这样，您可以为每个存档提供一个唯一的名称，当您希望从GitLab下载存档时，这可能会很有用。该artifacts:name 变量可以使用任何预定义的变量。默认名称为artifacts，成为artifacts.zip下载的时候。

示例配置

要创建具有当前作业名称的归档文件：

job:
  artifacts:
    name: "$CI_JOB_NAME"
要创建具有当前分支或标记的名称的归档文件，仅包含由Git未跟踪的文件：

job:
   artifacts:
     name: "$CI_COMMIT_REF_NAME"
     untracked: true
要使用当前作业的名称创建一个存档，并且当前的分支或标记仅包含Git未跟踪的文件：

job:
  artifacts:
    name: "${CI_JOB_NAME}_${CI_COMMIT_REF_NAME}"
    untracked: true
要创建具有当前阶段和分支名称的存档：

job:
  artifacts:
    name: "${CI_JOB_STAGE}_${CI_COMMIT_REF_NAME}"
    untracked: true
如果您使用Windows Batch来运行您的shell脚本，则需要替换 $为%：

job:
  artifacts:
    name: "%CI_JOB_STAGE%_%CI_COMMIT_REF_NAME%"
    untracked: true
文物：何时 

在GitLab 8.9和GitLab Runner v1.3.0中引入。

artifacts:when 用于在作业失败或尽管发生故障时上传工件。

artifacts:when 可以设置为以下值之一：

on_success - 仅当作业成功时上传工件。这是默认值。
on_failure - 仅当作业失败时才上传工件。
always - 无论工作状态如何，都会上传工件。
示例配置

仅在作业失败时上传工件。

job:
  artifacts:
    when: on_failure
文物：expire_in 

在GitLab 8.9和GitLab Runner v1.3.0中引入。

artifacts:expire_in用于在指定时间后删除上传的工件。默认情况下，工件永远存储在GitLab上。expire_in允许您指定制品在其过期之前应存在多长时间，从上传和存储在GitLab上的时间开始计算。

您可以使用作业页面上的“ 保留 ”按钮来覆盖过期并永久保存工件。

到期后，默认情况下实际上会删除工件（通过cron作业），但在到期后不可访问。

值expire_in是经过的时间。可分析值的示例：

'3分4秒'
'2小时20分钟'
'2h20min'
'6 mos 1天'
'47年6 mos和4d'
'3周2天'
示例配置

上传后1周过期文物：

job:
  artifacts:
    expire_in: 1 week
依赖关系 
在GitLab 8.6和GitLab Runner v1.1.1中引入。

此功能应与之结合使用，artifacts并允许您定义在不同作业之间传递的工件。

请注意，默认情况下artifacts，所有以前的阶段都将被传递。

要使用此功能，请dependencies在作业的上下文中定义，并传递所有以前作业的列表，从中下载工件。您只能从在当前执行的阶段定义作业。如果从当前阶段或下一个阶段定义作业，将会显示错误。定义空数组将跳过下载该作业的任何工件。

在下面的例子中，我们定义了两个就业机会，文物，build:osx和 build:linux。当test:osx被执行时，从所述工件build:osx 将被下载和在构建的上下文中提取。同样的事情test:linux和文物从build:linux。

deploy由于阶段优先级，该作业将从以前所有作业中下载工件：

build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
    - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
    - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
  - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
  - build:linux

deploy:
  stage: deploy
  script: make deploy
before_script和after_script 
可以覆盖全局定义的before_script和after_script：

before_script:
- global before script

job:
  before_script:
  - execute this instead of global before script
  script:
  - my command
  after_script:
  - execute this after my script
覆盖面 
笔记：

介绍在GitLab 8.17。
coverage 允许您配置如何从作业输出中提取代码覆盖率。

正则表达式是这里唯一有效的值。所以，使用周边/是强制性的，以便一致地和明确地表示正则表达式字符串。如果你想从字面上匹配，你必须逃脱特殊字符。

一个简单的例子：

job1:
  coverage: '/Code coverage: \d+\.\d+/'
Git策略 
作为实验功能在GitLab 8.9中引入。在未来版本中可能会更改或完全删除。GIT_STRATEGY=none要求GitLab Runner v1.7 +。

您可以GIT_STRATEGY在全局variables部分或variables 单个作业的部分中设置用于获取最近的应用程序代码。如果未指定，将使用项目设置的默认值。

有三种可能的值：clone，fetch，和none。

clone是最慢的选择。它为每个作业从头开始克隆资源库，确保项目工作区始终是原始的。

variables:
  GIT_STRATEGY: clone
fetch更快，因为它重新使用项目工作区（clone 如果它不存在则回退）。git clean用于撤消上一个作业所做的更改，并git fetch用于检索自上次作业运行以来所做的提交。

variables:
  GIT_STRATEGY: fetch
none也重新使用项目工作区，但是跳过所有Git操作（包括GitLab Runner的pre-clone脚本（如果存在））。它主要用于仅对工件（例如deploy）进行操作的作业。Git存储库数据可能存在，但它肯定是过期的，因此您只应该依赖从缓存或工件引入项目工作空间的文件。

variables:
  GIT_STRATEGY: none
Git子模块策略 
需要GitLab Runner v1.10 +。

该GIT_SUBMODULE_STRATEGY变量用于在构建之前获取代码时控制是否/如何包含Git子模块。喜欢 GIT_STRATEGY，可以在全局variables 部分或variables单个作业的部分中设置。

有三种可能的值：none，normal和recursive：

none意味着在获取项目代码时不会包含子模块。这是默认值，它与v1.10之前的行为相匹配。

normal意味着只包括顶级子模块。相当于：

git submodule sync
git submodule update --init
recursive意味着将包括所有子模块（包括子模块子模块）。相当于：

git submodule sync --recursive
git submodule update --init --recursive
请注意，要使此功能正常工作，子模块必须.gitmodules配置为：

可公开访问的存储库的HTTP（S）URL
在同一个GitLab服务器上的另一个存储库的相对路径。请参阅 Git子模块文档。
作业阶段尝试 
在GitLab中引入，它需要GitLab Runner v1.9 +。

您可以设置运行作业将尝试执行以下每个阶段的尝试次数：

变量	描述
GET_SOURCES_ATTEMPTS	尝试获取运行作业的源的次数
ARTIFACT_DOWNLOAD_ATTEMPTS	尝试下载运行作业的工件的次数
RESTORE_CACHE_ATTEMPTS	尝试恢复运行作业的缓存的次数
默认是一次尝试。

例：

variables:
  GET_SOURCES_ATTEMPTS: "3"
您可以在全局variables部分或variables单个作业的 部分中设置它们。

浅克隆 
作为实验功能在GitLab 8.9中引入。可能会在未来版本中更改或完全删除。

您可以使用指定抓取和克隆的深度GIT_DEPTH。这允许浅层克隆存储库，这可以显着加速具有大量提交或旧的大型二进制文件的存储库的克隆。该值传递给git fetch和git clone。

注意： 如果深度为1，并且具有作业队列或重试作业，作业可能会失败。

由于Git获取和克隆是基于一个引用（如分支名称），所以Runners不能克隆特定的提交SHA。如果队列中有多个作业，或者您正在重试旧作业，则要测试的提交需要在克隆的Git历史记录中。设置太小的值GIT_DEPTH可能导致无法运行这些旧的提交。您将unresolved reference在作业日志中看到。然后，您应该重新考虑更改GIT_DEPTH为更高的值。

由于只有Git历史的一部分存在，依赖的作业git describe可能无法正常工作GIT_DEPTH。

仅获取或克隆最近3次提交：

variables:
  GIT_DEPTH: "3"
隐藏键 
在GitLab 8.6和GitLab Runner v1.1.1中引入。

以点（.）开头的键不会被GitLab CI处理。您可以使用此功能忽略作业，或使用 特殊的YAML功能，并将隐藏的键转换为模板。

在以下示例中，.key_name将被忽略：

.key_name:
  script:
    - rake spec
隐藏的键可以像普通CI作业一样散列，但是您也可以使用不同类型的结构来利用特殊的YAML功能。

特殊YAML功能 
可以使用特殊的YAML功能，如anchor（&），别名（*）和map merging（<<），这将大大降低复杂度.gitlab-ci.yml。

详细了解各种YAML功能。

锚点 
在GitLab 8.6和GitLab Runner v1.1.1中引入。

YAML有一个方便的功能，称为“锚”，可以让您轻松地在文档中复制内容。锚可用于复制/继承属性，并且是使用隐藏键 来为您的作业提供模板的完美示例。

以下示例使用锚点和地图合并。它会创建两个就业机会， test1并test2，将继承的参数.job_template，每一个自己定制其script定义为：

.job_template: &job_definition  # Hidden key that defines an anchor named 'job_definition'
  image: ruby:2.1
  services:
    - postgres
    - redis

test1:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test1 project

test2:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test2 project
&设置anchor（job_definition）的名称，<<表示“将给定的哈希合并到当前的哈希”，并*包括命名的锚（job_definition再次）。扩展版本如下所示：

.job_template:
  image: ruby:2.1
  services:
    - postgres
    - redis

test1:
  image: ruby:2.1
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.1
  services:
    - postgres
    - redis
  script:
    - test2 project
让我们看看另一个例子。这一次我们将使用anchor来定义两组服务。这将创建两个作业，test:postgres并且test:mysql，将共享script中定义的指令.job_template，并services 指令定义.postgres_services和.mysql_services分别为：

.job_template: &job_definition
  script:
    - test project

.postgres_services:
  services: &postgres_definition
    - postgres
    - ruby

.mysql_services:
  services: &mysql_definition
    - mysql
    - ruby

test:postgres:
  <<: *job_definition
  services: *postgres_definition

test:mysql:
  <<: *job_definition
  services: *mysql_definition
扩展版本如下所示：

.job_template:
  script:
    - test project

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
您可以看到隐藏的键被方便地用作模板。

触发器 
触发器可用于强制使用API​​调用重建特定分支，标记或提交。

在触发器文档中阅读更多内容。

页面 
pages是一个特殊的工作，用于将静态内容上传到GitLab，可用于为您的网站提供服务。它具有特殊的语法，因此必须满足以下两个要求：

任何静态内容必须放在public/目录下
artifactspublic/必须定义到目录的路径
下面的示例将所有文件从项目的根移动到 public/目录。该.public解决方法是这样cp不也复制 public/到自身无限循环：

pages:
  stage: deploy
  script:
  - mkdir .public
  - cp -r * .public
  - mv .public public
  artifacts:
    paths:
    - public
  only:
  - master
阅读更多关于GitLab Pages用户文档。

验证.gitlab-ci.yml 
GitLab CI的每个实例都有一个名为Lint的嵌入式调试工具。您可以在/ci/lintgitlab实例下找到链接。

跳过工作 
如果您的提交消息包含[ci skip]或[skip ci]使用任何大小写，将创建提交，但作业将被跳过。
