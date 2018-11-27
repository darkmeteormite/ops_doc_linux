# /etc/my.cnf
    
    [mysql]
    
    # CLIENT #
    port = 3306
    socket = /data/mysql/mysql.sock
    
    [mysqld]
    
    # GENERAL #
    user = mysql
    default-storage-engine = InnoDB    	#设置默认存储引擎
    socket = /data/mysql/mysql.socket 	#套接字路径
    pid-file = /data/mysql/mysql.pid 	#pid文件位置
    
    # MyISAM #
    key-buffer-size = 32M
    myisam-recover = FORCE,BACKUP
    
    # SAFETY #
    max-allowed-packet = 16M 			#发送最大包得值，默认值为1M
    max-connect-errors = 1000000 		#默认值为10，客户端尝试连接此mysql服务器，但是失败(如密码错误等等)1000000次，则mysql会无条件强制阻止此客户端连接，防止暴力破解密码
    # max_connections = 2000 						#最大连接数目，mysql会保留一个管理员的连接，所有最大连接数目实际为max_connections+1，该变量的最大值为16384，增加这个参数的值不会太占用系统的资源
    skip-name-resolve
    # sql-mode  = STRICT-TRANS-TABLES,ERROR-FOR-DIVISION-BY-ZERO,NO-AUTO-CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ONLY_FULL_GROUP_BY
    sysdate-is-now = 1
    innodb = FORCE
    innodb-strict-mode = 1
    
    # DATA STORAGE #
    datadir  = /data/mysql/
    
    # BINARY LOGGING #
    log-bin = /data/mysql/mysql-bin
    expire-logs-days = 7
    sync-binlog = 0
    
    # CACHES AND LIMITS #
    tmp-table-size = 32M  #当我们进行一些特殊操作如需要使用临时表才能完成的Order By,Group By等等，Mysql可能需要使用到临时表，太小的话，临时表就只能写到硬盘上了。
    max-heap-table-size = 32M  #这个变量定义了用户可以创建的内存表(memory table)的大小，这个值用来计算内存表的最大行数值。
    #这个变量支持动态改变，即set @max_h
    query-cache-type = 0
    query-cache-size               = 0
    max-connections                = 1000
    thread-cache-size              = 100
    open-files-limit               = 65535
    table-definition-cache         = 4096
    table-open-cache               = 1000  #限制缓存表的最大数目，默认值为64
    
    # INNODB #
    innodb-flush-method            = O_DIRECT
    innodb-log-files-in-group      = 2
    innodb-log-file-size           = 1G
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = 2G
    innodb_additional_mem_pool_size = 16M
    innodb_flush_log_at_trx_commit = 0
    innodb_max_dirty_pages_pct = 90
    
    # LOGGING #
    log-error                      = /data/mysql/mysql-error.log
    log-queries-not-using-indexes  = 0
    slow-query-log                 = 1
    slow-query-log-file            = /data/mysql/mysql-slow.log
    long_query_time                = 1
    
    back-log = 256
    wait-timeout = 7200
    sort-buffer-size = 1M
    join-buffer-size = 2M
    
    server_id                     = 34
    # relay-log                     = mysql-relay-bin
    # log-slave-updates             = 1
    # read-only                     = 1
    #slave-skip-errors             = all
    
    # TMPDIR
    tmpdir = /data/mysql/tmp
    
    # SECURITY
    local-infile = 0
    
    
    
    
    [xtrabackup]
    target_dir = /data/backup/mysql
