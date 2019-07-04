ACL的设置技巧
	getfacl:取得某个文件/目录的ACL权限
	setfacl:设置某个文件/目录的ACL权限

setfacl [-mxdb]
	-m:设置一个ACL权限
	-x:取消一个ACL权限
	-b:全部的ACL权限被移除
	-d:设置默认的ACL权限，仅能针对目录使用，在该目录新建的数据会引用此默认值。
    -R:递归设定acl，亦即包括次目录都会被设定起来；
    -k:移除预设的ACL参数
	
lsblk 列出系统上的所有磁盘列表
	lsblk [-dfimpt] [device]
		-d:仅列出磁盘本身，并不会列出该磁盘的分区数据
		-f:同时列出该磁盘内的文件系统名称
		-i:使用ASCII的线段输出，不要使用复杂的编码
		-m:同时输出该装置在/dev底下的权限数据
		-p:列出该装置的完整文件名！而不是仅列出最后的名字而已
		-t:列出该磁盘装置的详细数据，包括磁盘队列机制、预读写的数据量大小等

fdisk(fdisk提供交互式借口管理分区，操作均在内存中完成，没有直接同步到磁盘；直到适用w命令保存到磁盘中）
语法：
查看分区适用信息：
fdisk -l [-u] [device...]：列出指定磁盘设备上的分区情况；
管理分区：

    fdisk device
        常用命令：
           n：创建新分区
           d：删除已有分区
           t：修改分区类型
           l：查看分区类型
           w：保存并退出
           q：不保存退出
           p：显示现有分区
         h/m：查看帮助信息

分区完成后，需要通知内核重读分区表：

    CentOS 5：partprobe [device]
    CentOS 6,7：partx,kpartx,partprobe
        partx -a [device]
        kpartx -af [device]
        
查看：$ cat /proc/partitions    


磁盘管理
文件系统管理工具

    mkfs -t type = mkfs.{ext(2|3|4)|xfs|vfat...}    创建文件系统
    fsck -t type = fsck.{ext(2|3|4)|xfs|vfat...}    检测及修复文件系统

创建swap分区
Linux上的交换分区必须适用独立的文件系统；System ID必须为82
   
    mkswap [options] device
        -L LABEL 指明卷标
        -f 强制
        
mke2fs：文件系统管理工具

    mke2fs [options] device
        -t    {ext2|ext3|ext4}：指明要创建的文件系统类型
              mkfs.ext4 == mkfs -t ext4 == mke2fs -t ext4
        -b    {1024|2048|4096}：指明文件系统的块大小
        -L LABEL    ：指明卷标
        -j    创建有日志功能的文件系统ext3
            mke2fs -j == mke2fs -t ext3 == mkfs -t ext3 == mkfs.ext3
        -i #    bytes-per-inode,指明inode与字节的比率;即每多少字节创建一个inode;
        -N #    直接指明要给此文件系统创建的inode数量;
        -m #    指定预留的空间,百分比
        -O feature[,...]  以指定的特性创建目标文件系统;
        


tune2fs：查看或修改ext系列文件系统的某些属性

    tune2fs [options] device
            -l  查看超级块内容
       修改文件系统的属性：
            -j    ext2-->ext3;
            -L LABEL    修改卷标;
            -m #        修改预留空间百分比;
            -O [^]feature[,...]  开启或关闭某种特性;
            -o [^]mount_options  开启或关闭某种默认挂载选项;
                    例: 1.默认关闭acl：-o ^acl    2.默认开启acl：-o acl


查看和设定

    e2lable:
        e2lable device          查看卷标
        e2lable device LABEL    设定卷标
        
    blkid:
        blkid device    
        blkid -L LABEL    根据LABEL定位设备
        blkid -U UUID     根据UUID定位设备  
        
    dumpe2fs：
        dumpe2fs [-h] device    显示ext文件系统属性信息
        
        
检测和修复

    e2fsck：check a Linux ext2/ext3/ext4 file system
        e2fsck [options] device
            -y    对所有问题自动回答为yes
            -f    即使文件系统处于clean状态,也要强制进行检测
            
    fsck：check and repair a Linux file system
            -t fstype：指明文件系统类型
                fsck -t ext4 == fsck.ext4
            -a    无须交互式而自动修复所有错误
            -r    交互式修复
            
挂载

    swapon
        swapon device
        swapon -L LABEL
    swapoff
        swapoff device
        swapoff -L LABEL
        
mount挂载详解

    mount  [-nrw]  [-t vfstype]  [-o options]  device  dir
        命令选项：
            -a：将 /etc/fstab 中定义的所有档案系统挂上
            -r：readonly 只读挂载
            -w：read and write,读写挂载
            -n：默认情况挂载卸载操作会同步/etc/mtab文件中;-n用于禁用此特征
            -t vfstype：
                指明文件系统类型;多数可省,此时mount用blkid判断需挂载设备的文件系统类型
            -L LABEL：挂载时以卷标的方式指明设备        # mount -L LABEL dir
            -U UUID ：挂载时以UUID的方式指明设备        # mount -U UUID dir
            -B,--bind：绑定目录到另一个目录上
        -o options：挂载选项
                      ro：只读
                      rw：读写
              sync/async：同步/异步操作
           atime/noatime：文件或目录在被访问时是否更新其时间戳
     diratime/nodiratime：目录在被访问时是否更新其访问时间戳
             dev/nodev  ：此设备上是否允许创建设备文件
             exec/noexec：是否允许运行此设备上的程序文件
             auto/noauto：打开/关闭自动挂上模式
             user/nouser：是否允许普通用户挂载此文件系统
             suid/nosuid：是否允许程序文件上的suid和sgid特殊权限生效
                 remount：重新挂载
                     acl：支持使用facl功能
                          # mount -o acl device dir
                          # tune2fs -o acl device
            defaults：rw, suid, dev, exec, auto, nouser, async, relatime.
    注意：查看内核追踪到的已挂载的所有设备：cat /proc/mounts
            
umount卸载

    umount
        umount device|dir

    Note:正在被进程访问到的挂载点无法被卸载；

    查看被那个或者那些进程所占用；
        # lsof MOUNT_POINT
        # fuser -v MOUNT_POINT
        终止所有正在访问某挂载点的进程；
        # fuser -km MOUNT_POINT


两个小命令

    df命令：
    	df [OPTION]... [FILE]...
    		-l：仅显示本地文件的相关信息；
    		-h：人性化显示
    		-i：显示inode的使用状态而非blocks
    		
    du命令：
    	du [OPTION]... [FILE]...
    		-s:只显示每个参数的总数
    		-h:人性化显示

文件挂载的配置文件：/etc/fstab
    每行定义一个要挂载的文件系统：
        UUID=e79e59c0-797e-41a8-85c2-1477277338ae /boot  xfs    defaults  0 0
        要挂载的设备  挂载点 文件系统类型  挂载选项    转储频率    自检次序
            转储频率：
                0：不做备份
                1：每天转储
                2：每隔一天转储
            自检次序：
                0：不自检
                1：首先自检：一般只有rootfs采用1；
                ...

挂载本地的回环设备：

    $ mount -o loop /PATH/TO/SOME_LOOP_FILE   MOUNT_POINT 

挂载本地的回环设备：

    $ mount --bind olddir newdir

CentOS 6如何使用xfs文件系统：

    $ yum  -y  install  xfsprogs
    创建：mkfs.xfs 
    检测：fsck.xfs     

ext2不损坏数据的情况下升级ext4

    检查系统是否支持Ext4模块
    $ [ -f /lib/modules/`uname -r`/kernel/fs/ext4/ext4.ko ] && echo OK || echo NO
       # （如果能看到"OK"说明支持若不支持自行Google）
    检查Ext4模块是否挂载
    $ lsmod | grep ext4
            # (看到ext4则已挂载；若没挂在则执行：modprobe ext4)
    安装e2fsprogs
    $ yum install e2fsprogs -y
    卸载,转换
    $ umount /dev/device
    $ tune2fs -O has_journal,extents,huge_file,flex_bg,uninit_bg,dir_nlink,extra_isize /dev/device
    # 添加ext4特性
    修复
    $ e2fsck -fDC0 /dev/device
    挂载
    $ mount -t ext4 /dev/device dir

parted命令
	
	parted [装置] [指令] [参数]

	选项与参数：
	指令功能：
		新增分区：mkpart [parimary|logical|extended] [ext4|vfat|xfs] 开始 结束
		显示分区：print
		删除分区：rm [partition]

	示例：1、将/dev/sda这个原本的MBR分区变成GPT分区表
		# parted /dev/sda mklabel gpt
		 2、建立一个约为1G容量的分区槽
		# parted /dev/vda print   (先找出上一个分区的结束点作为下一个分区的起始点)
		# parted /dev/vda mkpart primary fat32 36.0G 37.0G	(新建一个1G的分区槽)


Btrfs 文件系统 (B-tree,Butter FS,Better FS),GPL,Oracle,2007,CoW;

    核心特性：
        多物理卷支持：btrfs可由多个底层物理卷组成：支持RAID，以联机“添加”、“移除”，“修改”
        写时复制更新机制(CoW)：复制、更新及替换指针，而非“就地”更新；
        数据及元数据校验码：checksum
        子卷：sub_volume
        快照：支持快照的快照；能实现增量快照
        透明压缩：

    文件系统创建：
        mkfs.btrfs
            -L 'LABEL'
            -d <type>：raid0,raid1,raid5,raid6,raid10,single
            -m <profile>：raid0,raid1,raid5,raid6,raid10,single,dup 
            -O <feature>
                -O list-all：列出支持的所有feature;
        属性查看：
            btrfs filesystem show
        挂载文件系统：
            mount -t btrfs /dev/sdb MOUNT_POINT
        透明压缩机制：
            mount -o compress={lzo|zlib} DEVICE MOUNT_POINT

让你的linux系统支持xfs文件系统只需下面的几步：
    1、安装xfs支持包
       yum -y install xfsprogs kmod-xfs xorg-x11-xfs xfsdump
    2、卸载掉原来已挂载的分区，假如你想让sda5成为xfs分区
       umount /dev/sda5   
    3、格式化成xfs格式
       mkfs.xfs -f /dev/sda5
    4、重新mount
       mount -t xfs -o defaults,noatime,nodiratime /dev/sda5 /data
       或者写入到/etc/fstab文件中后重启系统
       /dev/sda5             /data                   xfs    defaults,noatime,nodiratime    0 0
                    
