FROM debian:stretch

MAINTAINER Stephane Mullings

ENV PHP_RUN_DIR=/opt/php-5.4/var/run \
    PHP_LOG_DIR=/var/log/php \
    PHP_CONF_DIR=/opt/php-5.4/etc \
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
  && wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-fpm_5.4.45-0+deb7u12_amd64.deb -O php-fpm_5.4.45.deb \
  && dpkg -i php-fpm_5.4.45.deb

RUN cp /usr/local/src/php5.4-build/php-5.4.45/php.ini-production /opt/php-5.4/lib/php.ini \
#  && cp /opt/php-5.4/etc/php-fpm.conf.default /opt/php-5.4/etc/php-fpm.conf
#  && cp /opt/php-5.4/etc/php-fpm.d/www.conf.default /opt/php-5.4/etc/php-fpm.d/www.conf
# COPY ./config/www.conf /opt/php-5.4/etc/php-fpm.d/www.conf
# COPY ./config/php-5.4-fpm.service /lib/sytemd/system/php-fpm

#RUN systemctl enable php-fpm \
 #   && systemctl daemon-reload

WORKDIR /var/www

EXPOSE 9000

# PHP_DATA_DIR store sessions
VOLUME ["${PHP_RUN_DIR}", "${PHP_DATA_DIR}"]

#CMD ['php-fpm']