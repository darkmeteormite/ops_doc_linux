一个Opcache的推荐配置:

zend_extension=opcache.so
opcache.enable_cli=1
opcache.memory_consumption=128      //共享内存大小, 这个根据你们的需求可调
opcache.interned_strings_buffer=8   //interned string的内存大小, 也可调
opcache.max_accelerated_files=4000  //最大缓存的文件数目
opcache.revalidate_freq=60          //60s检查一次文件更新
opcache.fast_shutdown=1             //打开快速关闭, 打开这个在PHP Request Shutdown的时候
                                    //   会收内存的速度会提高
opcache.save_comments=0             //不保存文件/函数的注释