FROM debian:stretch

MAINTAINER Stephane Mullings

ENV PHP_RUN_DIR=/run/php \
    PHP_LOG_DIR=/var/log/php \
    PHP_CONF_DIR=/etc/php5 \
    PHP_DATA_DIR=/var/lib/php5

RUN apt-get update \
  && apt install -y build-essential \
                    checkinstall \
                    zip \
                    autoconf \
                    sed \

  && apt install -y libfcgi-dev \
                    libfcgi0ldbl \
                    libmcrypt-dev \
                    libssl-dev \
                    libc-client2007e-dev \
                    libkrb5-dev \
                    libcurl4-openssl-dev \
  && apt install -y libxml2-dev \
                    libcurl4-openssl-dev \
                    libpcre3-dev \
                    libbz2-dev \
                    libjpeg-dev \
                    libpng-dev \
                    libfreetype6-dev \
                    libmcrypt-dev \
                    libmhash-dev \
                    freetds-dev \
                    libmariadbclient-dev-compat \
                    unixodbc-dev \
                    libxslt1-dev \
  && apt install -y wget

##compile old openssl

RUN cd /opt \
  && wget https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz \
  && tar -xzf openssl-1.0.1u.tar.gz \
  && cd openssl-1.0.1u \
  && ./config shared --openssldir=/usr/local/openssl/ enable-ec_nistp_64_gcc_128 \
  && make depend \
  && make \
  && make install \
  && ln -s /usr/local/openssl/lib /usr/local/openssl/lib/x86_64-linux-gnu

## compile old curl
RUN cd /opt \
  && wget https://curl.haxx.se/download/curl-7.26.0.tar.gz \
  && tar -xzf curl-7.26.0.tar.gz \
  && ls -al \
  && chown -R root:root curl-7.26.0 \
  && ls -al \
  && mv curl-7.26.0 curl \
  && ls -al \
  && cd curl \
  && env PKG_CONFIG_PATH=/usr/local/openssl/lib/pkgconfig LDFLAGS=-Wl,-rpath-link=/usr/local/openssl/lib \
  && ./configure \
    --with-ssl=/usr/local/openssl/lib \
    --with-zlib \
    --prefix=/usr/local/curl \
  && make \
  && make install

RUN mkdir -p /opt/php-5.4 \
  && mkdir -p /var/www \
  && mkdir -p /usr/local/src/php5.4-build \
  && cd /usr/local/src/php5.4-build \
  && wget http://fr2.php.net/get/php-5.4.45.tar.gz/from/this/mirror -O php-5.4.45.tar.gz \
  && tar xzf php-5.4.45.tar.gz \
  && cd php-5.4.45 \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" './configure'  --prefix=/opt/php-5.4 '--with-zlib-dir' '--with-freetype-dir' '--enable-fpm' '--enable-mbstring' '--with-libxml-dir=/usr' '--enable-soap' '--enable-calendar' '--with-curl=/usr/local/curl' '--with-mcrypt' '--with-zlib' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-mbregex' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-mysql' '--with-pdo-mysql' '--with-mysqli' '--with-jpeg-dir=/usr' '--with-png-dir=/usr' '--enable-gd-native-ttf' '--enable-cgi' '--with-pear' '--enable-memcache' '--with-openssl=/usr/local/openssl'  '--with-kerberos'  '--with-libdir=lib/x86_64-linux-gnu' '--enable-fpm' '--with-fpm-user=www-data' '--with-fpm-group=www-data' '--with-mysql-sock' \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" make \
  && make install

RUN mkdir -p /usr/local/src/php-fpm5.4 \
  && cd /usr/local/src/php-fpm5.4

# install libdb dependency
RUN wget http://security.debian.org/debian-security/pool/updates/main/d/db/libdb5.1_5.1.29-5+deb7u1_amd64.deb -O libdb5.1.deb \
  && dpkg -i libdb5.1.deb

# install libonig dependency
RUN wget http://security.debian.org/debian-security/pool/updates/main/libo/libonig/libonig2_5.9.1-1+deb7u1_amd64.deb -O libonig2_5.9.1.deb \
   && dpkg -i libonig2_5.9.1.deb

# install  libqdbm dependecy
RUN wget http://ftp.us.debian.org/debian/pool/main/q/qdbm/libqdbm14_1.8.78-2_amd64.deb -O libqdbm14.deb \
  && dpkg -i libqdbm14.deb

# install libssl1 dependency
RUN wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb7u3_amd64.deb -O libssl1.0.0.deb \
  && dpkg -i libssl1.0.0.deb

# install mime-support dependecy
RUN wget http://ftp.us.debian.org/debian/pool/main/m/mime-support/mime-support_3.52-1+deb7u1_all.deb -O mime-support.deb \
  && dpkg -i mime-support.deb

# install ucf dependency
RUN wget http://ftp.us.debian.org/debian/pool/main/u/ucf/ucf_3.0025+nmu3_all.deb -O ucf.deb \
  && dpkg -i ucf.deb

# install php5-common dependency
RUN wget http://ftp.us.debian.org/debian/pool/main/p/psmisc/psmisc_22.19-1+deb7u1_amd64.deb -O psmisc.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libp/libperl4-corelibs-perl/libperl4-corelibs-perl_0.003-1_all.deb -O libperl4-corelibs-perl.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/l/lsof/lsof_4.86+dfsg-1_amd64.deb -O lsof.deb \
  && wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-common_5.4.45-0+deb7u12_amd64.deb -O php5-common.deb \
  && dpkg -i psmisc.deb \
  && dpkg -i libperl4-corelibs-perl.deb \
  && dpkg -i lsof.deb \
  && dpkg -i php5-common.deb

# install php-fpm
RUN wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-fpm_5.4.45-0+deb7u12_amd64.deb -O php-fpm_5.4.45.deb \
  && dpkg -i php-fpm_5.4.45.deb

RUN cp /usr/local/src/php5.4-build/php-5.4.45/php.ini-production /etc/php5/php.ini \
  && cp /opt/php-5.4/etc/php-fpm.conf.default /etc/php5/fpm/php-fpm.conf
#  && cp /opt/php-5.4/etc/php-fpm.d/www.conf.default /etc/php-fpm.d/www.conf
# COPY ./config/www.conf /opt/php-5.4/etc/php-fpm.d/www.conf
# COPY ./config/php-5.4-fpm.service /lib/sytemd/system/php-fpm

#RUN systemctl enable php5-fpm \
#  && systemctl daemon-reload

WORKDIR /var/www

EXPOSE 9000

# PHP_DATA_DIR store sessions
VOLUME ["${PHP_RUN_DIR}", "${PHP_DATA_DIR}"]

CMD ['/etc/init.d/php5-fpm start']