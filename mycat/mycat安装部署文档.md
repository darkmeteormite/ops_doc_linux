一、集群架构
```
10.25.86.43     huoban-mycat-app01

10.81.60.51     huoban-mycat-mysql01
10.81.62.125    huoban-mycat-mysql02

10.80.154.187   huoban-mycat-mysql03
10.81.61.146    huoban-mycat-mysql04

10.81.62.95     huoban-mycat-mysql05
10.81.62.154    huoban-mycat-mysql06

10.81.69.29     huoban-mycat-mysql07
10.81.19.35     huoban-mycat-mysql08
```
二、Mycat安装

1、系统环境：
```
# cat /etc/redhat-release
CentOS Linux release 7.4.1708 (Core)
```
2、关闭Selinux和防火墙
```
# systemctl stop firewalld
# setenforce 0
# getenforce
```
3、下载安装JDK
```
下载链接地址http://www.oracle.com/technetwork/java/javase/downloads/index.html
# yum -y install jdk-8u131-linux-x64.rpm
```
4、下载安装mycat
```
# wget http://dl.mycat.io/1.6-RELEASE/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz
# tar xf Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz -C /usr/local/
```
5、新建用户和组
```
# groupadd mycat
# useradd -g mycat -r mycat
# chown -R mycat.mycat /usr/local/mycat
```
6、添加环境变量
```
# echo "export PATH=/usr/local/mycat/bin:$PATH" >> /etc/profile
# echo "export JAVA_HOME=/usr/java/latest" >> /etc/profile
# echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/profile
```
三、编写分库分表规则，启动Mycat
1、后端mysql服务器对mycat授权
```
mysql> grant all on *.* to root@'10.%' identified by '123456';
Query OK, 0 rows affected (0.00 sec)
mysql> flush privileges;
Query OK, 0 rows affected (0.01 sec)
```
2、写分片规则
```
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

        <schema name="huoban_v4" checkSQLschema="false">
		<table name="files" dataNode="dna1,dna2,dna3,dna4"  primaryKey="file_id" rule="file_id"/>
		<table name="workflow_logs" dataNode="dna1,dna2,dna3,dna4"  primaryKey="workflow_log_id"/>
                <table name="revisions_0" dataNode="dna1" primaryKey="revision_id"/>
                ...
                <table name="revisions_199" dataNode="dna4" primaryKey="revision_id"/>

		        <table name="item_streams_0" dataNode="dna1" primaryKey="stream_id"/>
                ...
                <table name="item_streams_199" dataNode="dna4" primaryKey="stream_id"/>
        </schema>
        <schema name="TESTDB" checkSQLschema="false">
		<table name="travelrecord" dataNode="dnb1,dnb2,dnb3" rule="mod-long"/>
	    </schema>
        <dataNode name="dna1" dataHost="dn_t1" database="huoban_v4"/>
        <dataNode name="dna2" dataHost="dn_t2" database="huoban_v4"/>
        <dataNode name="dna3" dataHost="dn_t3" database="huoban_v4"/>
        <dataNode name="dna4" dataHost="dn_t4" database="huoban_v4"/>
        <dataNode name="dnb1" dataHost="dn_t1" database="test"/>
        <dataNode name="dnb2" dataHost="dn_t2" database="test"/>
        <dataNode name="dnb3" dataHost="dn_t3" database="test"/>
        <dataHost name="dn_t1" maxCon="1000" minCon="10" balance="2"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
                <heartbeat>select user()</heartbeat>
                <writeHost host="hostM1" url="10.81.60.51:3306" user="root" password="123456">
		<readHost host="hostS1" url="10.81.62.125:3306" user="root" password="123456"/>
                </writeHost>
        </dataHost>
        <dataHost name="dn_t2" maxCon="1000" minCon="10" balance="2"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
                <heartbeat>select user()</heartbeat>
                <writeHost host="hostM1" url="10.80.154.187:3306" user="root" password="123456">
		<readHost host="hostS1" url="10.81.61.146:3306" user="root" password="123456"/>
                </writeHost>
        </dataHost>
        <dataHost name="dn_t3" maxCon="1000" minCon="10" balance="2"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
                <heartbeat>select user()</heartbeat>
                <writeHost host="hostM1" url="10.81.62.95:3306" user="root" password="123456">
		<readHost host="hostS1" url="10.81.62.154:3306" user="root" password="123456"/>
                </writeHost>
        </dataHost>
        <dataHost name="dn_t4" maxCon="1000" minCon="10" balance="2"
                          writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
                <heartbeat>select user()</heartbeat>
                <writeHost host="hostM1" url="10.81.69.29:3306" user="root" password="123456">
		<readHost host="hostS1" url="10.81.69.35:3306" user="root" password="123456"/>
                </writeHost>
        </dataHost>
</mycat:schema>
```
3、启动mycat
```
# /usr/local/mycat/bin/mycat start
```
4、连接并灌入数据测试
```
# mysql -uroot -p123456 -h127.0.0.1 -P8066 
mysql> show databases;
+----------+
| DATABASE |
+----------+
| huoban_v4 |    //虚拟数据库
+----------+
1 row in set (0.00 sec)
mysql> use huoban_v4;
mysql> source /backup/all.sql;

Query OK, 1672 rows affected (0.41 sec)
Records: 1672  Duplicates: 0  Warnings: 0

Query OK, 1672 rows affected (0.50 sec)
Records: 1672  Duplicates: 0  Warnings: 0

Query OK, 1672 rows affected (0.61 sec)
Records: 1672  Duplicates: 0  Warnings: 0   //灌入数据
```
5、查询
四、增删节点

1)、准备工作
```
1、mycat所在环境安装mysql客户端程序
2、mycat的lib目录下添加mysql的jdbc驱动包
3、对扩容缩容的表所有节点数据进行备份，以便迁移失败后的数据恢复
```
2)、扩容缩容步骤
```
1、复制 schema.xml、rule.xml 并重命名为 newSchema.xml、newRule.xml 放于 conf 目录下
2、修改 newSchema.xml 和 newRule.xml 配置文件为扩容缩容后的 mycat 配置参数(表的节点数、 数据源、路由规则)
3、修改 conf 目录下的 migrateTables.properties 配置文件，告诉工具哪些表需要进行扩容或缩 容,没有出现在此配置文件的 schema 表不会进行数据迁移，格式:
huoban_v4=revisions_76
4、修改 bin 目录下的 dataMigrate.sh 脚本文件，参数如下:
    tempFileDir 临时文件路径,目录不存在将自动创建
    isAwaysUseMaster 默认 true:不论是否发生主备切换，都使用主数据源数据，false:使用当前数据源
    mysqlBin:mysql bin 路径
    cmdLength mysqldump 命令行长度限制 默认 110k 110*1024。在 LINUX 操作系统有限制单条命令行的长度是 128KB，也就是 131072 字节，这个值可能不同操作系统不同内核都不一样，如果执行迁移时报 Cannot run program "sh": error=7, Argument list too long 说明这个值设置大了，需要调小此值。
    charset 导入导出数据所用字符集 默认 utf8
    deleteTempFileDir 完成扩容缩容后是否删除临时文件 默认为 true
    threadCount 并行线程数(涉及生成中间文件和导入导出数据)默认为迁移程序所在主机环境的 cpu 核数*2
    delThreadCount 每个数据库主机上清理冗余数据的并发线程数，默认为当前脚本程序所在主机 cpu 核数/2
    queryPageSize 读取迁移节点全部数据时一次加载的数据量 默认 10w 条
5、停止 mycat 服务(如果可以确保扩容缩容过程中不会有写操作，也可以不停止 mycat 服务)
6、通过工具进入 mycat 根目录，执行 bin/ dataMigrate.sh 脚本，开始扩容/缩容过程:
    
    [huoban_v4:revisions_76] dn1->dn0 completed in 60741ms
    [huoban_v4:revisions_76] dn2->dn0 completed in 71357ms
    [huoban_v4:revisions_76] dn0->dn1 completed in 99417ms
    [huoban_v4:revisions_76] dn2->dn1 completed in 145257ms
    
    2018-03-28 15:35:55:907 [3]-> cleaning redundant data...
    [huoban_v4:revisions_76] clean dataNode dn1 completed in 91219ms
    [huoban_v4:revisions_76] clean dataNode dn0 completed in 10914ms
    [huoban_v4:revisions_76] clean dataNode dn2 completed in 130ms
    [huoban_v4:revisions_76] clean dataNode dn2 completed in 152ms
    
    2018-03-28 15:37:38:354 [4]-> validating tables migrate result...
     +----------migrate result-----------+
     |[huoban_v4:revisions_76] -> success|
     +-----------------------------------+


    2018-03-28 15:37:39:827 migrate data complete in 251744ms
    
7、扩容缩容成功后，将 newSchema.xml 和 newRule.xml 重命名为 schema.xml 和 rule.xml 并替 换掉原文件，重启 mycat 服务，整个扩容缩容过程完成。
```
3)、注意事项:
```
    1、保证拆分表迁移数据前后路由规则一致
    2、保证拆分表迁移数据前后拆分字段一致
    3、全局表将被忽略
    4、不要将非拆分表配置到migrateTables.properties文件中 
    5、暂时只支持拆分表使用mysql作为数据源的扩容缩容
```
