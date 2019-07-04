#备份数据库
pg_dump -p 20004 -h test2 -d test1  -f test2.sql

#恢复数据库
psql -p 20004 -d test1 -f test2.sql

#备份所有数据库
pg_dumpall -p 20004 -h test2  -f test2.sql