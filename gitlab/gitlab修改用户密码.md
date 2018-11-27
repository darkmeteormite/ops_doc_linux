gitlab  修改用户密码

```
[root@svr34 bin]# gitlab-rails console production
Loading production environment (Rails 4.2.5.2)
irb(main):001:0> user = User.where(id: 1).first
=> #<User id: 1, email: "admin@example.com", ...
irb(main):002:0> user.password=12345678
=> 12345678
irb(main):003:0> user.password_confirmation=12345678
=> 12345678
irb(main):004:0> user.save!
=> true
irb(main):005:0> quit

```


gitlab-ci


```
#  gitlab-ci-multi-runner register
Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
https://gitlab.huobandev.com/
Please enter the gitlab-ci token for this runner:
j6kKsc4V_ARQmm5s6C3-
Please enter the gitlab-ci description for this runner:
[HUOBAN-DEV-GIT01]: HUOBAN-DEV-GIT01
Please enter the gitlab-ci tags for this runner (comma separated):
HUOBAN-DEV-GIT01,huoban_api
Whether to run untagged builds [true/false]:
[false]:
Whether to lock Runner to current project [true/false]:
[false]:
Registering runner... succeeded                     runner=j6kKsc4V
Please enter the executor: kubernetes, docker-ssh, docker+machine, shell, ssh, virtualbox, docker-ssh+machine, docker, parallels:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

gitlab升级
```
# gitlab-ctl stop unicorn
# gitlab-ctl stop sidekiq
# gitlab-ctl stop nginx
```
