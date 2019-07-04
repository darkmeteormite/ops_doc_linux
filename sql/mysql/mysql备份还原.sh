一、备份
$ sudo mysqldump -uroot  --master-data=2 --single-transaction --all-databases --socket=/data/mysql/mysql.sock >all.sql
二、恢复
$ mysql < all.sql
CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000600', MASTER_LOG_POS=606032919;




--single-transaction
用于保证innodb备份数据一致性，配合RR隔离级别使用；当发起事务，读取一个快照版本，直到备份结束时，都不会读取到本事务开始之后提交的数据；（很重要）
 
-q, --quick
加 SQL_NO_CACHE 标示符来确保不会读取缓存里的数据-l
  
--lock-tables
发起 READ LOCAL LOCK锁，该锁不会阻止读，也不会阻止新的数据插入
 
--master-data
两个值 1和2,如果值等于1，就会添加一个CHANGE MASTER语句（后期配置搭建主从架构）
如果值等于2，就会在CHANGE MASTER语句前添加注释（后期配置搭建主从架构）
  
-c, --complete-insert；
导出完整sql语句
 
-d，--no-data；
不导出数据，只导表结构
  
-t，--no-create-info；
只导数据，不导表结构
  
-w, --where=name ；
按条件导出想要的数据