FROM centos:7.6.1810

LABEL maintainer="zhangqiang@huoban.com"

ENV MYSQL_VERSION 5.6.29-76.2

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
    && wget https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-${MYSQL_VERSION}/source/tarball/percona-server-${MYSQL_VERSION}.tar.gz \
    && tar xf percona-server-${MYSQL_VERSION}.tar.gz \
    && cd percona-server-${MYSQL_VERSION} \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc/my.cnf -DMYSQL_TCP_PORT=3306 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLE_DTRACE=0 -DWITH_EXTRA_CHARSETS=all \
    && make \
    && make install \
    && /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/var/lib/mysql --basedir=/usr/local/mysql \
    && cp /usr/local/mysql/



VOLUME /var/lib/mysql

EXPOSE 3306
CMD ["mysqld"]
