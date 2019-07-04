xfsdump [-L S_label] [-M M_label] [-l #] [-f 备份档] 待备份资料
选项与参数:
	-L :xfsdump 会纪录每次备份的 session 标头，这里可以填写针对此文件系统的简易说明
	-M :xfsdump 可以纪录储存媒体的标头，这里可以填写此媒体的简易说明
	-l :是 L 的小写，就是指定等级~有 0~9 共 10 个等级喔! (预设为 0，即完整备份)
	-f :有点类似 tar 啦!后面接产生的文件，亦可接例如 /dev/st0 装置文件名或其他一般文件档名等 
	-I :从 /var/lib/xfsdump/inventory 列出目前备份的信息状态

xfsrestore [-f 备份文件] -i 待复原目录
选项与参数:
	-I :跟 xfsdump 相同的输出!可查询备份数据，包括 Label 名称与备份时间等
	-f :后面接的就是备份档!企业界很有可能会接 /dev/st0 等磁带机!我们这里接档名! 
	-L :就是 Session 的 Label name 喔!可用 -I 查询到的数据，在这个选项后输入!
	-s :需要接 特定目录，亦即仅复原 一个文件或目录之意!
	-r :如果是用文件来储存备份数据，那这个就不需要使用。如果是一个磁带内有多个文件，
	需要这东西来达成累积复原
	-i :进入互动模式，进阶管理员使用的!一般我们不太需要操作它!


dd if="input_file" of="output_file" bs="block_size" count="number" 
选项与参数:
	if :就是 input file 啰~也可以是装置喔!
	of :就是 output file 喔~也可以是装置;
	bs :规划的一个 block 的大小，若未指定则预设是 512 bytes(一个 sector 的大小) count:多少个 bs 的意思。

# cpio -ovcB > [file|device] <==备份 
# cpio -ivcdu < [file|device] <==还原 
# cpio -ivct < [file|device] <==察看 备份会使用到的选项与参数:
-o :将数据 copy 输出到文件或装置上
-B :让预设的 Blocks 可以增加至 5120 bytes ，预设是 512 bytes !
这样的好处是可以让大文件的储存速度加快(请参考 i-nodes 的观念) 还原会使用到的选项与参数:
-i :将数据自文件或装置 copy 出来系统当中
-d :自动建立目录!使用 cpio 所备份的数据内容不见得会在同一层目录中，因此我们
必须要让 cpio 在还原时可以建立新目录，此时就得要 -d 选项的帮助! -u :自动的将较新的文件覆盖较旧的文件!
-t :需配合 -i 选项，可用在"察看"以 cpio 建立的文件或装置的内容
一些可共享的选项与参数:
-v :让储存的过程中文件名可以在屏幕上显示 -c :一种较新的 portable format 方式储存