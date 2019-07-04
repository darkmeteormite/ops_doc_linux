安装node
1、下载安装包
# wget https://nodejs.org/dist/v0.12.0/node-v0.12.0.tar.gz
2、编译安装
# tar xf node-v0.12.0.tar.gz
# cd node-v0.12.0
# ./configure --prefix=/usr/local/node
# make && make install



一、npm的安装、卸载、升级、配置
本地安装 vs 全局安装（重要）
node包的安装分两种：本地安装、全局安装。两者的区别如下，后面会通过简单例子说明
  ● 本地安装：package会被下载到当前所在目录，也只能在当前目录下使用。
  ● 全局安装：package会被下载到到特定的系统目录下，安装的package能够在所有目录下使用。
npm install pkg - 本地安装
npm install -g pkg- 全局安装
安装最新版本的grunt-cli
npm install grunt-cli
安装0.1.9版本的grunt-cli
npm install grunt-cli@"0.1.9"
通过package.json进行安装
如果我们的项目依赖了很多package，一个一个地安装那将是个体力活。我们可以将项目依赖的包都在package.json这个文件里声明，然后一行命令搞定
npm install
其他package安装命令
运行如下命令，列出所有 npm install 可能的参数形式
npm install --help
输出如下
npm install <tarball file>
npm install <tarball url>
npm install <folder>
npm install <pkg>
npm install <pkg>@<tag>
npm install <pkg>@<version>
npm install <pkg>@<version range>
卸载grunt-cli
比如卸载grunt-cli
npm uninstall grunt-cli
卸载0.1.9版本的grunt-cli
npm uninstall grunt-cli@"0.1.9"
查看安装了哪些包
npm ls     #本地安装
npm ls -g  #查看全局安装了那些包
查看特定包得信息
npm ls grunt-cli -g
# npm info which -g  #查看更详细的信息
更新包
npm update which -g
搜索包
npm search which 
npm发布
npm publish <tarball>
npm publish <folder>




npm            https://github.com/npm/npm/tags

node           http://nodejs.org/

1，下载.exe,到任意目录，将目录地址配置为环境变量

2，下载npm，解压到任意目录， node install cli， 进入解压的目录  运行node cli.js install -gf安装npm。


npm config set prefix "D:\node\node-global"<!--配置全局安装目录-->
npm config set cache "D:\node\node-cache"<!--配置缓存目录-->
配置环境变量path添加    node.exe  的目录文件夹路径 和  D:\node\node-global （npm设置的全局安装的目录文件夹路径）

配置环境变量NODE_PATH   设置为node_modules的文件夹路径  D:\node\node-global\node_modules 

设置npm国内镜像

npm config set registry http://registry.npmjs.vitecho.com
 也可使用淘宝的npm镜像

npm install -g cnpm --registry=https://registry.npm.taobao.org

