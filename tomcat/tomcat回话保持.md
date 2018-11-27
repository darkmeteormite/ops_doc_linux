Tomcat Cluster(3)
	
	会话保持：
		session sticky
			source ip
			cookie
		session cluster: 
		session server
			kv: memcached, redis

	(1) LB tomcat
		nginx tomcats
		apache tomcats
	(2) LB tomcat cluster
	(3) LB tomcat 
		session server
			memcached


	apache: tomcats
		(1) apache: 
				mod_proxy
				mod_proxy_http
				mod_proxy_balancer
			tomcat:
				http connector
		(2) apache: 
				mod_proxy
				mod_proxy_ajp
				mod_proxy_balancer				
			tomcat:
				ajp connector
		(3) apache:
				mod_jk
			tomcat:
				ajp connector

	第一种方法的实现：
		<proxy balancer://lbcluster1>
		    BalancerMember http://172.16.100.68:8080 loadfactor=10 route=TomcatA
		    BalancerMember http://172.16.100.69:8080 loadfactor=10 route=TomcatB
		</proxy>

		<VirtualHost *:80>
		    ServerName web1.magedu.com
		    ProxyVia On
		    ProxyRequests Off
		    ProxyPreserveHost On
		    <Proxy *>
		        Require all granted
		    </Proxy>
		    ProxyPass / balancer://lbcluster1/
		    ProxyPassReverse / balancer://lbcluster1/
		    <Location />
		        Require all granted
		    </Location>
		</VirtualHost>


		如果需要会话绑定：
			Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
			<proxy balancer://lbcluster1>
			    BalancerMember http://172.16.100.68:8080 loadfactor=10 route=TomcatA
			    BalancerMember http://172.16.100.69:8080 loadfactor=10 route=TomcatB
			    ProxySet stickysession=ROUTEID
			</proxy>

			<VirtualHost *:80>
			    ServerName web1.magedu.com
			    ProxyVia On
			    ProxyRequests Off
			    ProxyPreserveHost On
			    <Proxy *>
			        Require all granted
			    </Proxy>
			    ProxyPass / balancer://lbcluster1/
			    ProxyPassReverse / balancer://lbcluster1/
			    <Location />
			        Require all granted
			    </Location>
			</VirtualHost>		

	第二种方法的实现：
		#Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
		<proxy balancer://lbcluster1>
		    BalancerMember ajp://172.16.100.68:8009 loadfactor=10 route=TomcatA
		    BalancerMember ajp://172.16.100.69:8009 loadfactor=10 route=TomcatB
		    ProxySet stickysession=ROUTEID
		</proxy>

		<VirtualHost *:80>
		    ServerName web1.magedu.com
		    ProxyVia On
		    ProxyRequests Off
		    ProxyPreserveHost On
		    <Proxy *>
		        Require all granted
		    </Proxy>
		    ProxyPass / balancer://lbcluster1/
		    ProxyPassReverse / balancer://lbcluster1/
		    <Location />
		        Require all granted
		    </Location>
		</VirtualHost>

	补充:mod_proxy_balancer模块内置的manager：
		<Location /balancer-manager>
		  SetHandler balancer-manager
		  Proxypass !
		  Order Deny,Allow
		  Allow from all
		</Location>	

	第三种方式：
		mod_jk：额外编译安装

		(1) 反向代理
			模块配置文件：mod_jk.conf 
				LoadModule  jk_module  modules/mod_jk.so
				JkWorkersFile  /etc/httpd/conf.d/workers.properties
				JkLogFile  logs/mod_jk.log
				JkLogLevel  debug
				JkMount  /*  TomcatA
				JkMount  /status/  stat1

			workers配置文件：workers.properties
				worker.list=TomcatA,stat1
				worker.TomcatA.port=8009
				worker.TomcatA.host=172.16.100.68
				worker.TomcatA.type=ajp13
				worker.TomcatA.lbfactor=1
				worker.stat1.type = status

			注意：status的访问要做访问控制；

		(2) 负载均衡
			模块配置文件：mod_jk.conf
				LoadModule  jk_module  modules/mod_jk.so
				JkWorkersFile  /etc/httpd/conf.d/workers.properties
				JkLogFile  logs/mod_jk.log
				JkLogLevel  debug
				JkMount  /*  lbcluster1
				JkMount  /status/  stat1

			workers配置文件：workers.properties
				worker.list = lbcluster1,stat1
				worker.TomcatA.type = ajp13
				worker.TomcatA.host = 172.16.100.68
				worker.TomcatA.port = 8009
				worker.TomcatA.lbfactor = 1
				worker.TomcatB.type = ajp13
				worker.TomcatB.host = 172.16.100.69
				worker.TomcatB.port = 8009
				worker.TomcatB.lbfactor = 1
				worker.lbcluster1.type = lb
				worker.lbcluster1.sticky_session = 0
				worker.lbcluster1.balance_workers = TomcatA, TomcatB
				worker.stat1.type = status	

	Session Cluster：

		session manager：会话管理器

			StandardManager
			PersistentManager：
				FileStore
				JDBC
			DeltaManager
			BackupManager

		构建步骤：
			(1) 各节点配置使用deltamaanager：
        <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"
                 channelSendOptions="8">

          <Manager className="org.apache.catalina.ha.session.DeltaManager"
                   expireSessionsOnShutdown="false"
                   notifyListenersOnReplication="true"/>

          <Channel className="org.apache.catalina.tribes.group.GroupChannel">
            <Membership className="org.apache.catalina.tribes.membership.McastService"
                        address="228.0.1.7"
                        port="45564"
                        frequency="500"
                        dropTime="3000"/>
            <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"
                      address="auto"
                      port="4000"
                      autoBind="100"
                      selectorTimeout="5000"
                      maxThreads="6"/>

            <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
              <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
            </Sender>
            <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
            <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatch15Interceptor"/>
          </Channel>

          <Valve className="org.apache.catalina.ha.tcp.ReplicationValve"
                 filter=""/>
          <Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve"/>

          <Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer"
                    tempDir="/tmp/war-temp/"
                    deployDir="/tmp/war-deploy/"
                    watchDir="/tmp/war-listen/"
                    watchEnabled="false"/>

          <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
        </Cluster>

        (2) 为需要使用session cluster的webapps开启session distribution的功能：
        	WEB-INF/web.xml中添加
        		<distributable/>
