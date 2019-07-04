通过Zabbix模板检查监控rabbitmq队列和服务器。


1、设置python脚本，zabbix模板和关联数据进行自动发现

    使用系统为centos6.5，python版本为2.6，使用软件为zabbix。
    将文件zabbix_agent.d/zabbix-rabbitmq.conf复制到zabbix-server端的/etc/zabbix/zabbix_agent.d目录下
    将脚本文件目录scripts/rabbitmq复制到/etc/zabbix/scripts中，将权限更改为Zabbix。
        # sudo chmod -R zabbix.zabbix /etc/zabbix/scripts
    确保已安装zabbix_sender，如未安装可使用
        # sudo yum -y install zabbix-sender    进行安装
    重新启动本地zabbix代理
        # sudo service zabbix-agent restart

2、使用方法
    
    将模板导入zabbix服务器（rabbitmq.template.xml）
    
3、使用应注意安全问题

    您应该在scripts/rabbitmq目录中创建一个文件.rab.auth。该文件允许您更改默认参数，格式为VARIABLE=value每行一个：默认值如下：

    USERNAME=guest  #rabbitmq使用账号
    PASSWORD=guest  #rabbitmq使用密码
    CONF=/etc/zabbix/zabbix_agent.conf   #zabbix-agent端配置文件
    LOGLEVEL=INFO   #日志级别为INFO
    LOGFILE=/var/log/zabbix/rabbitmq_zabbix.log     #记录日志文件的位置

    您还可以在此文件中添加一个过滤器来限制哪些队列被监视。此项目是JSON编码的字符串。该格式为其使用提供了一些灵活性。您可以提供单个对象或要过滤的对象列表。可用的键是：status，node，name，consumer，vhost，durable，exclusive_consumer_tag，auto_delete，memory，policy。

    例如，以下过滤器可以找到所有耐用队列： FILTER='{"durable": true}'

    为了仅对给定的虚拟机使用持久队列，过滤器将是： FILTER='{"durable": true, "vhost": "mine"}'

    要提供队列名称列表，过滤器将是： FILTER='[{"name": "mytestqueuename"}, {"name": "queue2"}]'

    要调试任何的问题，请确保日志目录存在并可以由zabbix用户写入，然后在.rab.auth文件中设置LOGLEVEL = DEBUG，您将获得相当详细的输出

    队列的低级发现，可以参考zabbix官方文档：
    https://www.zabbix.com/documentation/3.0/manual/regular_expressions 
