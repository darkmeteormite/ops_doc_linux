SQL MODE：定义mysqld对约束等得响应行为
	修改方式：
		mysql>  SET GLOBAL sql_mode='MODE';
		mysql>  SET @@global.sql_mode='MODE';
		需要修改权限：仅对修改后新创建的会话有效；对已经建立的会话无效；
		mysql>  SET SESSION sql_mode='MODE';
		mysql>  SET @@session.sql_mode='MODE';
	查询：
		mysql > SHOW GLOBAL VARIABLES LIKE 'sql_mode';
		mysql > SHOW GLOBAL VARIABLES LIKE 'sql_%';
		mysql > SHOW VARIABLES LIKE 'sql_mode';

	常用MODE：TRADITIONAL，STRICT_TRANS_TABLES, or STRICT_ALL_TABLES