大纲
一、grep分类
       –1.1基本定义
       –1.2常用选项
       –1.3不常用选项
二、正则表达式
       –2.1基本定义
       –2.2正则表达式
              –2.2.1基本正则表达式
              –2.2.2扩展正则表达式
              –2.2.3快速正则表达式
三、案例分析
       –3.1grep选项案例
       –3.2正则表达式安全
              –3.2.1基本正则表达式案例
              –3.2.2扩展正则表达式案例

              –3.2.3快速正则表达式案例

一、grep分类


1.1、基本定义：
      grep（Global search regular expression and print out theline)，全面搜索正则表达式并打印出来。
      是一种很强大的文本搜索工具，并把相匹配的行打印出来。grep在查找一个字符串时，是以整行为单位
      进行数据筛选的。
 
      egrep：相当于grep -E，利用此命令可使用扩展的正则表达式来搜索筛选文本。
 
      fgrep：相当于grep -F，不支持正则表达式

1.2、常用选项：
-E:扩展正则表达式，相当于egrep
-F:固定字符串列表，相当于fgrep
-G:基本正则表达式，默认
 
-n:标识匹配“搜索字符串”行号
-i:忽略大小写
-y：同-i，忽略大小写
-v:反相匹配
-w:完整匹配文字和数字字符
-c:计算匹配“搜索的字符串”的行数
-o:仅打印匹配到的字符串
-A NUM：除了显示匹配行外，并显示匹配行后的指定数量 NUM 行
-B NUM：除了显示匹配行外，并显示匹配行前的指定数量 NUM 行
-C NUM: 除了显示匹配行外，并显示匹配行前后的指定数量 NUM 行
--color=auto:与“搜索字符串”匹配的字符串着色显色
--help：帮助信息

1.3、不常用选项：
-x:完整行匹配
-l:--files-with-matches  只打印包含匹配字符串的文件名 
-L:--files-without-match 只打印不包含匹配字符串的文件名
-f:从文件中提取模板,空文件中包含0个模板，所以什么都不匹配
-e:指定范本文件，其内容含有一个或多个范本样式，让grep查找符合范本条件的文件内容
-q:安静模式，不打印任何标准输出,如果有匹配的内容则立即返回状态值0
-s:不显示不存在或无匹配文本的错误信息。
-H:在每个匹配的行前显示绝对路径文件名，如果存在多个搜索文件，则默认存在-H功能
-h:匹配的行前不显示绝对路径文件名，默认存在于单个搜索文件前提下
-b:显示在每一行输出前的输入字节的偏移量
-m NUM:在找到指定数量 NUM 的匹配行后停止读文件
-a, --text：将二进制文件当作文本处理
-R, -r, --recursive：递归
二、正则表达式


2.1、基本定义：
正则表达式，又称正规表示法、常规表示法(Regular Expression),常简称为RE；RE就是处理字串的方法，通过
一些特殊符号的辅助来实现对文本搜索、删除、替换的目的。grep、vim、awk、sed等都支持RE。

2.2、正则表达式
2.2.1、基本正则表达式
a）锚定符
^ :行首锚定符   
$ :行尾锚定符   
\<:词首锚定符   
\>:词尾锚定符   
\b:位于词首前相当于\<；位于词尾后，相当于\> 
^$:匹配空白行
 
b）字符、次数匹配
.：匹配单个字符
*：匹配0个或多个重复位于星号前的字符
[]:匹配一组字符中的任意一个
[^]:取反
\{m\}：出现m次
\{m,n\}：最少出现m次，最多出现n次
\(\):分组引用，引用：\1, \2, \3
 
c)特殊符号
[:alnum:]:表示数字与大小写字母[0-9a-zA-Z]
[:alpha:]:表示大小写字母[a-zA-Z]
[:cntr:]:表示控制按键，Ctrl、Tab...
[:digit:]:表示数字
[:graph:]:表示除了空白键与Tab键外的所有按键
[:lower:]:代表小写字母
[:print:]:代表任何可以被打印出来的字节
[:punct:]:代表标点符号
[:space:]:代给空白键
[:upper:]:代表大写字母
[:xdigit:]:代表十六进制的数字类型

2.2.2、扩展正则表达式
使用方法及参数与基本正则表达式一致，与之不一样的是特殊字符无需转义（词首和词尾锚定除外），另新增了
几个参数，详情如下：
a)、特殊字符无转使用转义符
()：分用引用，相当于grep \(\)
{m}:相当于grep \{m\},精确匹配m次
{m,n}:相当于grep \{m,n\}最少出现m次，最多出现n次
\<:词首锚定
\>:词尾锚定符 
\b:位于词首前相当于\<；位于词尾后，相当于\> 
+：匹配其前导字符最少一次
？：匹配其前导字符0次或1次（案例测试2次以上的也会匹配，相当）
| ：或的意思，a|b；匹配a或b
1
2
2.2.3、快速正则表达式
同grep的常用选项及不常用选项
三、案例（为了方便，利用别名把grep默认加入–color=auto选项）

3.1 grep选项
a）常用选项测试案例

#-n:标识匹配“搜索字符串”行号：/etc/passwd只要包含root字符串的行都显示出来，并标识行号
[root@localhost tmp]# grep -n "root" /etc/passwd 
1:root:x:0:0:root:/root:/bin/bash
11:operator:x:11:0:operator:/root:/sbin/nologin
89:roota:x:33130:33130::/home/roota:/bin/bash
90:aroot:x:33131:33131::/home/aroot:/bin/bash

#-i:忽略大小写：/etc/rc0.d/K80kdump包含"PRO"字符串都显示出来，无视大小写。
[root@localhost ~]# grep -i "PRO" /etc/rc0.d/K80kdump 
# Provides: kdump 
# Description:  The kdump init script provides the support necessary for
KDUMP_IDE_NOPROBE_COMMANDLINE=""
1
#-y：同-i，忽略大小写

#-v:反相匹配：匹配/etc/passwd文件中不包含“root"字符串的行
[root@localhost ~]# grep -v "root" /etc/passwd
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin

#-w:完整匹配文字和数字字符：匹配/etc/passwd中单词为”root"的行，看下面结果，会发现与-n结果不一致，
#   roota、aroot用户都不符合匹配要求
[root@localhost tmp]# grep -w "root" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin

#-c:计算匹配“搜索的字符串”的行数：统计/etc/passwd文件中包含“root"字符串的行，从-n结果中即能确定
#   为4行
[root@localhost tmp]# grep -c "root" /etc/passwd
4

#-o:仅打印匹配到的字符串
[root@localhost tmp]# grep -o "aroot" /etc/passwd
aroot
aroot

#-A NUM：除了显示匹配行外，并显示匹配行后的指定数量 NUM 行
[root@localhost tmp]# grep -A1 "apache" /etc/passwd
apache:x:48:48:Apache:/var/www:/sbin/nologin
saslauth:x:498:76:"Saslauthd user":/var/empty/saslauth:/sbin/nologin

#-B NUM：除了显示匹配行外，并显示匹配行前的指定数量 NUM 行
[root@localhost tmp]# grep -B1 "apache" /etc/passwd
ntp:x:38:38::/etc/ntp:/sbin/nologin
apache:x:48:48:Apache:/var/www:/sbin/nologin

#-C NUM: 除了显示匹配行外，并显示匹配行前后的指定数量 NUM 行
[root@localhost tmp]# grep -C1 "apache" /etc/passwd
ntp:x:38:38::/etc/ntp:/sbin/nologin
apache:x:48:48:Apache:/var/www:/sbin/nologin
saslauth:x:498:76:"Saslauthd user":/var/empty/saslauth:/sbin/nologin
b)不常用选项：


#-x:完整行匹配：在搜索条件中，需输入整行字符，下例从shell.sh中匹配包含”#！/bin/bash“行的行
[root@localhost scripts]# grep -x "#\!/bin/bash" shell.sh 
#!/bin/bash

#-l:--files-with-matches  只打印包含匹配字符串的文件名 ：如果/etc/passwd文件中存在root字符串，则打印
#   文件名，不存在，则不显示
[root@localhost scripts]# grep -l "root" /etc/passwd
/etc/passwd

#-L:--files-without-match 只打印不包含匹配字符串的文件名，与-l选项正好相反：如果/etc/passwd文件中
#   不存在ro0ot字符串，则打印文件名，存在，则不显示
[root@localhost scripts]# grep -L "ro0ot" /etc/passwd
/etc/passwd

#-f:从文件中提取模板,如果为空文件则什么都不匹配：新建一个test.txt，包含aroot\roota，在从test.txt中
#   提取为模板，匹配/etc/passwd中包含模板的行
[root@localhost tmp]# cat test.txt 
aroot
roota
[root@localhost tmp]# grep -f test.txt /etc/passwd
roota:x:33130:33130::/home/roota:/bin/bash
aroot:x:33131:33131::/home/aroot:/bin/bash
#还可以结合重定向使用：
[root@localhost tmp]# cat > test.in
aroot
broot       
#==>输入ctrl+d中止输入信号
[root@localhost tmp]# grep -f test.in /etc/passwd
aroot:x:33131:33131::/home/aroot:/bin/bash
broot:x:33132:33132::/home/broot:/bin/bash

#-e:指定范本文件，其内容含有一个或多个范本样式，让grep查找符合范本条件的文件内容：在/etc/passwd中匹
#   配包含aroot或roota字符串的行
[root@localhost tmp]# grep -e aroot -e roota /etc/passwd
roota:x:33130:33130::/home/roota:/bin/bash
aroot:x:33131:33131::/home/aroot:/bin/bash

#-q:安静模式，不打印任何标准输出,如果有匹配的内容则立即返回状态值0
[root@localhost tmp]# grep -q "root" /etc/passwd
[root@localhost tmp]# echo $?

#-s:不显示不存在或无匹配文本的错误信息：存在则匹配输出，不存在则不输出
[root@localhost tmp]# grep -s "aroot" /etc/passwd
aroot:x:33131:33131::/home/aroot:/bin/bash
[root@localhost tmp]# grep -s "ro0ot" /etc/passwd

#-H:在每个匹配的行前显示绝对路径文件名，如果存在多个搜索文件，则默认存在-H功能：结合-e选项使用
[root@localhost tmp]# grep -H -e aroot -e roota /etc/passwd
/etc/passwd:roota:x:33130:33130::/home/roota:/bin/bash
/etc/passwd:aroot:x:33131:33131::/home/aroot:/bin/bash

#-h:匹配的行前不显示绝对路径文件名，默认存在于单个搜索文件前提下：多个搜索文件，默认存在-H功能，加
#   上-h选项，则不显示绝对路径文件名了，看下两例对比
[root@localhost ~]# grep "root" /tmp/aroot.txt /tmp/roota.txt 
/tmp/aroot.txt:aroot
/tmp/roota.txt:roota
[root@localhost ~]# grep -h "root" /tmp/aroot.txt /tmp/roota.txt 
aroot
roota

#-b:显示在每一行输出前的输入字节的偏移量：通过wc统计，你会发现，第一行加第二行正好为65，前三行相加
#   为105
[root@localhost ~]# grep -b bin  /etc/passwd  --color=auto
0:root:x:0:0:root:/root:/bin/bash
32:bin:x:1:1:bin:/bin:/sbin/nologin
65:daemon:x:2:2:daemon:/sbin:/sbin/nologin
105:adm:x:3:4:adm:/var/adm:/sbin/nologin
 
[root@localhost ~]# head -n 1 /etc/passwd | wc -m
32
[root@localhost ~]# head -n 2 /etc/passwd | tail -n 1 | wc -m
33
[root@localhost ~]# head -n 3 /etc/passwd | tail -n 1 | wc -m

#-m NUM:在找到指定数量 NUM 的匹配行后停止读文件
[root@localhost ~]# grep -m 2 "root" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin

#-R, -r, --recursive：递归
[root@localhost ~]# grep -r "passwd" /etc
Binary file /etc/prelink.cache matches
/etc/rpc:yppasswdd      100009  yppasswd
/etc/rpc:nispasswd      100303  rpc.nispasswdd
Binary file /etc/vmware-tools/plugins/vmsvc/libgrabbitmqProxy.so matches
/etc/default/nss:#  If set to TRUE, the passwd routines in the NIS NSS module will not
3.2正则表达式测试案例
3.2.1、基本正则表达式案例

a）锚定符

#^ :行首锚定符    :查找以root开头的行
[root@localhost ~]# grep "^root" /etc/passwd
root:x:0:0:root:/root:/bin/bash
roota:x:33130:33130::/home/roota:/bin/bash

#$ :行尾锚定符    :查找以nologin结尾的行
[root@localhost ~]# grep "nologin$" /etc/passwd
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin

#\<:词首锚定符    :查找以root作为单词首部的行
[root@localhost ~]# grep "\<root" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
roota:x:33130:33130::/home/roota:/bin/bash

#\>:词尾锚定符    :查找以root作为单词词尾的行
[root@localhost ~]# grep "root\>" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
aroot:x:33131:33131::/home/aroot:/bin/bash

#\b:位于词首前相当于\<；位于词尾后，相当于\> ，词首词尾均锚定相当于参数-w  :匹配/etc/passwd中包含单
#   词"root"的行
[root@localhost ~]# grep "\broot\b" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
b）字符、次数匹配

#.：匹配单个字符
[root@localhost ~]# grep "ar..t" /etc/passwd
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
aroot:x:33131:33131::/home/aroot:/bin/bash

#*：匹配0个或多个重复位于星号前的字符 ：从/etc/passwd中匹配rt、rot、root、roo*t
[root@localhost ~]# grep "ro*t" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
vcsa:x:69:69:virtual console memory owner:/dev:/sbin/nologin
#如果要用选项*匹配r与t之间到少两个以上的o，则需用rooo*
[root@localhost ~]# grep "rooo*" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin

#[]:匹配一组字符中的任意一个   从/etc/passwd中匹配包含aroot或broot的行
[root@localhost ~]# grep "[ab]root" /etc/passwd
aroot:x:33131:33131::/home/aroot:/bin/bash
broot:x:33132:33132::/home/broot:/bin/bash

#[^]:取反  :匹配/etc/passwd中不包含root的行，如果案例，你会发现包含root行也会匹配成功，这是因为这些
#    行还有很多非root字符，所以成功匹配
[root@localhost tmp]# grep "[^root]" /etc/passwd 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
#可以这样用：匹配非root开头的行
[root@localhost tmp]# grep "^[^root]" /etc/passwd
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin

#\{m\}：出现m次    ：匹配/etc/passwd中字母o连续出现2次的行
[root@localhost ~]# grep "o\{2\}"  /etc/passwd
root:x:0:0:root:/root:/bin/bash
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin

#\{m,n\}：最少出现m次，最多出现n次    
[root@localhost ~]# grep "ro\{2,4\}"  /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin

#\(\):分组引用，引用：\1, \2, \3   ：匹配test.conf文件中以15开头且以15结尾的行
[root@localhost tmp]# grep "^\(15\).*\1$" test.conf 
15:this is test file 15
c)特殊符号


#[:alnum:]:表示数字与大小写字母[0-9a-zA-Z]
[root@localhost tmp]# grep "[[:alnum:]]" test.conf 
15379111
this is test file 
THIS IS TEST FILE
This is test file

#[:alpha:]:表示大小写字母[a-zA-Z]
[root@localhost tmp]# grep "[[:alpha:]]" test.conf 
this is test file 
THIS IS TEST FILE
This is test file

#[:digit:]:表示数字
[root@localhost tmp]# grep "[[:digit:]]" test.conf 
15379111

#[:lower:]:代表小写字母
[root@localhost tmp]# grep "[[:lower:]]" test.conf 
this is test file 
This is test file

#[:upper:]:代表大写字母
[root@localhost tmp]# grep "[[:upper:]]" test.conf 
THIS IS TEST FILE
This is test file

#[:punct:]:代表标点符号
[root@localhost tmp]# grep "[[:punct:]]" test.conf 
This is test file.

#[:space:]:代表空白键
[root@localhost tmp]# grep "[[:space:]]" test.conf 
1537911    1
this is test file
3.2.2、扩展正则表达式案例
使用方法及参数与基本正则表达式一致，与之不一样的是特殊字符无需转义（词首和词尾锚定除外），另新增了几个参数，详情如下：
a)、特殊字符无转使用转义符


#()：分用引用，相当于grep \(\)   ：从test.conf文件中匹配以15开头且以15结尾的行
[root@localhost tmp]# egrep "^(15).*\1" test.conf 
15:THIS IS TEST FILE 15

#{m}、{m,n}:与grep使用方法一致，同（）一样无须转义符而已

#+：匹配其前导字符最少一次  ：从/etc/passwd中匹配包含ro字符串，且字母至少出现一次以上的行
[root@localhost tmp]# egrep "ro+" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
rtkit:x:499:497:RealtimeKit:/proc:/sbin/nologin

#？：匹配其前导字符0次或1次
[root@localhost tmp]# egrep "roo?" /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
rtkit:x:499:497:RealtimeKit:/proc:/sbin/nologin

#| ：或的意思，a|b；匹配a或b    从/etc/passwd中匹配aroot或broot
[root@localhost tmp]# egrep "[a|b]root" /etc/passwd
aroot:x:33131:33131::/home/aroot:/bin/bash
broot:x:33132:33132::/home/broot:/bin/bash
3.2.3、快速正则表达式案例


[root@chenss test]# man gcc | tr -cs "[:alpha:]" "\n" > out.conf        
#                    ==>创建纯字符串文本，grep提取做“搜索字符串”用
[root@chenss test]# time `man gcc | grep -F -f out.conf > /dev/null`   
#                    ==>测试fgrep提取out.conf为搜索字符串来匹配man gcc所消耗的时间
real    0m1.264s
user    0m1.235s
sys    0m0.128s
[root@chenss test]# time `man gcc | grep -f out.conf > /dev/null`      
#                    ==>测试grep提取out.conf为搜索字符串来匹配man gcc所消耗的时间
real    12m26.280s
user    12m25.121s
sys    0m1.559s
#对比结果告诉我们，纯字符串匹配时，fgrep比grep速度快的不是一点半点。