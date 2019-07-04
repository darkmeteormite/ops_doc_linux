mysqldiff 顾名思义就是来diff比较的，相当于Linux下的diff命令。mysqldiff 用来比较对象的定义是否相同并显示不同的地方，mysqldiff 是通过对象名称来进行比较的。如果要比较数据是否一致，那就要用到mysqldbcompare了，参见前面文章。
当指定了数据库对，所有的对象就要进行比较。如果其中某个库中出现的对象在另一个库中没有出现，将报错。信息如下所示：
# WARNING: Objects in server2.ttlsa_com but not in server1.ttlsa_com:
# TABLE: t
Compare failed. One or more differences found.
如果要比较特定对象，使用db.obj 格式。db1.obj1:db2 和db1:db2.obj2 这样类型的格式是非法的。报错信息如下所示：
mysqldiff: error: Incorrect object compare argument, one specific object is missing. Please verify that both object are correctly specified. No object has been specified for db1 'ttlsa_com', while object 't' was specified for db2 'ttlsa_com'. Format should be: db1[.object1]:db2[.object2].
比较同一实例上的不同数据库只需要指定--server1，不同的实例的话还需要指定--server2。 在这种情况下，数据库对左边的对象来自server1，右边的对象来自server2。
执行完后，会生成一个差异报告。也可以生成一个转换的SQL语句报告来更改使两者相同。
输出类型，也就是difftype选项值：

unified (默认)显示统一的格式输出.
context以上下文格式输出
differ以differ-style 格式输出.
sql以生成转换SQL语句输出.
要对两物进行比较，就需要参照物。参照物可以任意选定，可以选server1，也可以选server2，选择不同的参照物来描述同一物体的状态，可能得出的结论不同。“小小竹排江中游，巍巍青山两岸走” 一样的道理不是么？
--changes-for选项来控制对比方向。默认是以server1。同时显示，可以使用--show-reverse选项。
--changes-for=server1： 以server2为参照物，针对server1
--changes-for=server2：以server1为参照物，针对server2

$ mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --show-reverse -vvv
    # server1 on localhost: ... connected.
    # server2 on localhost: ... connected.

    # Definition for object ttlsa_com:
    CREATE DATABASE `ttlsa_com` /*!40100 DEFAULT CHARACTER SET latin1 */

    # Definition for object ttlsa_com:
    CREATE DATABASE `ttlsa_com` /*!40100 DEFAULT CHARACTER SET latin1 */
    # Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]

    # Definition for object ttlsa_com.bbs_categories:
    CREATE TABLE `bbs_categories` (
      `cid` smallint(5) NOT NULL AUTO_INCREMENT,
      `pid` smallint(5) NOT NULL DEFAULT '0',
      `cname` varchar(30) DEFAULT NULL COMMENT '分类名称',
      `content` varchar(255) DEFAULT NULL,
      `keywords` varchar(255) DEFAULT NULL,
      `ico` varchar(128) DEFAULT NULL,
      `master` varchar(100) NOT NULL,
      `permit` varchar(255) DEFAULT NULL,
      `listnum` mediumint(8) unsigned DEFAULT '0',
      `clevel` varchar(25) DEFAULT NULL,
      `cord` smallint(6) DEFAULT NULL,
      PRIMARY KEY (`cid`,`pid`)
    ) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8

    Compare failed. One or more differences found.

$ mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --show-reverse -vvv
    # server1 on localhost: ... connected.
    # server2 on localhost: ... connected.
     
    # Definition for object ttlsa_com:
    CREATE DATABASE `ttlsa_com` /*!40100 DEFAULT CHARACTER SET latin1 */
     
    # Definition for object ttlsa_com:
    CREATE DATABASE `ttlsa_com` /*!40100 DEFAULT CHARACTER SET latin1 */
    # Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
     
    # Definition for object ttlsa_com.bbs_categories:
    CREATE TABLE `bbs_categories` (
      `cid` smallint(5) NOT NULL AUTO_INCREMENT,
      `pid` smallint(5) NOT NULL DEFAULT '0',
      `cname` varchar(30) DEFAULT NULL COMMENT '分类名称',
      `content` varchar(255) DEFAULT NULL,
      `keywords` varchar(255) DEFAULT NULL,
      `ico` varchar(128) DEFAULT NULL,
      `master` varchar(100) NOT NULL,
      `permit` varchar(255) DEFAULT NULL,
      `listnum` mediumint(8) unsigned DEFAULT '0',
      `clevel` varchar(25) DEFAULT NULL,
      `cord` smallint(6) DEFAULT NULL,
      PRIMARY KEY (`cid`,`pid`)
    ) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8
     
    Compare failed. One or more differences found.

选项：

Usage: mysqldiff --server1=user:pass@host:port:socket --server2=user:pass@host:port:socket db1.object1:db2.object1 db3:db4

mysqldiff - compare object definitions among objects where the difference is
how db1.obj1 differs from db2.obj2

Options:
  --version             show program's version number and exit
  --help                display a help message and exit
  --license             display program's license and exit
  --ssl-ca=SSL_CA       The path to a file that contains a list of trusted SSL
                        CAs.
  --ssl-cert=SSL_CERT   The name of the SSL certificate file to use for
                        establishing a secure connection.
  --ssl-key=SSL_KEY     The name of the SSL key file to use for establishing a
                        secure connection.
  --server1=SERVER1     connection information for first server in the form:
                        <user>[:<password>]@<host>[:<port>][:<socket>] or
                        <login-path>[:<port>][:<socket>] or <config-
                        path>[<[group]>].
  --server2=SERVER2     connection information for second server in the form:
                        <user>[:<password>]@<host>[:<port>][:<socket>] or
                        <login-path>[:<port>][:<socket>] or <config-
                        path>[<[group]>].
  --character-set=CHARSET
                        sets the client character set. The default is
                        retrieved from the server variable
                        'character_set_client'.
  --width=WIDTH         display width
  --force               do not abort when a diff test fails
  -c, --compact         compact output from a diff.
  --skip-table-options  skip check of all table options (e.g., AUTO_INCREMENT,
                        ENGINE, CHARSET, etc.).
  -v, --verbose         control how much information is displayed. e.g., -v =
                        verbose, -vv = more verbose, -vvv = debug
  -q, --quiet           turn off all messages for quiet execution.
  -d DIFFTYPE, --difftype=DIFFTYPE
                        display differences in context format in one of the
                        following formats: [unified|context|differ|sql]
                        (default: unified).
  --changes-for=CHANGES_FOR
                        specify the server to show transformations to match
                        the other server. For example, to see the
                        transformation for transforming server1 to match
                        server2, use --changes-for=server1. Valid values are
                        'server1' or 'server2'. The default is 'server1'.
  --show-reverse        produce a transformation report containing the SQL
                        statements to transform the object definitions
                        specified in reverse. For example if --changes-for is
                        set to server1, also generate the transformation for
                        server2. Note: the reverse changes are annotated and
                        marked as comments.

Usage: mysqldiff --server1=user:pass@host:port:socket --server2=user:pass@host:port:socket db1.object1:db2.object1 db3:db4
 
mysqldiff - compare object definitions among objects where the difference is
how db1.obj1 differs from db2.obj2
 
Options:
  --version             show program's version number and exit
  --help                display a help message and exit
  --license             display program's license and exit
  --ssl-ca=SSL_CA       The path to a file that contains a list of trusted SSL
                        CAs.
  --ssl-cert=SSL_CERT   The name of the SSL certificate file to use for
                        establishing a secure connection.
  --ssl-key=SSL_KEY     The name of the SSL key file to use for establishing a
                        secure connection.
  --server1=SERVER1     connection information for first server in the form:
                        <user>[:<password>]@<host>[:<port>][:<socket>] or
                        <login-path>[:<port>][:<socket>] or <config-
                        path>[<[group]>].
  --server2=SERVER2     connection information for second server in the form:
                        <user>[:<password>]@<host>[:<port>][:<socket>] or
                        <login-path>[:<port>][:<socket>] or <config-
                        path>[<[group]>].
  --character-set=CHARSET
                        sets the client character set. The default is
                        retrieved from the server variable
                        'character_set_client'.
  --width=WIDTH         display width
  --force               do not abort when a diff test fails
  -c, --compact         compact output from a diff.
  --skip-table-options  skip check of all table options (e.g., AUTO_INCREMENT,
                        ENGINE, CHARSET, etc.).
  -v, --verbose         control how much information is displayed. e.g., -v =
                        verbose, -vv = more verbose, -vvv = debug
  -q, --quiet           turn off all messages for quiet execution.
  -d DIFFTYPE, --difftype=DIFFTYPE
                        display differences in context format in one of the
                        following formats: [unified|context|differ|sql]
                        (default: unified).
  --changes-for=CHANGES_FOR
                        specify the server to show transformations to match
                        the other server. For example, to see the
                        transformation for transforming server1 to match
                        server2, use --changes-for=server1. Valid values are
                        'server1' or 'server2'. The default is 'server1'.
  --show-reverse        produce a transformation report containing the SQL
                        statements to transform the object definitions
                        specified in reverse. For example if --changes-for is
                        set to server1, also generate the transformation for
                        server2. Note: the reverse changes are annotated and
                        marked as comments.
以SQL输出的限制有：

对于分区表，如果分区表有差异，将对所有的改变生产 ALTER TABLE 语句，显示经过并省略分区差异。
事件重命名不支持。
不支持事务定义的条款。
不支持MySQL Cluster 的SQL扩展特性。
实例：


# mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com
# server1 on localhost: ... connected.
# server2 on localhost: ... connected.
# Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
# Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
# Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
# Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
# Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
# Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
# Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
# Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
# Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
# Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
# Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
# Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
# Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
# Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
# Object definitions differ. (--changes-for=server1)
#

--- `ttlsa_com`.`t_data`
+++ `ttlsa_com`.`t_data`
@@ -4,4 +4,4 @@
   `count` int(11) DEFAULT NULL,
   PRIMARY KEY (`value`),
   KEY `id` (`id`)
-) ENGINE=InnoDB DEFAULT CHARSET=latin1
+) ENGINE=MyISAM DEFAULT CHARSET=latin1
Compare failed. One or more differences found.

# mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com
# server1 on localhost: ... connected.
# server2 on localhost: ... connected.
# Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
# Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
# Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
# Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
# Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
# Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
# Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
# Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
# Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
# Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
# Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
# Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
# Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
# Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
# Object definitions differ. (--changes-for=server1)
#
 
--- `ttlsa_com`.`t_data`
+++ `ttlsa_com`.`t_data`
@@ -4,4 +4,4 @@
   `count` int(11) DEFAULT NULL,
   PRIMARY KEY (`value`),
   KEY `id` (`id`)
-) ENGINE=InnoDB DEFAULT CHARSET=latin1
+) ENGINE=MyISAM DEFAULT CHARSET=latin1
Compare failed. One or more differences found.

#  mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --changes-for=server1
# server1 on localhost: ... connected.
# server2 on localhost: ... connected.
# Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
# Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
# Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
# Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
# Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
# Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
# Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
# Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
# Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
# Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
# Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
# Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
# Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
# Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
# Transformation for --changes-for=server1:
#

ALTER TABLE `ttlsa_com`.`t_data` 
  DROP INDEX id, 
  ADD INDEX id (id), 
ENGINE=MyISAM;

Compare failed. One or more differences found.

#  mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --changes-for=server1
# server1 on localhost: ... connected.
# server2 on localhost: ... connected.
# Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
# Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
# Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
# Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
# Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
# Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
# Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
# Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
# Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
# Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
# Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
# Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
# Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
# Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
# Transformation for --changes-for=server1:
#
 
ALTER TABLE `ttlsa_com`.`t_data` 
  DROP INDEX id, 
  ADD INDEX id (id), 
ENGINE=MyISAM;
 
Compare failed. One or more differences found.

#  mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --changes-for=server2
# server1 on localhost: ... connected.
# server2 on localhost: ... connected.
# Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
# Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
# Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
# Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
# Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
# Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
# Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
# Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
# Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
# Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
# Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
# Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
# Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
# Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
# Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
# Transformation for --changes-for=server2:
#

ALTER TABLE `ttlsa_com`.`t_data` 
  DROP INDEX id, 
  ADD INDEX id (id), 
ENGINE=InnoDB;

Compare failed. One or more differences found.

$ mysqldiff --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com --difftype=sql --changes-for=server2
    # server1 on localhost: ... connected.
    # server2 on localhost: ... connected.
    # Comparing `ttlsa_com` to `ttlsa_com`                             [PASS]
    # Comparing `ttlsa_com`.`bbs_categories` to `ttlsa_com`.`bbs_categories`   [PASS]
    # Comparing `ttlsa_com`.`bbs_comments` to `ttlsa_com`.`bbs_comments`   [PASS]
    # Comparing `ttlsa_com`.`bbs_favorites` to `ttlsa_com`.`bbs_favorites`   [PASS]
    # Comparing `ttlsa_com`.`bbs_forums` to `ttlsa_com`.`bbs_forums`   [PASS]
    # Comparing `ttlsa_com`.`bbs_links` to `ttlsa_com`.`bbs_links`     [PASS]
    # Comparing `ttlsa_com`.`bbs_notifications` to `ttlsa_com`.`bbs_notifications`   [PASS]
    # Comparing `ttlsa_com`.`bbs_page` to `ttlsa_com`.`bbs_page`       [PASS]
    # Comparing `ttlsa_com`.`bbs_settings` to `ttlsa_com`.`bbs_settings`   [PASS]
    # Comparing `ttlsa_com`.`bbs_tags` to `ttlsa_com`.`bbs_tags`       [PASS]
    # Comparing `ttlsa_com`.`bbs_tags_relation` to `ttlsa_com`.`bbs_tags_relation`   [PASS]
    # Comparing `ttlsa_com`.`bbs_user_follow` to `ttlsa_com`.`bbs_user_follow`   [PASS]
    # Comparing `ttlsa_com`.`bbs_user_groups` to `ttlsa_com`.`bbs_user_groups`   [PASS]
    # Comparing `ttlsa_com`.`bbs_users` to `ttlsa_com`.`bbs_users`     [PASS]
    # Comparing `ttlsa_com`.`data` to `ttlsa_com`.`data`               [PASS]
    # Comparing `ttlsa_com`.`t_data` to `ttlsa_com`.`t_data`           [FAIL]
    # Transformation for --changes-for=server2:
    #
     
    ALTER TABLE `ttlsa_com`.`t_data` 
      DROP INDEX id, 
      ADD INDEX id (id), 
    ENGINE=InnoDB;
     
    Compare failed. One or more differences found.

$ mysqldbcompare --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com  --show-reverse  --run-all-tests -vv
    # server1 on localhost: ... connected.
    # server2 on localhost: ... connected.
    # Checking databases ttlsa_com on server1 and ttlsa_com on server2
    #
    Looking for object types table, view, trigger, procedure, function, and event.
    Object types found common to both databases:
         FUNCTION : 0
          TRIGGER : 0
            TABLE : 15
            EVENT : 0
        PROCEDURE : 0
             VIEW : 0
    #                                                   Defn    Row     Data   
    # Type      Object Name                             Diff    Count   Check  
    # ------------------------------------------------------------------------- 
    # TABLE     bbs_categories                          pass    pass    -       
    #           - Compare table checksum                                pass    
    #           - Compare table checksum                                pass   

    # Definition for object ttlsa_com.bbs_categories:
    CREATE TABLE `bbs_categories` (
      `cid` smallint(5) NOT NULL AUTO_INCREMENT,
      `pid` smallint(5) NOT NULL DEFAULT '0',
      `cname` varchar(30) DEFAULT NULL COMMENT '分类名称',
      `content` varchar(255) DEFAULT NULL,
      `keywords` varchar(255) DEFAULT NULL,
      `ico` varchar(128) DEFAULT NULL,
      `master` varchar(100) NOT NULL,
      `permit` varchar(255) DEFAULT NULL,
      `listnum` mediumint(8) unsigned DEFAULT '0',
      `clevel` varchar(25) DEFAULT NULL,
      `cord` smallint(6) DEFAULT NULL,
      PRIMARY KEY (`cid`,`pid`)
    ) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8


    # Database consistency check failed.
    #
    # ...done

$ mysqldbcompare --server1=instance_3306 --server2=instance_3308  ttlsa_com:ttlsa_com  --show-reverse  --run-all-tests -vv
    # server1 on localhost: ... connected.
    # server2 on localhost: ... connected.
    # Checking databases ttlsa_com on server1 and ttlsa_com on server2
    #
    Looking for object types table, view, trigger, procedure, function, and event.
    Object types found common to both databases:
         FUNCTION : 0
          TRIGGER : 0
            TABLE : 15
            EVENT : 0
        PROCEDURE : 0
             VIEW : 0
    #                                                   Defn    Row     Data   
    # Type      Object Name                             Diff    Count   Check  
    # ------------------------------------------------------------------------- 
    # TABLE     bbs_categories                          pass    pass    -       
    #           - Compare table checksum                                pass    
    #           - Compare table checksum                                pass   
     
    # Definition for object ttlsa_com.bbs_categories:
    CREATE TABLE `bbs_categories` (
      `cid` smallint(5) NOT NULL AUTO_INCREMENT,
      `pid` smallint(5) NOT NULL DEFAULT '0',
      `cname` varchar(30) DEFAULT NULL COMMENT '分类名称',
      `content` varchar(255) DEFAULT NULL,
      `keywords` varchar(255) DEFAULT NULL,
      `ico` varchar(128) DEFAULT NULL,
      `master` varchar(100) NOT NULL,
      `permit` varchar(255) DEFAULT NULL,
      `listnum` mediumint(8) unsigned DEFAULT '0',
      `clevel` varchar(25) DEFAULT NULL,
      `cord` smallint(6) DEFAULT NULL,
      PRIMARY KEY (`cid`,`pid`)
    ) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8
     
     
    # Database consistency check failed.
    #
    # ...done
权限：

对两者对象要有SELECT 权限，同时，还需要对mysql数据库有SELECT权限。