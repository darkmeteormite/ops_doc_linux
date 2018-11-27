Tomcat介绍：

Tomcat是一个免费开放源代码的web应用服务器，不是一个完整意义上的JavaEE服务器；它甚至都没有提供哪怕对一个主Java EE API的实现，但由于遵循apache开源协议，所以Tomcat却有为众多的Java应用程序服务器嵌入自己的产品中构建商业的Java应用程序服务器，如Jboss和JOnAS等。Tomcat工作在jdk(Java Development kit)之上；要想使用Tomcat必须先安装Jdk，Jdk分为openjdk和oracle Jdk，可以根据自己的需求选择相应的jdk来实现Tomcat实例。

Tomcat组件：

    Server： 即一个Tomcat实例；
    Service：用于将connector关联至engine组件；一个service只能包含一个engine组件和一个或多个connector组件；
    Engine： Tomcat的核心组件，用于运行jsp或者servlet代码；
    Connector： 接入并解析用户请求，讲请求映射为Engine中运行的代码；之后，将运行结果构建响应报文（http,asp）
    Host： 类似httpd中的虚拟主机；
    Context： 类似于httpd中的alias；
    
注意：每个组件都由“类”来实现，有些组件的实现还不止一种；

    顶级类组件：server
    服务类组件：service
    容器类组件：即可以部署webapp的组件，engine, host, context
    连接器组件：connector
    被嵌套类组件：valve, logger, realm

	<server>
		<service>
			<connector />
			<connector />
			...
			<engine>
				<host>
					<context />
					...
				</host>
				...
			</engine>
		</service>
	</server>
	
Tomcat目录结构

    bin：脚本及启动时用到的类
    lib：类库
    conf：配置文件
    logs：日志文件
    webapps：应用程序默认部署目录
    work：工作目录
    temp：临时文件目录
    
配置文件

    server.xml：主配置文件
    context.xml：每个webapp都可以有专用的配置文件，这些配置文件通常位于webapp应用应用承训目录下的WEB-INF目录中，用于定义会话管理器、JDBC等；conf/context.xml是为各webapp提供默认配置；
    web.xml：每个webapp"部署"之后才能被访问：此文件则用于为所有的webapp提供默认部署相关的配置；
    tomcat-users.xml：用户认证的帐号和密码配置文件；
    catalina.policy：当适用-security选项启动tomcat实例时会读取此配置文件来实现其安全运行策略；
    catalina.properties：Java属性的定义文件，用于设定类加载器路径等，以及一些JVM性能相关的调优参数；
    logging.properties：日志相关的配置信息；
    
Java WebAPP 组织结构:
有特定的组织形式、层次型的目录结构；主要包含了servlet代码文件、JSP页面文件、类文件、部署描述符文件等；

    /usr/local/tomcat/webapps/app1/
        /: webapp的根目录；
    	WEB-INF/：当前webapp的私有资源目录，通常存放当前webapp自用的web.xml；
        META-INF/：当前webapp的私有资源目录，通常存放当前webapp自用的context.xml；
        classes/: 此webapp的私有类；
        lib/: 此webapp的私有类，被打包为jar格式类；
        index.jsp：webapp的主页
    webapp归档格式：
        .war：webapp；
        .jar：EJB的类；
        .rar：资源适配器；
        .ear：企业级应用程序；
        
手动添加一个测试应用程序：

    1、创建webapp特有的目录结构；
        mkdir -pv myapp/{lib,classes,WEB-INF,META-INF} 
    2、提供webapp各文件；
        myapp/index.jsp
        	<%@ page language="java" %>
        	<%@ page import="java.util.*" %>
                <html>
                    <head>
                    	<title>JSP Test Page</title>
                    </head>
                    <body>
                        <% out.println("Hello, world."); %>
                    </body>
                </html>
                

自定义Host及Context示例：

     <Host name="web1.magedu.com" appBase="/data/webapps/" unpackWARs="true" autoDeploy="true">
        <Context path="" docBase="ROOT" reloadable="true">
          <Valve className="org.apache.catalina.valves.RemoteAddrValve"
                deny="172\.16\.100\.100"/>
        </Context>
        <Context path="/shop" docBase="shopxx" reloadable="true" />
          <Valve className="org.apache.catalina.valves.AccessLogValve" directory="/data/logs"
                prefix="web1_access_log" suffix=".txt"
                pattern="%h %l %u %t &quot;%r&quot; %s %b" />	 
    </Host>
    注意：path给定的路径不能以“/”结尾；
    
安装Tomcat

    [root@node1 ~]# wget http://mirrors.cnnic.cn/apache/tomcat/tomcat-8/v8.5.5/bin/apache-tomcat-8.5.5.tar.gz
    Jdk下载地址(Oracle)：http://www.oracle.com/technetwork/java/javase/downloads/index-jsp-138363.html
        [root@node1 ~]# rpm -ivh jdk-8u45-linux-x64.rpm
        [root@node1 tomcat]# vim /etc/profile.d/java.sh  \\声明环境变量
              export JAVA_HOME=/usr/java/latest
              export PATH=$JAVA_HOME/bin:$PATH
        [root@node1 tomcat]# source /etc/profile.d/java.sh      \\重载一下
        #或者安装系统自带的openjdk(yum search jdk(centos7上我找到的java-1.8.0-openjdk.x86_64))
        [root@node1 ~]# yum -y install java-1.8.0-openjdk.x86_64
    [root@node1 ~]# java -version     #两种方法，任选一种
        openjdk version "1.8.0_91"
        OpenJDK Runtime Environment (build 1.8.0_91-b14)
        OpenJDK 64-Bit Server VM (build 25.91-b14, mixed mode)
    [root@node1 ~]# tar xf apache-tomcat-8.5.5.tar.gz -C /usr/local
    [root@node1 ~]# cd /usr/local
    [root@node1 local]# ln -sv apache-tomcat-8.5.5/ tomcat
    ‘tomcat’ -> ‘apache-tomcat-8.5.5/’
    [root@node1 bin]# vim /etc/profile.d/tomcat.sh   \\导出tomcat环境变量
        export CATALINA_HOME=/usr/local/tomcat
        export PATH=$CATALINA_HOME/bin:$PATH
    [root@node1 bin]# source /etc/profile.d/tomcat.sh   \\重载
    [root@node1 bin]# catalina.sh start   \\启动
        Using CATALINA_BASE:   /usr/local/tomcat
        Using CATALINA_HOME:   /usr/local/tomcat
        Using CATALINA_TMPDIR: /usr/local/tomcat/temp
        Using JRE_HOME:        /usr
        Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
        Tomcat started.

测试一下

    [root@node1 ~]# curl -I http://localhost:8080
    HTTP/1.1 200 
    Content-Type: text/html;charset=UTF-8
    Transfer-Encoding: chunked
    Date: Wed, 14 Sep 2016 09:10:55 GMT


如何进入Tomcat manager页面
现在我们搭建了最基础的tomcat服务器, 上面没有跑我们的JSP脚本, 是tomcat提供的一个manual页面, 页面的左上方有几个图形界面的管理界面server status,manager app, Host manager, 我们需要提供用户名和密码才能进入并配置它们;

     # vim /usr/local/tomcat/conf/tomcat-users.xml   \\在文件倒数第二行加入下面内容
        <role rolename="admin-gui"/>
        <role rolename="manager-gui"/>
        <user username="bjwf" password="passwd"    roles="admin-gui,manager-gui"/>

