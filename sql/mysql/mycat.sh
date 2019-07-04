
 STATEMENT                                 DESCRIPTION                                                说明                                                     

 show @@time.current                       Report current timestamp                    查看现在时间
 show @@time.startup                       Report startup timestamp                    查看启动时间
 show @@version                            Report Mycat Server version                 获取mycat版本
 show @@server                             Report server status                        查看mycat状态信息
 show @@threadpool                         Report threadPool status                    查看线程池状态
 show @@database                           Report databases                            显示mycat数据库列表
 show @@datanode                           Report dataNodes                            显示mycat数据节点列表
 show @@datanode where schema = ?          Report dataNodes                            显示数据库节点数据分布情况
 show @@datasource                         Report dataSources                          查看数据源的状态，如果配置了主从或者多主，则可以切换。
 show @@datasource where dataNode = ?      Report dataSources                          查看数据节点具体信息
 show @@datasource.synstatus               Report datasource data synchronous         
 show @@datasource.syndetail where name=?  Report datasource data synchronous detail  
 show @@datasource.cluster                 Report datasource galary cluster variables 
 show @@processor                          Report processor status                     查看线程状态，主要用于指定系统可用的线程数
 show @@command                            Report commands status                      查看进程执行过多少次命令
 show @@connection                         Report connection status                    获取mycat前端连接状态，即应用于mycat的连接
 show @@cache                              Report system cache usage                   查看mycat的缓存
 show @@backend                            Report backend connection status            查看后端的连接状态
 show @@session                            Report front session details                查看session信息
 show @@connection.sql                     Report connection sql                      
 show @@sql.execute                        Report execute status                       查看执行状态
 show @@sql.detail where id = ?            Report execute detail status               
 show @@sql                                Report SQL list                             显示在mycat中执行过的SQL
 show @@sql.high                           Report Hight Frequency SQL                  
 show @@sql.slow                           Report slow SQL                             显示慢SQL
 show @@sql.resultset                      Report BIG RESULTSET SQL                   
 show @@sql.sum                            Report  User RW Stat                        显示SQL执行的整体情况，读写比例等。
 show @@sql.sum.user                       Report  User RW Stat                       
 show @@sql.sum.table                      Report  Table RW Stat                      
 show @@parser                             Report parser status                        显示分析
 show @@router                             Report router status                       
 show @@heartbeat                          Report heartbeat status                     报告心跳状态
 show @@heartbeat.detail where name=?      Report heartbeat current detail            
 show @@slow where schema = ?              Report schema slow sql                     
 show @@slow where datanode = ?            Report datanode slow sql                   
 show @@sysparam                           Report system param                         查看系统指令
 show @@syslog limit=?                     Report system mycat.log                     用于显示系统日志
 show @@white                              show mycat white host                      
 show @@white.set=?,?                      set mycat white host,[ip,user]             
 show @@directmemory=1 or 2                show mycat direct memory usage              显示mycat的直接内存使用情况。
 switch @@datasource name:index            Switch dataSource                           用于切换数据源，执行过程中，mycat不可用
        name：schema中配置的dataHost中的name
        index：schema中配置的dataHost中的writeHost index的坐标，即按照从上到下的配置顺序，从0开始。
 kill @@connection id1,id2,...             Kill the specified connections              强制关闭mycat的连接
 stop @@heartbeat name:time                Pause dataNode heartbeat                    暂停dataNode的心跳
 reload @@config                           Reload basic config from file               更新配置文件
 reload @@config_all                       Reload all config from file                 重新加载所有配置文件
 reload @@route                            Reload route config from file               从文件中重新加载路由配置
 reload @@user                             Reload user config from file                从文件中重新加载用户配置
 reload @@sqlslow=                         Set Slow SQL Time(ms)                       开启慢SQL时间阀值
 reload @@user_stat                        Reset show @@sql  @@sql.sum @@sql.slow      重置SQL监控分析的数据，用于清除缓存
 rollback @@config                         Rollback all config from memory             从内存中回滚所有配置
 rollback @@route                          Rollback route config from memory           从内存中回滚路由配置
 rollback @@user                           Rollback user config from memory            从内存中回滚用户配置
 reload @@sqlstat=open                     Open real-time sql stat analyzer            开启SQL监控分析功能
 reload @@sqlstat=close                    Close real-time sql stat analyzer           关闭SQL监控分析功能
 offline                                   Change MyCat status to OFF                  改变mycat状态为OFF（还能连，不知道什么情况）
 online                                    Change MyCat status to ON                   改变mycat状态为ON
 clear @@slow where schema = ?             Clear slow sql by schema                    清除schema中的慢SQL
 clear @@slow where datanode = ?           Clear slow sql by datanode                  清除datanode中的慢SQL
