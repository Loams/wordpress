FROM debian:stretch

MAINTAINER Stephane Mullings

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LCC_ALL en_US.UTF-8

RUN apt-get update \
  && apt install -y locales \
  && apt install -y make \
  && locale-gen en_US.UTF-8 \
  && apt build-dep php5 \
  && apt install -y libxslt1.1 libxslt1-dev \
  && apt install -y wget \
  && apt install -y libfcgi-dev libfcgi0ldbl libjpeg62-dbg libmcrypt-dev \
  && apt install -y curl \
  && apt install -y libgd-dev \
  && apt install -y g++ \
  && apt install -y libcurl4-gnutls-dev \
  && apt install -y openssl libssl-dev pkg-config\
  && apt install -y libxml2-dev \
  && apt install -y gcc \
  && cd /usr/include \
  && ln -s x86_64-linux-gnu/curl curl \
  && cd /tmp \
  && wget http://fr2.php.net/get/php-5.4.45.tar.gz/from/this/mirror -O php.tar.gz\
  && tar -xzf php.tar.gz \
  && cd php-* \
#  && ./configure --prefix=/usr/local/php --enable-mbstring --with-curl --with-openssl --with-xmlrpc --enable-soap --enable-zip --with-gd --with-jpeg-dir --with-png-dir --with-mysql --enable-embedded-mysqli --with-freetype-dir --with-xsl --with-mysql --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-mysql-sock --enable-intl \
  && ./configure \
     --prefix=/usr/local/php \
     --with-zlib-dir \
     --with-freetype-dir \
     --enable-cgi \
     --enable-mbstring \
     --with-libxml-dir=/usr \
     --enable-soap \
     --enable-calendar \
     --with-curl \
     --with-mcrypt \
     --with-zlib \
     --with-gd \
     --disable-rpath \
     --enable-inline-optimization \
     --with-bz2 \
     --with-zlib \
     --enable-sockets \
     --enable-sysvsem \
     --enable-sysvshm \
     --enable-pcntl \
     --enable-mbregex \
     --with-mhash \
     --enable-zip \
     --with-pcre-regex \
     --with-mysql \
     --with-pdo-mysql \
     --with-mysqli \
     --with-jpeg-dir=/usr \
     --with-png-dir=/usr \
     --enable-gd-native-ttf \
     --with-openssl \
     --with-libdir=lib64 \
     --with-libxml-dir=/usr \
     --enable-exif \
     --enable-dba \
     --with-gettext \
     --enable-shmop \
     --enable-sysvmsg \
     --enable-wddx \
     --with-imap \
     --with-imap-ssl \
     --with-kerberos \
     --enable-bcmath \
     --enable-ftp \
     --enable-intl \
     --with-pspell \
     --enable-fpm \
     --enable-embedded-mysqli \
     --with-fpm-user=www-data \
     --with-fpm-group=www-data \
     --with-mysql-sock \
  && make \
  && make install

EXPOSE 9000
CMD ["php-fpm"]