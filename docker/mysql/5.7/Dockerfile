FROM centos:7.6.1810

LABEL maintainer="zhangqiang@huoban.com"

ENV MYSQL_VERSION 5.7.22

RUN curl -fSL http://mirrors.aliyun.com/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo \
 \
    && yum -y install vim \ 
                  gcc \
                  gcc-c++ \
                  make \
                  cmake \
                  libgcrypt \
                  openssl-devel \
                  openssl098e \
                  ncurses-devel \
                  bison \
                  ncurses-libs \
                  libaio \
                  unzip \
                  perl-Module-Install \
                  readline-devel \
                  wget \
    && groupadd -g 306 -r mysql \
    && useradd -u 306 -g 306 -s /sbin/nologin mysql \
    && cd /usr/local/src \
    && wget http://www.sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz \
    && tar -zxvf boost_1_59_0.tar.gz -C /usr/local \
    && mv /usr/local/boost_1_59_0 /usr/local/boost \
    && wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-${MYSQL_VERSION}.tar.gz \
    && tar xf mysql-${MYSQL_VERSION}.tar.gz \
    && cd mysql-${MYSQL_VERSION} \
    && cmake \
	-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
	-DMYSQL_DATADIR=/var/lib/mysql \
	-DWITH_BOOST=/usr/local/boost \
	-DSYSCONFDIR=/etc \
	-DWITH_INNOBASE_STORAGE_ENGINE=1 \
	-DWITH_PARTITION_STORAGE_ENGINE=1 \
	-DWITH_FEDERATED_STORAGE_ENGINE=1 \
	-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
	-DWITH_MYISAM_STORAGE_ENGINE=1 \
	-DENABLED_LOCAL_INFILE=1 \
	-DENABLE_DTRACE=0 \
	-DDEFAULT_CHARSET=utf8 \
	-DDEFAULT_COLLATION=utf8_general_ci \
	-DWITH_EMBEDDED_SERVER=1
    && make \
    && make install \
    && /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/var/lib/mysql --basedir=/usr/local/mysql \
    && ln -sv /usr/local/mysql/include /usr/include/mysqld \
    && echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf \
    && ldconfig \
    && ln -sv /usr/local/mysql/bin/mysqld /bin/mysqld

COPY my.cnf /etc/my.cnf

VOLUME /var/lib/mysql

EXPOSE 3306
CMD ["mysqld"]
