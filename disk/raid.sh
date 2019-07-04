测试机centos6.7 x86_64

一、RAID是什么

    简单描述：RAID(Redundant Array of indenpensive Disk)独立磁盘冗余阵列：磁盘阵列是把多个磁盘组成一个阵列，当作单一磁盘使用，它将数据以分段或条带（striping)的方式储存在不同的磁盘中，存取数据时，阵列中的相关磁盘一起动作，大幅减低数据的存取时间，同时有更佳的空间利用率。磁盘阵列利用不同的技术，称为RAID level，不同的level针对不同的系统及应用，以解决数据安全的问题。简单来说，RAID把多个磁盘组成一个逻辑扇区，因此，操作系统只会把他当作一个硬盘。



二、RAID优缺点

    优点：

    1、提高传输速率。RAID通过多个磁盘上同时存储和读取数据来大幅提高存储系统的数据吞吐量（Throughput)。在RAID中，可以让很多磁盘驱动器同时传输数据，而这些磁盘驱动器在逻辑上又是一个磁盘驱动器，所以使用RAID可以单个磁盘驱动器的几倍、几十倍甚至上百倍的速率。这也是RAID最初想要解决的问题。因为当时CPU的速度增长很快，而磁盘驱动器的数据传输速率无法大幅提高，所以需要有一种方案解决两者之间的矛盾。RAID最后成功了。

    2、通过数据校验提供容错功能。普通磁盘驱动器无法提供容错功能，如果不包括写在磁盘上的CRC（循环冗余校验）码的话。RAID容错是建立在每个磁盘驱动器的硬件容错功能之上的，所以它提供更高的安全性。在很多RAID中都有较为完备的相互校验/恢复的措施，甚至是直接相互的镜像备份，从而大大提高了RAID系统的容错度，提高了系统的稳定冗余性。

    缺点：

    1、做不同的RAID，有RAID模式磁盘利用率低，价格昂贵。

    2、RAID0没有冗余功能，如果有一个磁盘（物理）损坏，则所有的数据都无法使用。

    3、RAID1磁盘利用率只有50%，是所有RAID级别中最低的。

    4、RAID5可以理解为是RAID0和RAID1的折中方案。RAID5可以为系统提供数据安全保障，但保障程度要比RAID1低而磁盘空间利用率要比RAID1高。

三、RAID样式

    外接式磁盘阵列柜：最常被使用大型服务器上，具有热抽换（Hot Swap）的特性，不过价格都很贵。

    内接式磁盘阵列卡：因为价格便宜，但需要较高的安装技术，适合技术人员操作。

    利用软件来仿真：由于会拖累机器的速度，不适合大数据流量的服务器。

四、RAID分类

    1、RAID 0 被称为条带盘 — 需要2块以上的磁盘，成本低，可以提高整个磁盘的性能和吞吐量。我们通过名字来想象：RAID 0 通过把文件切割之后把数据像一条带子一样平铺在每个磁盘之上。由于文件的数据分布在每个磁盘上，所以其中一个磁盘出现问题的时候，文件就会由于缺失了某部分而损坏。并且RAID 0 不提供冗余所以不需要额外使用空间来存储校验码，所以磁盘空间都可以用作存储文件。并且磁盘的实际容量体现为木桶理论（最小的水平决定整体的水平）。假如有4个磁盘，分别为320G，500G，1T，2T。则实际容量为（最小容量的磁盘乘以硬盘数量），即320G*4。读写性能由于磁头数电费增加，所以读写的时候磁头之间可以实现分工合作。所以读写性能提升。

    2、RAID 1 磁盘镜像盘 — 数据在写入一块磁盘的同时，会在另外一块闲置的磁盘上生成镜像文件mirroring（镜像卷），至少需要两块磁盘，RAID大小等于两个RAID分区中最小的容量（最好两个磁盘的容量一样），可增加热备盘提供一定的备份能力；数据有冗余，在存储时同时写入两块磁盘，实现了数据备份；但相对降低了写入性能，但是读取数据时可以并发，几乎类似于raid-0的读取效率；

    3、RAID 3 奇偶校验码的并行传送 — 只能查错不能纠错；

    4、RAID 4 带奇偶校验码的独立磁盘结构 — 对数据的访问是按数据块进行的，也就是按磁盘进行的，RAID 3 是一次一横条，而RAID 4 一次一竖条；

    5、RAID 5 分布式奇偶校验的独立磁盘结构：需要至少三块或以上磁盘，可以提供热备盘实现故障的恢复；采用奇偶校验，可靠性强，且只有同时损坏两块磁盘时数据才会完全损坏，至损坏一块硬盘时，系统会根据存储的奇偶校验位重建数据，临时提供服务；此时如果有热备盘，系统还会自动在热备盘上重建故障磁盘上的数据；

    6、RAID 6 带有两种分布式存储的奇偶校验码的独立磁盘结构，在RAID 5 的基础上进行改进，通过加入增加校验块，而有更好的容错能力。由于整体的磁盘数量增加，所以读取速率提升；但是由于写入数据时不仅要写入文件数据，还要计算并写入两个校验块，所以写入速率性能下降；并且由于增加了一位校验块，RAID控制器要求更加复杂，所以在数据安全和磁盘性能中进行取舍，RAID 5 更受欢迎。实际的磁盘空间为：最小的磁盘容量*（磁盘数量-2）

    7、RAID 7 优化的高速数据传送磁盘结构 — 高速缓冲存储器：这是一种新的RAID标准，其本身带有智能化实时操作系统和用于存储管理的软件工具，可完全独立于主机运行，不占用主机CPU资源，RAID 7 可以看作是一种存储计算机（Strage Computer），它与其他RAID标准有明显区别。

    8、RAID 1+0 高可靠性于高效磁盘结构

    9、RAID 0+1 高效率与高性能磁盘结构、

RAID 1+0 与 RAID 0+1 的区别：RAID 1+0 是先镜像在分区数据，再将所有硬盘分为两组，视为RAID 0 的最低组合，然后将这两组各自视为RAID 1 运作。RAID 0+1 则是跟RAID 1+0 的程序相反，是先分区再将数据镜射到两组磁盘。它将所有磁盘分为两组，变成RAID 1 的最低组合，而将两组磁盘各自视为RAID 0 运作。性能上，RAID 0+1比RAID 1+0 有着更快的读写速度。可靠性上，当RAID 1+0 有一个磁盘受损，其余三个硬盘会继续运作。RAID 0+1 只要有一个硬盘受损，同组RAID 0的另一只磁盘亦会停止运作，只剩下两个硬盘运作，可靠性较低。因此，RAID 10 远较RAID 01常用，零售主板绝大部分支持RAID 0/1/5/10,但不支持RAID 01。


五、常见RAID总结

  RAID Level	性能提升	冗余能力	空间利用率	磁盘数量（块）
  RAID 0	读、写提升	无	100%	至少2
  RAID 1	读性能提升，写性能下降	有	50%	至少2
  RAID 5	读、写提升	有	（n-1）/n%	至少3
  RAID 1+0	读、写提升	有	50%	至少4
  RAID 0+1	读、写提升	有	50%	至少4
  RAID 5+0	读、写提升	有	（n-2）/n%	至少6

六、mdadm工具介绍
    简介：mdadm (multiple devices admin)是linux下标准的软raid管理工具，是一个模式化工具（在不同的模式下）；程序工作再内存用户程序区，为用户提供RAID接口来操作内核的模块，实现各种功能。

  ###查看：
  [root@mail ~]# uname -r
  2.6.32-573.el6.x86_64
  [root@mail ~]# lsb_release -a
  LSB Version::base-4.0-amd64:base-4.0-noarch:core-4.0-amd64:core-4.0-noarch:graphics-4.0-
  amd64:graphics-4.0-noarch:printing-4.0-amd64:printing-4.0-noarch
  Distributor ID:CentOS
  Description:CentOS release 6.7 (Final)
  Release:6.7
  Codename:Final
  [root@mail ~]# rpm -qa mdadm
  mdadm-3.3.2-5.el6.x86_64
  ###mdadm命令基本语法
  mdadm [mode] <raiddevice> [options] <component-devices>
  目前支持的模式
  LINEAR(线性模式)、RAID0(striping条带模式)、RAID1(mirroring)、 RAID-4、RAID-5、 RAID-6、 R
  AID-10、 MULTIPATH和FAULTY
  LINEAR:线性模式，该模式不是raid的标准模式，其主要作用是可以实现将几块小的硬盘组合为一块大
  硬盘来使用，数组存储时一次存满一个硬盘在使用下一个硬盘，对上层来说操作的是一个大硬盘。
  主要模式(7种)
    Assemble：装配模式：加入一个以前定义的阵列,可以正在使用阵列或从其他主机移出的阵列
    Build：  创建：创建一个没有超级块的阵列
    Create： 创建一个新的阵列，每个设备具有超级块
    Follow or Monitor: 监控RAID的状态，一般只对RAID-1/4/5/6/10等有冗余功能的模式来使用
    Grow：(Grow or shrink) 改变RAID的容量或阵列中的设备数目；收缩一般指的是数据收缩或重建
    Manage： 管理阵列(如添加spare盘和删除故障盘)
    Incremental Assembly：添加一个设备到一个适当的阵列
    Misc：  允许单独对阵列中的某个设备进行操作(如抹去superblocks 或停止阵列)
    Auto-detect： 此模式不作用于特定的设备或阵列，而是要求在Linux内核启动任何自动检测到的阵列
  #主要选项：（Options for selecting a mode)
    -A, --assemble：加入并开启一个以前定义的阵列
    -B, --build：创建一个没有超级块的阵列（Build a legacy array without superblocks)
    -C, --create：创建一个新的阵列
    -F， --follow,--monitor：选择监控（Monitor)模式
    -G， --grow：改变激活阵列的大小或形态
    -I， --incremental：添加一个单独的设备到合适的阵列，并可能启动阵列
    --auto-detect：请求内核启动任何自动检测到的阵列
  #创建模式
    -C --create：创建一个新的阵列
            专用选项：
                -l：级别
                -n #：设备个数
                -a {yes|no}：是否自动为其创建设备文件
                -c：CHUNK大小，2^n，默认为64K
                -x #：指定空闲盘个数
               
  #管理模式
    -a --add：添加列出的设备到一个工作的阵列中；当阵列出于降级状态（故障状态），你添加一个设
    备，该设备将作为备用设备并且再该备用设备上开始数据重建
    -f --fail：将列出的设备标记为faulty状态，标记后就可以移除设备：（可以作为故障恢复的测试手
    段）
    -r --remove：从阵列中移除列出的设备，并且该设备不能出于活动状态（是冗余盘或故障盘）
  
  #监控模式
    -F --follow,--monitor：选择监控（Monitor）模式
    -m --mail：设置一个mail地址，在报警时给该mail发信；该地址可写入conf文件，在启动阵列时生效
    -p --program,--alert：当检测到一个事件时运行一个指定的程序
    -y --syslog：设置所有的事件记录于syslog中
    -t --test：给启动时发现的每个阵列生成test警告信息；该信息传递给mail或报警程序；（以此来测
    试报警信息是否能正确接收）
 
  #增长模式
    -G --grow：改变激活阵列的大小或形态
    -n --raid-devices=：指定阵列中活动的device数目，不包括spare磁盘，这个数目只能由--grow修改
    -x --spare-devices=：指定初始阵列的冗余device数目即spare device数目
    -c --chunk：Specify chunk size of kibibytes.缺省为64.chunk-size是一个重要的参数，决定了一
    次向阵列中每个磁盘写入数据的量
    （Chunk :,可以理解为raid分储数据时每个数据段的大小（通常为32/64/128等这类数字大小）；合理
  的选择chunk大小非常重要，若chunk过大可能一块磁盘上的带区空间就可以满足大部分的I/O操作，使
  得数据的读写只局限于一块硬盘上，这便不能充分发挥RAID并发的优势；如果chunk设置过小，任何很
  小的I/O指令都 可能引发大量的读写操作，不能良好发挥并发性能，占用过多的控制器总线带宽，也
  影响了阵列的整体性能。所以，在创建带区时，我们应该根据实际应用的需要，合理的选择带区大小
  。）
    -z --size=：组建RAID1/4/5/6后从每个device获取的空间总数；但是大小必须为chunk的倍数，还需
    要在每个设备最后给RAID的superblock留至少128KB的大小。
    --rounding=: Specify rounding factor for linear array (==chunk size)
    -l --level=: 设定 raid level.raid的几倍
    --create：   可用:linear, raid0, 0, stripe, raid1,1, mirror, raid4, 4, raid5, 5, raid6, 
    6, multipath, mp.
    --build：   可用：linear, raid0, 0, stripe.
    -p --layout=：设定raid5 和raid10的奇偶校验规则；并且控制故障的故障模式；其中RAID-5的奇偶
    校验可以在设置为：:eft-asymmetric, left-symmetric, right-asymmetric, right-symmetric, la,
     ra, ls, rs.缺省为left-symmetric
    --parity:   类似于--layout=
    --assume-clean:目前仅用于 --build 选项
    -R --run:  阵列中的某一部分出现在其他阵列或文件系统中时，mdadm会确认该阵列。此选项将不作
    确认。
    -f --force: 通常mdadm不允许只用一个device 创建阵列，而且此时创建raid5时会使用一个device作
    为missing drive。此选项正相反
    -N --name=: 设定阵列的名称
  #装配模式
    -A, --assemble： 加入并开启一个以前定义的阵列
    #MISC模式选项
    -Q, --query： 查看一个device，判断它为一个 md device 或是 一个 md 阵列的一部分
    -D, --detail： 打印一个或多个md device 的详细信息
    -E, --examine：打印 device 上的 md superblock 的内容
 
  #查看RAID阵列的详细信息
    mdadm -D /dev/md#
              --detail   停止阵列
               
  #停止RAID阵列
    mdadm -S /dev/md#
              --stop
               
  #开启RAID阵列
    mdadm -A /dev/md#
              --start
             
  #其他选项
    -c, --config=： 指定配置文件，缺省为 /etc/mdadm.conf
    -s, --scan：  扫描配置文件或 /proc/mdstat以搜寻丢失的信息。默认配置文件：/etc/mdadm.conf
    -h, --help：  帮助信息，用在以上选项后，则显示该选项信息
    -v, --verbose： 显示细节，一般只能跟 --detile 或 --examine一起使用，显示中级的信息
    -b, --brief：  较少的细节。用于 --detail 和 --examine 选项
    --help-options： 显示更详细的帮助
    -V, --version： 版本信息
    -q，--quit：   安静模式；加上该选项能使mdadm不显示纯消息性的信息，除非那是一个重要的报告

七、创建RAID

1、直接使用硬盘硬件设备，不需要分区。
    
    创建一个RAID 0设备：
    mdadm --create  /dev/md0 --level=0 --chunk=32 --raid-devices=3 /dev/sd[b-d]
    创建一个RAID 1设备：
    mdadm -C /dev/md0 -l1 -c128 -n2 -x1 /dev/sd[b-d]
    创建一个RAID 5设备：
    mdadm -C /dev/md0 -l5 -n5 /dev/sd[c-g] -x1 /dev/sdb
    创建一个RAID 6设备：
    mdadm -C /dev/md0 -l6 -n5 /dev/sd[c-g] -x2 /dev/sdb /dev/sdh
    创建一个RAID 10设备：
    mdadm -C /dev/md0 -l10 -n6 /dev/sd[b-g] -x /dev/sdh
    创建一个RAID1+0设备（双层架构）：
    mdadm -C /dev/md0 -l1 -n2 /dev/sdb /dev/sdc
    mdadm -C /dev/md1 -l1 -n2 /dev/sdd /dev/sde
    mdadm -C /dev/md2 -l1 -n2 /dev/sdf /dev/sdg
    mdadm -C /dev/md3 -l0 -n3 /dev/md0 /dev/md1 /dev/md2
     
2、如果要具体使用那个硬盘的分区来做RAID，才需要fdisk特定的分区，并给他指定分区类型：fd
具体过程如下：
  
  1）、分区
  # fdisk /dev/sda
  WARNING: DOS-compatible mode is deprecated. It's strongly recommended to
           switch off the mode (command 'c') and change display units to
           sectors (command 'u').
  Command (m for help): n
  Command action
     e   extended
     p   primary partition (1-4)
  e
  Selected partition 4
  First cylinder (1632-26108, default 1632): 
  Using default value 1632
  Last cylinder, +cylinders or +size{K,M,G} (1632-26108, default 26108): 
  Using default value 26108
  Command (m for help): n
  First cylinder (1632-26108, default 1632): 
  Using default value 1632
  Last cylinder, +cylinders or +size{K,M,G} (1632-26108, default 26108): +5G
  Command (m for help): n
  First cylinder (2286-26108, default 2286): 
  Using default value 2286
  Last cylinder, +cylinders or +size{K,M,G} (2286-26108, default 26108): +5G
  Command (m for help): n
  First cylinder (2940-26108, default 2940): 
  Using default value 2940
  Last cylinder, +cylinders or +size{K,M,G} (2940-26108, default 26108): +5G
  Command (m for help): n
  First cylinder (3594-26108, default 3594): 
  Using default value 3594
  Last cylinder, +cylinders or +size{K,M,G} (3594-26108, default 26108): +5G
  Command (m for help): t
  Partition number (1-7): 5
  Hex code (type L to list codes): fd
  Changed system type of partition 5 to fd (Linux raid autodetect)
  Command (m for help): t
  Partition number (1-7): 6
  Hex code (type L to list codes): fd
  Changed system type of partition 6 to fd (Linux raid autodetect)
  Command (m for help): t
  Partition number (1-7): 7
  Hex code (type L to list codes): fd
  Changed system type of partition 7 to fd (Linux raid autodetect)
  Command (m for help): t
  Partition number (1-8): 8
  Hex code (type L to list codes): fd
  Changed system type of partition 8 to fd (Linux raid autodetect)
  ##这里只是举个例子，其它类似！特别说明：再fdisk分区后需要将分区标志改为Linux raid auto
  类型。
  # fdisk -l| grep sd   （最终效果）
  Disk /dev/sda: 214.7 GB, 214748364800 bytes
  /dev/sda1   *           1         103      819200   83  Linux
  /dev/sda2             103        1377    10240000   83  Linux
  /dev/sda3            1377        1632     2048000   82  Linux swap / Solaris
  /dev/sda4            1632       26108   196604286    5  Extended
  /dev/sda5            1632        2285     5246007   fd  Linux raid autodetect
  /dev/sda6            2286        2939     5253223+  fd  Linux raid autodetect
  /dev/sda7            2940        3593     5253223+  fd  Linux raid autodetect
  /dev/sda8            3594        4247     5253223+  fd  Linux raid autodetect
  # kpartx -af /dev/sda
  # partx -a /dev/sda
  2）、建立磁盘阵列
  [root@mail soft]# mdadm -C /dev/md0 -a yes -l 5 -n 3 /dev/sda{5,6,7}
  mdadm: Defaulting to version 1.2 metadata
  mdadm: array /dev/md0 started.
  #-C：创建一个阵列，后跟阵列名称
  #-a：表示自动创建
  #-l：指定阵列级别
  #-n：指定阵列中活动devices的数目
  3）、查看RAID5阵列
  #watch cat /proc/mdstat   ##查看磁盘同步情况
  # cat /proc/mdstat 
  Personalities : [raid6] [raid5] [raid4] 
  md0 : active raid5 sda7[3] sda6[1] sda5[0]    #第一行
        10483712 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU] #第二行
         
  unused devices: <none>
  #第一行是MD设备名称md0,active和inactive选项表示阵列是否能读/写，接着是阵列的RAID级别RAID
  5,后面是属于阵列的块设备，方括号[]里的数字表示设备再阵列中的序号，(S)表示其是热备盘，(F)
  表示这个磁盘是faulty状态。
  #第二行是阵列的大小，用块数来表示；后面有chunk-size的大小，然后是layout类型，不同RAID级别
  的layout类型不同，[3/3] [UUU]表示阵列有3个磁盘并且3个磁盘都是正常运行的，若是[2/3]和[UU]
  表示阵列有3个磁盘中2个是正常运行的，下划线对应的那个位置的磁盘是faulty（错误）状态的。
4）、查看RAID 5的详细信息
  # mdadm --detail /dev/md0
  /dev/md0:
          Version : 1.2
    Creation Time : Mon Feb  1 13:58:13 2016
       Raid Level : raid5
       Array Size : 10483712 (10.00 GiB 10.74 GB)
    Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
     Raid Devices : 3
    Total Devices : 3
      Persistence : Superblock is persistent
      Update Time : Mon Feb  1 14:01:52 2016
            State : clean 
   Active Devices : 3       ＃活动的设备
  Working Devices : 3
   Failed Devices : 0
    Spare Devices : 0
           Layout : left-symmetric
       Chunk Size : 512K　　＃数据块大小
             Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
             UUID : bec67e95:105bc368:092dafe4:d0ad43bc
           Events : 18
      Number   Major   Minor   RaidDevice State
         0       8        5        0      active sync   /dev/sda5
         1       8        6        1      active sync   /dev/sda6
         3       8        7        2      active sync   /dev/sda7
        
5）、格式化
  # mke2fs -t ext4 -b 4096 -L myraid5 /dev/md0
  mke2fs 1.41.12 (17-May-2010)
  Filesystem label=myraid5
  OS type: Linux
  Block size=4096 (log=2)
  Fragment size=4096 (log=2)
  Stride=128 blocks, Stripe width=256 blocks
  655360 inodes, 2620928 blocks
  131046 blocks (5.00%) reserved for the super user
  First data block=0
  Maximum filesystem blocks=2684354560
  80 block groups
  32768 blocks per group, 32768 fragments per group
  8192 inodes per group
  Superblock backups stored on blocks: 
  32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632
  Writing inode tables: done                            
  Creating journal (32768 blocks): done
  Writing superblocks and filesystem accounting information: done
  This filesystem will be automatically checked every 29 mounts or
  180 days, whichever comes first.  Use tune2fs -c or -i to override.
  #-t：指定文件系统类型
  #-b：表示块大小有三种类型分别为 1024/2048/4096
6）、挂载并查看
  # mkdir /myraid5
  # mount /dev/md0 /myraid5
  # cd /myraid5
  # df -h
  Filesystem      Size  Used Avail Use% Mounted on
  /dev/sda2       9.5G  6.6G  2.5G  73% /
  tmpfs           3.9G     0  3.9G   0% /dev/shm
  /dev/sda1       772M   39M  693M   6% /boot
  /dev/md0        9.8G   23M  9.2G   1% /myraid5吧   #新分区
7）、开机自动挂载
  #
  # /etc/fstab
  # Created by anaconda on Sat Dec  5 05:19:21 2015
  #
  # Accessible filesystems, by reference, are maintained under '/dev/disk'
  # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
  #
  UUID=67de25d3-6b6c-469e-b25f-63f6640a162e /                       ext4    defaults        1 1
  UUID=c984f67e-5ac8-4278-9b8a-fd3541df0599 /boot                   ext4    defaults        1 2
  UUID=4fa33c13-d828-42ac-80ed-66577ae37ca8 swap                    swap    defaults        0 0
  tmpfs                   /dev/shm                tmpfs   defaults        0 0
  devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
  sysfs                   /sys                    sysfs   defaults        0 0
  proc                    /proc                   proc    defaults        0 0
  /dev/md0                /myraid5                ext4    defaults        0 0
# mount -a
# mount
  /dev/sda2 on / type ext4 (rw)
  proc on /proc type proc (rw)
  sysfs on /sys type sysfs (rw)
  devpts on /dev/pts type devpts (rw,gid=5,mode=620)
  tmpfs on /dev/shm type tmpfs (rw,rootcontext="system_u:object_r:tmpfs_t:s0")
  /dev/sda1 on /boot type ext4 (rw)
  none on /proc/sys/fs/binfmt_misc type binfmt_misc (rw)
  /dev/md0 on /myraid5 type ext4 (rw)    #已经挂载上了
8）、生成mdadm的配置文件
  /etc/mdadm.conf作为默认的配置文件，主要作用是为了方便的跟踪软RAID的配置，尤其是可以配置监
  控和事件上报选项。Assemble命令也可以使用--config(或者其缩写)来指定配置文件。我们通常可以
  如下命令来建立配置文件。
  #  echo DEVICE /dev/sd[b-h] /dev/sd[i-k]1 > /etc/mdadm.conf
  #  mdadm -Ds >>/etc/mdadm.conf
  #  cat /etc/mdadm.conf
  DEVICE /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh
               /dev/sdi1 /dev/sdj1 /dev/sdk1
  ARRAY /dev/md1 level=raid0 num-devices=3
   UUID=dcff6ec9:53c4c668:58b81af9:ef71989d
  ARRAY /dev/md0 level=raid10 num-devices=6 spares=1
   UUID=0cabc5e5:842d4baa:e3f6261b:a17a477a
  #使用配置文件启动阵列时，mdadm会查询配置文件中的设备和阵列内容，然后启动运行所有能运行RAI
  D阵列。如果指定阵列的设备名字，则只启动对应的阵列。

八、RAID的管理

1、给raid-5新增一个space(空)盘，添加磁盘到阵列中做备用盘（space)
# mdadm -a /dev/md0 /dev/sda8
mdadm: added /dev/sda8
[root@mail myraid5]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sda8[4](S) sda7[3] sda6[1] sda5[0]
      10483712 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
       
unused devices: <none>
# mdadm -D /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Mon Feb  1 13:58:13 2016
     Raid Level : raid5
     Array Size : 10483712 (10.00 GiB 10.74 GB)
  Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
   Raid Devices : 3
  Total Devices : 4
    Persistence : Superblock is persistent
    Update Time : Mon Feb  1 14:48:10 2016
          State : clean 
 Active Devices : 3
Working Devices : 4
 Failed Devices : 0
  Spare Devices : 1
         Layout : left-symmetric
     Chunk Size : 512K
           Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
           UUID : bec67e95:105bc368:092dafe4:d0ad43bc
         Events : 19
    Number   Major   Minor   RaidDevice State
       0       8        5        0      active sync   /dev/sda5
       1       8        6        1      active sync   /dev/sda6
       3       8        7        2      active sync   /dev/sda7
       4       8        8        -      spare   /dev/sda8   #备用盘
2、模拟硬盘故障
# mdadm -f /dev/md0 /dev/sda5
mdadm: set /dev/sda5 faulty in /dev/md0
# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sda8[4] sda7[3] sda6[1] sda5[0](F)
      10483712 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [_UU]
      [>....................]  recovery =  3.5% (185844/5241856) finish=4.0min speed=2064
      9K/sec
      ##正在同步
unused devices: <none>
# mdadm -D /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Mon Feb  1 13:58:13 2016
     Raid Level : raid5
     Array Size : 10483712 (10.00 GiB 10.74 GB)
  Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
   Raid Devices : 3
  Total Devices : 4
    Persistence : Superblock is persistent
    Update Time : Mon Feb  1 14:52:34 2016
          State : clean, degraded, recovering 
 Active Devices : 2
Working Devices : 3
 Failed Devices : 1
  Spare Devices : 1
         Layout : left-symmetric
     Chunk Size : 512K
 Rebuild Status : 19% complete  #同步到19%
           Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
           UUID : bec67e95:105bc368:092dafe4:d0ad43bc
         Events : 24
    Number   Major   Minor   RaidDevice State
       4       8        8        0      spare rebuilding   /dev/sda8 #重建RAID 5
       1       8        6        1      active sync   /dev/sda6
       3       8        7        2      active sync   /dev/sda7
       0       8        5        -      faulty   /dev/sda5
        
# mdadm -D /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Mon Feb  1 13:58:13 2016
     Raid Level : raid5
     Array Size : 10483712 (10.00 GiB 10.74 GB)
  Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
   Raid Devices : 3
  Total Devices : 4
    Persistence : Superblock is persistent
    Update Time : Mon Feb  1 14:55:55 2016
          State : clean 
 Active Devices : 3
Working Devices : 3
 Failed Devices : 1
  Spare Devices : 0
         Layout : left-symmetric
     Chunk Size : 512K
           Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
           UUID : bec67e95:105bc368:092dafe4:d0ad43bc
         Events : 38
    Number   Major   Minor   RaidDevice State
       4       8        8        0      active sync   /dev/sda8   ＃已经同步完成
       1       8        6        1      active sync   /dev/sda6
       3       8        7        2      active sync   /dev/sda7
       0       8        5        -      faulty   /dev/sda5　　　　＃故障盘
     
3、热移除故障的硬盘
# mdadm -r /dev/md0 /dev/sda5
mdadm: hot removed /dev/sda5 from /dev/md0   #移除sda5
# mdadm -D /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Mon Feb  1 13:58:13 2016
     Raid Level : raid5
     Array Size : 10483712 (10.00 GiB 10.74 GB)
  Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
   Raid Devices : 3
  Total Devices : 3
    Persistence : Superblock is persistent
    Update Time : Mon Feb  1 14:57:33 2016
          State : clean 
 Active Devices : 3
Working Devices : 3
 Failed Devices : 0
  Spare Devices : 0
         Layout : left-symmetric
     Chunk Size : 512K
           Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
           UUID : bec67e95:105bc368:092dafe4:d0ad43bc
         Events : 39
    Number   Major   Minor   RaidDevice State
       4       8        8        0      active sync   /dev/sda8
       1       8        6        1      active sync   /dev/sda6
       3       8        7        2      active sync   /dev/sda7
        
4、停止RAID
# mdadm -S /dev/md0   #停止RAID
mdadm: Cannot get exclusive access to /dev/md0:Perhaps a running process, mounted filesys
tem or active volume group?
#上面的错误告诉我们磁盘阵列正在使用中不能停止，我们得先写在RAID再停止
# umount /dev/md0
umount: /myraid5: device is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))  #在/myraid5文件目录中，所以也不行
# cd
# umount /dev/md0   #卸载md0
# mdadm -S /dev/md0 #停止RAID
mdadm: stopped /dev/md0 #停止完成
# mount  #可以看到md0已经不在
/dev/sda2 on / type ext4 (rw)
proc on /proc type proc (rw)
sysfs on /sys type sysfs (rw)
devpts on /dev/pts type devpts (rw,gid=5,mode=620)
tmpfs on /dev/shm type tmpfs (rw,rootcontext="system_u:object_r:tmpfs_t:s0")
/dev/sda1 on /boot type ext4 (rw)
none on /proc/sys/fs/binfmt_misc type binfmt_misc (rw)
5、开启RAID并挂载
# mdadm -A /dev/md0 /dev/sda[6-8]  #开启RAID
mdadm: /dev/md0 has been started with 3 drives.
# mdadm -D /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Mon Feb  1 13:58:13 2016
     Raid Level : raid5
     Array Size : 10483712 (10.00 GiB 10.74 GB)
  Used Dev Size : 5241856 (5.00 GiB 5.37 GB)
   Raid Devices : 3
  Total Devices : 3
    Persistence : Superblock is persistent
    Update Time : Mon Feb  1 15:00:03 2016
          State : clean 
 Active Devices : 3
Working Devices : 3
 Failed Devices : 0
  Spare Devices : 0
         Layout : left-symmetric
     Chunk Size : 512K
           Name : mail.bjwf.com:0  (local to host mail.bjwf.com)
           UUID : bec67e95:105bc368:092dafe4:d0ad43bc
         Events : 39
    Number   Major   Minor   RaidDevice State
       4       8        8        0      active sync   /dev/sda8
       1       8        6        1      active sync   /dev/sda6
       3       8        7        2      active sync   /dev/sda7
  
# cat /proc/mdstat #查看RAID
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sda8[4] sda7[3] sda6[1]
      10483712 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
       
unused devices: <none>
# mount /dev/md0 /myraid5/   #挂载
# ls /myraid5/  #查看
lost+found
6、删除RAID
# umount /dev/md0  #卸载md0
# mount | grep myraid5  #查看卸载成功与否
# mdadm -Ss /dev/md0    #停止raid
mdadm: stopped /dev/md0
# mdadm --zero-superblock /dev/sda[5-8]
# --zero-superblock 加上该选项时，会判断如果该阵列是否包含一个有效的阵列超级块，若有则将
该超级块中阵列信息抹除
# rm -rf /etc/mdadm.conf  #删除RAID配置文件

九、RAID优化
设定良好的stripe值，可以再后期使用时，减少写入数据时对数据块计算的负担，从而提高RAID性能；
1
# mk2fs -j -b 4096 -E stripe=16 /dev/md0 # 设置时，需要用-E选项进行扩展

十、RAID监控
配置每300秒mdadm监控进程查询MD设备一次，当阵列出现错误，会发送邮件给指定的用户，执行事件处理程序并且记录上报的事件到系统的日志文件。使用--daemonise参数，使程序持续再后台运行。如果要发送邮件需要postfix程序运行，当邮件地址被配置为外网地址应先测试是否能发送出去。


# mdadm --monitor --mail=root@localhost --program=/root/md.sh  --syslog --delay=300 /dev/
md0 --daemonise 
3305
# mdadm -f /dev/md0 /dev/sdb
mdadm: set /dev/sdb faulty in /dev/md0
# mdadm -f /dev/md0 /dev/sd
sda   sda1  sda2  sda3  sda4  sda5  sdb   sdc   sdd   sde   sdf   sdg   sdh   sdi
# mdadm -f /dev/md0 /dev/sdb  
mdadm: set /dev/sdb faulty in /dev/md0 
# mdadm -D /dev/md0  
/dev/md0: 
        Version : 0.90 
  Creation Time : Thu Jun 27 21:54:21 2013 
     Raid Level : raid5 
     Array Size : 41942912 (40.00 GiB 42.95 GB) 
  Used Dev Size : 20971456 (20.00 GiB 21.47 GB) 
   Raid Devices : 3 
  Total Devices : 4 
Preferred Minor : 0 
    Persistence : Superblock is persistent
    Update Time : Thu Jun 27 22:03:48 2013
          State : clean, degraded, recovering 
 Active Devices : 2 
Working Devices : 3 
 Failed Devices : 1 
  Spare Devices : 1
         Layout : left-symmetric
     Chunk Size : 64K
 Rebuild Status : 27% complete
           UUID : c7b98767:dbe2c944:442069fc:23ae34d9
         Events : 0.4
    Number   Major   Minor   RaidDevice State
       3       8       64        0      spare rebuilding   /dev/sde 
       1       8       32        1      active sync   /dev/sdc 
       2       8       48        2      active sync   /dev/sdd
       4       8       16        -      faulty spare   /dev/sdb
# tail –f /var/log/messages
Jun 27 22:03:48 localhost kernel:  --- rd:3 wd:2 fd:1 
Jun 27 22:03:48 localhost kernel:  disk 0, o:1, dev:sde 
Jun 27 22:03:48 localhost kernel:  disk 1, o:1, dev:sdc 
Jun 27 22:03:48 localhost kernel:  disk 2, o:1, dev:sdd 
Jun 27 22:03:48 localhost kernel: md: syncing RAID array md0 
Jun 27 22:03:48 localhost kernel: md: minimum _guaranteed_ reconstruction speed: 1000 KB/
sec/disc. 
Jun 27 22:03:48 localhost kernel: md: using maximum available idle IO bandwidth (but not 
more than 200000 KB/sec) for reconstruction. 
Jun 27 22:03:49 localhost kernel: md: using 128k window, over a total of 20971456 blocks. 
Jun 27 22:03:48 localhost mdadm[3305]: RebuildStarted event detected on md device /dev/md
0 
Jun 27 22:03:49 localhost mdadm[3305]: Fail event detected on md device /dev/md0, compone
nt device /dev/sdb
# mail
Mail version 8.1 6/6/93.  Type ? for help. 
"/var/spool/mail/root": 4 messages 4 new 
>N  1 logwatch@localhost.l  Wed Jun 12 03:37  43/1629  "Logwatch for localhost.localdomai
n (Linux)" 
 N  2 logwatch@localhost.l  Wed Jun 12 04:02  43/1629  "Logwatch for localhost.localdomai
 n (Linux)" 
 N  3 logwatch@localhost.l  Thu Jun 27 17:58  43/1629  "Logwatch for localhost.localdomai
 n (Linux)" 
 N  4 root@localhost.local  Thu Jun 27 22:03  32/1255  "Fail event on /dev/md0:localhost.
 localdomain" 
& 4 
Message 4: 
From root@localhost.localdomain  Thu Jun 27 22:03:49 2013 
Date: Thu, 27 Jun 2013 22:03:49 +0800 
From: mdadm monitoring <root@localhost.localdomain> 
To: root@localhost.localdomain 
Subject: Fail event on /dev/md0:localhost.localdomain
This is an automatically generated mail message from mdadm
running on localhost.localdomain
A Fail event had been detected on md device /dev/md0.
It could be related to component device /dev/sdb.
Faithfully yours, etc.
P.S. The /proc/mdstat file currently contains the following:
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdd[2] sde[3] sdc[1] sdb[4](F) 
      41942912 blocks level 5, 64k chunk, algorithm 2 [3/2] [_UU] 
      [>....................]  recovery =  0.9% (200064/20971456) finish=1.7min speed=200
      064K/sec 
unused devices: <none>

十一、RAID扩展
如果在创建阵列时不想使用整个块设备，可以指定用于创建RAID阵列每个块设备使用的设备大小。然后在阵列需要扩展大小时，使用模式--grow(或者其缩写-Q)以及--size参数(或者其缩写-z) 在加上合适的大小数值就能分别扩展阵列所使用每个块设备的大小。


# mdadm -C /dev/md0 -l5 -n3 /dev/sd[b-d] -x1 /dev/sde --size=1024000
# -- size单位为KB
# mdadm -C /dev/md0 -l5 -n3 /dev/sd[b-d] -x1 /dev/sde --size=1024000 
mdadm: array /dev/md0 started.
# mdadm -D /dev/md0                                              
/dev/md0:  
        Version : 0.90  
  Creation Time : Thu Jun 27 22:24:51 2013  
     Raid Level : raid5  
     Array Size : 2048000 (2000.34 MiB 2097.15 MB)  
  Used Dev Size : 1024000 (1000.17 MiB 1048.58 MB)  
   Raid Devices : 3  
  Total Devices : 4  
Preferred Minor : 0  
    Persistence : Superblock is persistent
    Update Time : Thu Jun 27 22:24:51 2013 
          State : clean, degraded, recovering  
 Active Devices : 2  
Working Devices : 4  
 Failed Devices : 0  
  Spare Devices : 2
         Layout : left-symmetric 
     Chunk Size : 64K
 Rebuild Status : 73% complete
           UUID : 78e766fb:776d62ee:d22de2dc:d5cf5bb9 
         Events : 0.1
    Number   Major   Minor   RaidDevice State 
       0       8       16        0      active sync   /dev/sdb  
       1       8       32        1      active sync   /dev/sdc  
       4       8       48        2      spare rebuilding   /dev/sdd
       3       8       64        -      spare   /dev/sde 
# mdadm --grow /dev/md0 --size=2048000 #扩展大小
# mdadm -D /dev/md0               
/dev/md0:
        Version : 0.90
  Creation Time : Thu Jun 27 22:24:51 2013
     Raid Level : raid5
     Array Size : 4096000 (3.91 GiB 4.19 GB)
  Used Dev Size : 2048000 (2000.34 MiB 2097.15 MB)
   Raid Devices : 3
  Total Devices : 4
Preferred Minor : 0
    Persistence : Superblock is persistent
    Update Time : Thu Jun 27 22:28:34 2013
          State : clean, resyncing
 Active Devices : 3
Working Devices : 4
 Failed Devices : 0
  Spare Devices : 1
         Layout : left-symmetric
     Chunk Size : 64K
 Rebuild Status : 90% complete
           UUID : 78e766fb:776d62ee:d22de2dc:d5cf5bb9
         Events : 0.3
    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        -      spare   /dev/sde