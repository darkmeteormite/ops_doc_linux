一、安装pyenv

    #系统环境
    # cat /etc/redhat-release 
    CentOS Linux release 7.2.1511 (Core)
     
    1、安装git
    # yum -y install git
    
    2、安装pyenv
    # curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
    或者参考：https://github.com/yyuu/pyenv-installer
    
    3、配置环境变量
    # vim /etc/profile.d/pyenv.sh   #定义的全局环境变量
    export PATH="/root/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    # . /etc/profile.d/pyenv.sh   #载入一下

二、安装python

    1、安装编译工具
    # yum -y install gcc make patch
    
    2、安装依赖环境
    # yum -y install gdbm-devel openssl-devel sqlite-devel readline-devel zlib-devel bzip2-devel
   
    3、升级pyenv（最新版本3.2也许没有在pyenv中）
    # pyenv update
   
    4、安装python3.5.2
    # pyenv install 3.5.2   #这块可能安装比较慢，需要等待一会。
   
    5、使用国内镜像安装
    # mkdir ~/.pyenv/cache
    # wget -c http://7d9qvq.com1.z0.glb.clouddn.com/Python-3.5.2.tgz 
    #  mv Python-3.5.2.tar.gz ~/.pyenv/cache/Python-3.5.2.tar.gz 
    # pyenv install 3.5.2

三、pyenv基本使用方法

    1、local命令
    # pyenv versions
    * system (set by /root/.pyenv/version)
      3.5.2
    # pyenv local 3.5.2    #切换到3.5.2
    # python -V
    Python 3.5.2    #已经切换成功
    
    2、global命令
    # pyenv global 3.5.2  #全局切换至3.5.2版本，不建议使用这条命令
    
    3、virtualenv命令
    # pyenv virtualenv 3.5.2 bjwf  #以3.5.2为模版创建python3.5.2虚拟环境bjwf
    # ll ~/.pyenv/versions/
         3.5.2
         bjwf -> /root/.pyenv/versions/3.5.2/envs/bjwf
    
    4、uninstall命令
    # pyenv uninstall bjwf    #卸载某个版本（包括虚拟环境版本）
    pyenv-virtualenv: remove /root/.pyenv/versions/3.5.2/envs/bjwf? y
    # ll ~/.pyenv/versions/
    drwxr-xr-x 7 root root 63 Jun 30 05:50 3.5.2
   
    5、其他命令
    # pyenv install –list   #列出可安装的版本 
    # pyenv rehash           #更新数据库 
    # pyenv versions         #查看当前已安装的所有版本 
    # pyenv global 3.5.2     #建议永远不要执行 
    # pyenv help             #查看帮助
    Usage: pyenv <command> [<args>]
 
    Some useful pyenv commands are:
       commands    List all available pyenv commands
       local       Set or show the local application-specific Python version
       global      Set or show the global Python version
       shell       Set or show the shell-specific Python version
       install     Install a Python version using python-build
       uninstall   Uninstall a specific Python version
       rehash      Rehash pyenv shims (run this after installing executables)
       version     Show the current Python version and its origin
       versions    List all Python versions available to pyenv
       which       Display the full path to an executable
       whence      List all Python versions that contain the given executable
     
    See `pyenv help <command>' for information on a specific command.
    For full documentation, see: https://github.com/yyuu/pyenv#readme

四、安装ipython，jupyter

    1、配置国内镜像（pipe）
    # mkdir ~/.pip
    # vim ~/.pip/pip.conf
    [global]      #阿里
    index-url = http://mirrors.aliyun.com/pypi/simple/
    trusted-host = mirrors.aliyum.com
    
    [global]      #豆瓣
    index-url = http://pypi.douban.com/simple
    trusted-host = pypi.douban.com
    disable-pip-version-check = true
    timeout = 120

    
    2、安装ipython
    # pip install --upgrade pip   #我这块提升要先安装这个
    # pip install ipyton
    # ipython   #可以使用了
    Python 3.5.2 (default, Jun 30 2016, 05:24:18) 
    Type "copyright", "credits" or "license" for more information.
 
    IPython 4.2.1 -- An enhanced Interactive Python.
    ?         -> Introduction and overview of IPython's features.
    %quickref -> Quick reference.
    help      -> Python's own help system.
    object?   -> Details about 'object', use 'object??' for extra details.
     
    In [1]: print('hello world')
    hello world
    
    3、安装jupyter
    # pip install jupyter
    # # jupyter-notebook --ip=0.0.0.0 --port=8888 --no-browser    #前台运行
    [I 06:24:43.608 NotebookApp] Serving notebooks from local directory: /root
    [I 06:24:43.609 NotebookApp] 0 active kernels 
    [I 06:24:43.609 NotebookApp] The Jupyter Notebook is running at: http://0.0.0.0:8888/
    [I 06:24:43.609 NotebookApp] Use Control-C to stop this server and shut down all kernels 
    [I 06:24:58.443 NotebookApp] 302 GET / (192.168.110.253) 2.11ms
    [I 06:25:26.260 NotebookApp] Creating new notebook in 
     
    # nohup jupyter-notebook --ip=0.0.0.0 --port=8888 --no-browser &      #后台运行

    