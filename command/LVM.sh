前言：
	LVM（Logical Volume Manager）是基于内核的一种逻辑卷管理器，LVM适合于管理大存储设备，并允许用户动态调整文件系统大小。此外，LVM的快照功能可以帮助我们快速备份数据。LVM为我们提供了逻辑概念上的磁盘，使得文件系统不再关心底层物理磁盘的概念。

	使用LVM创建逻辑卷需要我们提前了解以下几个概念：
    PE：Physical Ex
        LVM默认使用4MB的PE块，他是整个LVM最小的存储单元，也就是说，我们的文件数据都是由写入PE来处理的。简单的说，这个PE就是有点像文件系统里面的block大小。
    PV：Physical Volume 物理卷
        物理卷是LVM的最底层概念，是LVM的逻辑存储块，物理卷与磁盘分区是逻辑的对应关系。LVM提供了命令工具可以将分区转换为物理卷，通过组合物理卷可以生成卷组。
    VG：Volume Group 卷组
        卷组是LVM逻辑概念上的磁盘设备，通过将单个或多个物理卷组合成后生成卷组。卷组的大小取决于物理卷的容量以及个数。
    LV：Logical Volume 逻辑卷
        逻辑卷就是LVM逻辑意义上的分区，我们可以指定从卷组中提取多少容量来创建逻辑卷，最后对逻辑卷格式化并挂载使用。

常用命令
	PV常用命令
		pvcreate    #创建一个PV物理卷
        pvchange    #修改PV的属性
        pvresize    #调整一个PV的大小
        pvremove    #删除一个PV
        pvmove      #移动PE到指定物理卷
        pvscan      #搜索所有磁盘上的物理卷
        pvs         #显示PV的简要信息
        pvdisplay   #显示PV的属性信息
    VG常用命令：
   		vgcreate    #创建卷组
            -l：设置此卷组可容纳的LV最大数，默认为255
            -p：设置此卷组包含PV的最大数，默认为255
            -s：设置此卷组PE大小，默认为4M
        vgextend   #扩展VG大小
        vgchange   #修改VG属性信息
        vgreduce   #缩减VG大小
        vgremove   #删除VG
        vgscan    #搜索所有磁盘上的卷组
        vgs      #显示VG简要信息
        vgdisplay  #显示VG属性信息
        vgck        #检查VG元数据
    LV常用命令：
 		lvcreate    #创建LV分区
            -l：设置LV大小，以PE为单位
            -L：设置LV大小，以字节为单位
            -n：设置LV名称
            -p：设置LV权限读写权限，默认为可读可写
            -s：设置一个快照卷，对一个已存在的LV做快照
        lvextend    #扩展LV大小
        lvreduce    #缩减LV大小
        lvchange    #修改LV属性信息
            -ay：标记LV为可用状态
            -an：标记LV为不可用状态
        lvremove    #删除LV
        lvscan      #搜索所有磁盘上的逻辑卷
        lvs         #显示LV简要信息
        lvdisplay   #显示LV属性信息




实战演习：

[root@server ~]# fdisk -l | grep ^/de
/dev/sda1   *           1          64      512000   83  Linux
/dev/sda2              64        2611    20458496   8e  Linux LVM 
/dev/sdb1               1          14      112423+  83  Linux 
/dev/sdb2              15          80      530145   83  Linux
/dev/sdc1               1         654     5253223+  8e  Linux LVM
/dev/sdd1               1         654     5253223+  8e  Linux LVM 
/dev/sde1               1         654     5253223+  8e  Linux LVM

创建PV：
[root@server ~]# pvcreate /dev/sd{c,d,e}1
  Physical volume "/dev/sdc1" successfully created
  Physical volume "/dev/sdd1" successfully created
  Physical volume "/dev/sde1" successfully created

查看创建的PV
[root@server ~]# pvs            #查看PV的简要信息
  PV         VG       Fmt  Attr PSize  PFree
  /dev/sda2  VolGroup lvm2 a--  19.51g    0 
  /dev/sdc1           lvm2 ---   5.01g 5.01g
  /dev/sdd1           lvm2 ---   5.01g 5.01g
  /dev/sde1           lvm2 ---   5.01g 5.01g
[root@server ~]# pvdisplay             #查看PV详细信息
  --- Physical volume ---  
  "/dev/sde1" is a new physical volume of "5.01 GiB"
  --- NEW Physical volume ---            #新PV
  PV Name               /dev/sde1            #物理卷名称
  VG Name               
  PV Size               5.01 GiB                #物理卷大小
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               VREiVr-2Jr5-jNM8-EoKo-Agxw-oypN-kyUrXI

创建VG：
[root@server ~]# vgcreate -s 2M myvg /dev/sdc1 /dev/sdd1
  Volume group "myvg" successfully created
 
查看VG：
 [root@server ~]# vgs
  VG       #PV #LV #SN Attr   VSize  VFree 
  VolGroup   1   2   0 wz--n- 19.51g     0 
  myvg       2   0   0 wz--n- 10.02g 10.02g        #新建的VG，名称：myvg，大小10G
[root@server ~]# vgdisplay 
  --- Volume group ---
  VG Name               myvg            #卷组名
  System ID             
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               10.02 GiB        #卷组大小
  PE Size               2.00 MiB        #PE大小2M
  Total PE              5128
  Alloc PE / Size       0 / 0   
  Free  PE / Size       5128 / 10.02 GiB        #剩余容量
  VG UUID               W0FnIa-Z5Th-XRaM-EfcZ-HWeF-Jdee-jVTVyT

扩展myvg大小：
[root@server ~]# vgextend myvg /dev/sde1
  Volume group "myvg" successfully extended

缩减myvg大小：
[root@server ~]# vgreduce myvg /dev/sde1
  Removed "/dev/sde1" from volume group "myvg"

创建LV：
[root@server ~]# lvcreate -L +6G -n mylv myvg                创建大小为6G，名称为mylv的逻辑卷！卷组为myvg
  Logical volume "mylv" created
[root@server ~]# lvs
  LV      VG       Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao---- 17.57g                                                    
  lv_swap VolGroup -wi-ao----  1.94g                                                    
  mylv    myvg     -wi-a-----  6.00g                           #大小6G                         
[root@server ~]# lvdisplay
  --- Logical volume ---
  LV Path                /dev/myvg/mylv        #逻辑卷mylv的路径
  LV Name                mylv                        #逻辑卷名称mylv
  VG Name                myvg                      #基于myvg卷组
  LV UUID                EXKn5D-lVzU-JdlO-GYoo-CYpz-y20L-xn5cI5
  LV Write Access        read/write
  LV Creation host, time server.lili.com, 2015-06-10 17:47:02 +0800
  LV Status              available
  # open                 0
  LV Size                6.00 GiB
  Current LE             3072
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:2 
[root@server ~]# mkfs.ext4 /dev/myvg/mylv        #格式化LV 
[root@server ~]# mkdir /data        #创建挂载路径
[root@server ~]# mount /dev/myvg/mylv /data/        #挂载mylv 
[root@server ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                       18G  3.6G   13G  23% /
tmpfs                 491M  228K  491M   1% /dev/shm
/dev/sda1             477M   28M  424M   7% /boot
/dev/sr0              4.4G  4.4G     0 100% /media/CentOS_6.6_Final
/dev/mapper/myvg-mylv
                      5.8G   12M  5.5G   1% /data        #大小为6G的/data
这样我们就成功的创建了我们的逻辑卷！可是随着业务的增加！data目录不够用了，我们就可以扩展mylv的大小，可在线扩展。

扩展mylv： 
[root@server ~]# lvextend -L +1G -n /dev/myvg/mylv         #扩展物理边界增加1G
  Size of logical volume myvg/mylv changed from 6.00 GiB (3072 extents) to 7.00 GiB (3584 extents).
  Logical volume mylv successfully resized
 [root@server ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                       18G  3.6G   13G  23% /
tmpfs                 491M  228K  491M   1% /dev/shm
/dev/sda1             477M   28M  424M   7% /boot
/dev/sr0              4.4G  4.4G     0 100% /media/CentOS_6.6_Final
/dev/mapper/myvg-mylv
                      5.8G   12M  5.5G   1% /data     #仍然为6G        #逻辑卷没增加
[root@server ~]# resize2fs /dev/myvg/mylv         #扩展逻辑边界。        注：只对ext文件系统使用。这里也可以指定扩展逻辑边界大小，默认物理边界大小。
resize2fs 1.41.12 (17-May-2010)
Filesystem at /dev/myvg/mylv is mounted on /data; on-line resizing required
old desc_blocks = 1, new_desc_blocks = 1
Performing an on-line resize of /dev/myvg/mylv to 1835008 (4k) blocks.
The filesystem on /dev/myvg/mylv is now 1835008 blocks long.
[root@server ~]# lvs
  LV      VG       Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao---- 17.57g                                                    
  lv_swap VolGroup -wi-ao----  1.94g                                                    
  mylv    myvg     -wi-a-----  7.00g           
 [root@server ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                       18G  3.6G   13G  23% /
tmpfs                 491M  228K  491M   1% /dev/shm
/dev/sda1             477M   28M  424M   7% /boot
/dev/sr0              4.4G  4.4G     0 100% /media/CentOS_6.6_Final
/dev/mapper/myvg-mylv
                      6.8G   14M  6.5G   1% /data        #大小为7G了

缩减：

缩减的顺序应该与创建时的顺序相反，也就是卸载文件系统、删除逻辑卷、删除卷组、删除物理卷。缩减很危险，不到万不得已千万别缩减。缩减需离线。

缩减步骤：
1、先确定缩减后的目标大小；并确保对应的每一步逻辑卷大小中有足够的空间可容纳原有所有数据；
2、先制裁文件系统，并要执行强制检测
3、缩减逻辑边界
4、缩减物理边界

[root@server ~]# umount /data/
[root@server ~]# e2fsck -f /dev/myvg/mylv        # 强制检测
e2fsck 1.41.12 (17-May-2010)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/myvg/mylv: 11/458752 files (0.0% non-contiguous), 65023/1835008 blocks
  
[root@server ~]# resize2fs /dev/myvg/mylv 2G        # 缩减逻辑边界至2G
resize2fs 1.41.12 (17-May-2010)
Resizing the filesystem on /dev/myvg/mylv to 524288 (4k) blocks.
The filesystem on /dev/myvg/mylv is now 524288 blocks long.
  
[root@server ~]# lvreduce -L 2G /dev/myvg/mylv         # 缩减物理边界至2G
  WARNING: Reducing active logical volume to 2.00 GiB
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce mylv? [y/n]: y            # 确认，后果自负
  Size of logical volume myvg/mylv changed from 7.00 GiB (3584 extents) to 4.00 GiB (2048 extents).
  Logical volume mylv successfully resized
[root@server ~]# mount /dev/myvg/mylv /data/        # 重新挂载
[root@server ~]# df -lh
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                       18G  3.6G   13G  23% /
tmpfs                 491M  228K  491M   1% /dev/shm
/dev/sda1             477M   28M  424M   7% /boot
/dev/sr0              4.4G  4.4G     0 100% /media/CentOS_6.6_Final
/dev/mapper/myvg-mylv
                      1.9G  9.0M  1.8G   1% /data        # 2G大小
 

创建快照卷：

    快照卷是对逻辑卷进行的，因此必须跟目标逻辑卷在同一个卷组中，无须指明卷组。需确保剩余卷组可容纳快照。

lvcreate
-L ：大小
-n： 名称
-s：快照
-p r:只读
[root@server ~]# fuser /data/        # 创建快照卷时尽量避免有访问时创建快照！
 
/data/:               8640c          # 有访问

[root@server ~]# mount -o remount,ro /dev/myvg/mylv /data/ && lvcreate -L 1G -n mylv-snap -p r -s /dev/myvg/mylv && mount -o remount,rw /dev/myvg/mylv /data/       
# 先以只读方式挂载逻辑卷&&然后创建快照&&然后在以读写方式挂载逻辑卷
  Logical volume "mylv-snap" created
[root@server ~]# mkdir /snap        # 创建挂载点
[root@server ~]# mount /dev/myvg/mylv-snap /snap/        # 挂载快照
mount: block device /dev/mapper/myvg-mylv--snap is write-protected, mounting read-only    #只读
卸载快照卷：

[root@server ~]# umount /snap/        # 卸载
 
[root@server ~]# lvremove /dev/myvg/mylv-snap     # 移除快照
 
Do you really want to remove active logical volume mylv-snap? [y/n]: y    # 确认
 
  Logical volume "mylv-snap" successfully removed
























