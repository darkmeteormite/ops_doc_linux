Git是什么？
Git是目前世界上最先进的分布式版本控制系统（没有之一）。
Git有什么特点？简单来说就是：高端大气上档次！

1、创建版本库
```
# mkdir bjwf125
# cd bjwf125
# git init   #初始化仓库
把文件添加到仓库
例如：
	# vim readme.txt
		Git is a version control system.
		Git is free software.
# git add readme.txt   #把文件添加到仓库
# git commit -m 'add file readme.txt'    #把文件提交到仓库
```
2、时光穿梭机
```
要随时掌握工作区的状态，使用git status命令。
如果git status告诉你有文件被修改过，用git diff可以查看修改内容。
HEAD指向的版本就是当前版本，因此，Git允许我们在版本的历史之间穿梭，使用命令git reset --hard commit_id。
穿梭前，用git log可以查看提交历史，以便确定要回退到哪个版本。
要重返未来，用git reflog查看命令历史，以便确定要回到未来的哪个版本。

撤销修改
# git checkout -- readme.txt
命令git checkout -- readme.txt意思就是，把readme.txt文件在工作区的修改全部撤销，这里有两种情况：
一种是readme.txt自修改后还没有被放到暂存区，现在，撤销修改就回到和版本库一模一样的状态；
一种是readme.txt已经添加到暂存区后，又作了修改，现在，撤销修改就回到添加到暂存区后的状态。
总之，就是让这个文件回到最近一次git commit或git add时的状态。

总结
场景1：当你乱改了工作区某个文件的内容，想直接丢弃工作区的修改时，用命令git checkout --file。
场景2：当你不但乱改了工作区某个文件的内容，还添加到了暂存区时，想丢弃修改，分两步，第一步用命令git reset HEAD file，就回到了场景1，第二步按场景1操作。
场景3：已经提交了不合适的修改到版本库时，想要撤销本次提交，可以使用git reset --hard HEAD^回退上一个版本，不过前提是没有推送到远程库。

删除文件：
# rm file        #先删除文件
# git rm file    #第二步是用命令删掉
# git commit -m 'remove file'   #第三步是从版本库中删除文件
*如果删错了，版本库中还有，可以很轻松地把误删的文件恢复到最新版本
# git checkout -- file
*git checkout其实是用版本库里地版本替换工作区的版本，无论工作区是修改还是删除，都可以“一键还原”。
*命令git rm用于删除一个文件，如果一个文件已经提交到版本库，那么你永远不用担心误删，但是要小心，你只能恢复文件到最新版本，你会丢失最近一次提交后你修改的内容。
```
3、远程仓库
```
# git push -u origin master     #把本地库的内容推送到远程，用git push命令

*
要关联一个远程库，使用命令git remote add origin git@server-name:path/repo-name.git;
关联后，使用命令git push -u origin master 第一次推送master分支的所有内容；
此后，每次本地提交后，只要有必要，就可以使用命令git push origin master推送最新修改；
#分布式版本系统的最大好处之一是在本地工作完全不需要考虑远程库的存在，也就是没有联网都可以正常工作，而SVN在没有联网的时候是拒绝干活的！当有网络的时候，再把本地提交推送一下就完成了同步，真是太方便了！

克隆远程库
要克隆一个仓库，首先必须知道仓库的地址，然后使用git clone命令克隆。
Git支持多种协议，包括https，但通过ssh支持的原生git协议速度最快。
```

4、分支管理
```
创建分支
# git checkout -b dev
Switched to a new branch 'dev'
注：git checkout命令加上—b参数表示创建并切换，相当于以下两条命令：
# git branch dev
# git checkout dev
然后用git branch命令查看当前分支
# git branch
* dev
  master
#git branch命令会列出所有分支，当前分支前面会标一个*号。

合并分支
# git merge dev   #把dev分支的工作成果合并到master分支上
删除分支
# git branch -d dev  

合并创建分支到主分支 

在创建的分支中
# git checkout NAME-OF-BRANCH
# git merge master

在主分支中
# git checkout master
# git merge NAME-OF-BRANCH

查看当前分支
# git rev-parse --abbrev-ref HEAD

Git鼓励大量使用分支
查看分支：git branch
创建分支：git branch <name>
切换分支：git checkout <name>
创建+切换分支：git checkout -b <name>
合并某分支到当前分支：git merge <name>
删除分支：git branch -d <name>

解决冲突
当Git无法自动合并分支时，就必须首先解决冲突。解决冲突后，再提交，合并完成。
用git log --graph命令可以看到分支合并图。

合并分支时，加上--no-ff参数就可以用普通模式合并，合并后的历史有分支，能看出来曾经做过合并，而fast forward合并就看不出来曾经做过合并。

储藏功能
# git stash   #把当前工作现场储藏起来，等以后恢复工作继续工作。
# git stash list  #查看工作现场
*Git把stash内容存在某个地方了，如果需要恢复，有两个办法：
一是用 git stash apply 恢复，但是恢复后，stash的内容并不删除，需要用 git stash drop 来删除；
另一种方式是用 git stash pop ,恢复的同时也把stash的内容删了。
*可以使用多长stash，恢复的时候，先用git stash list查看，然后恢复指定的stash，用命令：
# git stash apply stash@{0}

Feature分支
开发一个新feature，最好新建一个分支；
如果要丢弃一个没有被合并过的分支，可以通过git branch -D <name>强行删除。

多人协作
	多人协作的工作模式：
		首先，可以试图用 git push origin branch-name 推送自己的提交。
		如果推送失败，则因为远程分支比你的本地更新，需要用 git pull 试图合并。
		如果合并有冲突，则解决冲突，并在本地提交。
		没有冲突或者解决掉冲突后，再用 git push origin branch-name 推送就能成功。
		如果 git pull 提示"no tracking information",则说明本地分支和远程分支的链接关系没有创建，用命令git branch --set-upstream branch-name origin/branch-name。
	总结：
		查看远程库信息，使用 git remote -v;	
		本地新建的分支如果不推送到远程，对其他人都是不可见的；
		从本地推送分支，使用 git push origin branch-name,如果推送失败，先用 git pull 抓取远程的新提交；
		在本地创建和远程分支对应的分支，使用git checkout -b branch-name origin/branch-name，本地和远程分支的名称最好一致；
		建立本地分支和远程分支的关联，使用git branch --set-upstream branch-name origin/branch-name;
		从远程抓取分支，使用 git pull，如果有冲突，要先处理冲突。	
```

5、标签管理

```
创建标签
	# git tag <name>  #用于新建一个标签，默认为HEAD，也可以指定一个commit id;
	# git tag -a <tagname> -m "babababa....."  #可以指定标签信息；
	# git tag -s <tagname> -m "babababa....."  #可以用PGP签名标签；
	# git tag  #可以查看所有标签。
	# git show <tagname>   #可以看具体标签说明
	# git tag -d <tagname>    #删除标签
	*创建的标签一般只存储在本地，不会自动推送到远程，所有打错的标签可以删除。
	*如果要推送某个标签到远程，使用git push origin <tagname>;
	一次推送全部尚未推送到远程的本地标签：
	# git push origin --tags
	删除远程标签
	# git push origin :refs/tags/<tagname>
```

6、自定义git

```
让Git显示颜色： $ git config --global color.ui true

忽略某些文件时，需要编写 .gitignore;
.gitignore文件本身要放在版本库里，并且可以对.gitignore做版本管理。

配置别名:
	$ git config --global alias.st status
	# --global参数是全局参数，也就是这些命令在这台电脑的所有Git仓库下都有用
	配置文件: .git/config

