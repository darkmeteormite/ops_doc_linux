FROM centos:7.6.1810

LABEL maintainer="zhangqiang@huoban.com"

RUN curl -fSL http://mirrors.aliyun.com/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo \
    && yum -y install make \
                gcc-c++ \
                kernel-devel \
                m4 \
                ncurses-devel \
                openssl-devel \
                git \
                xmlto \
                ncurses \
                zip \
                unzip \
                gcc \
                autoconf \
                libxslt-devel \
                wget \
    && cd /usr/local/src \
    && wget https://github.com/erlang/otp/archive/OTP-22.0.7.tar.gz \
    && tar xf OTP-22.0.7.tar.gz \
    && cd otp-OTP-22.0.7 \
    && ./otp_build autoconf \
    && ./configure \
                --disable-dynamic-ssl-lib \
                --disable-hipe \
                --disable-sctp \
                --disable-silent-rules \
                --enable-clock-gettime \
                --enable-hybrid-heap \
                --enable-kernel-poll \
                --enable-shared-zlib \
                --enable-smp-support \
                --enable-threads \
                --with-microstate-accounting=extra \
                --without-common_test \
                --without-debugger \
                --without-dialyzer \
                --without-diameter \
                --without-edoc \
                --without-erl_docgen \
                --without-erl_interface \
                --without-et \
                --without-eunit \
                --without-ftp \
                --without-hipe \
                --without-jinterface \
                --without-megaco \
                --without-observer \
                --without-odbc \
                --without-reltool \
                --without-ssh \
                --without-tftp \
                --without-wx \
    && make -j "$(getconf _NPROCESSORS_ONLN)" \
    && make install \
    && RABBITMQ_HOME=/opt/rabbitmq \
    && RABBITMQ_VERSION=3.7.16 \
    && groupadd -g 101 -r rabbitmq \
    && useradd -u 101 -g 101 -d /var/lib/rabbitmq rabbitmq \
    && mkdir -p /var/lib/rabbitmq /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq /opt/rabbitmq \
    && chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq /opt/rabbitmq \
    && chmod 777 /var/lib/rabbitmq /etc/rabbitmq /tmp/rabbitmq-ssl /var/log/rabbitmq \
    && ln -sf /var/lib/rabbitmq/.erlang.cookie /root/.erlang.cookie \
    && cd /usr/local/src \
    && wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v$RABBITMQ_VERSION/rabbitmq-server-generic-unix-latest-toolchain-$RABBITMQ_VERSION.tar.xz \
    && tar --extract --file "rabbitmq-server-generic-unix-latest-toolchain-3.7.16.tar.xz" --directory "$RABBITMQ_HOME" --strip-components 1 \
    && rm -rf /usr/local/src/* \
    && grep -qE '^SYS_PREFIX=\$\{RABBITMQ_HOME\}$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults" \
    && sed -i 's/^SYS_PREFIX=.*$/SYS_PREFIX=/' "$RABBITMQ_HOME/sbin/rabbitmq-defaults" \
    && grep -qE '^SYS_PREFIX=$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults" \
    && chown -R rabbitmq:rabbitmq "$RABBITMQ_HOME" \
    && ${RABBITMQ_HOME}/sbin/rabbitmq-plugins enable rabbitmq_management \
    && ln -sf /opt/rabbitmq/plugins /plugins \
    && yum clean all

ENV LANG="zh_CN.UTF-8"

COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf

EXPOSE 4369 5671 5672 15672 25672
CMD ["/opt/rabbitmq/sbin/rabbitmq-server"]
