FROM debian:stretch

MAINTAINER Stephane Mullings

RUN apt-get update \
  && apt-get install -y locales \
  && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LCC_ALL en_US.UTF-8

RUN apt-get update \
  && apt install curl
  && cd /tmp \
  && curl http://fr2.php.net/get/php-5.4.45.tar.gz/from/this/mirror \
  && tar -xzf *.tar.gz \
  && cd *.tar.gz \
  && sudo ./configure --prefix=/usr/local/php --enable-mbstring --with-curl --with-openssl --with-xmlrpc --enable-soap --enable-zip --with-gd --with-jpeg-dir --with-png-dir --with-mysql --enable-embedded-mysqli --with-freetype-dir --with-ldap --enable-intl --with-xsl --with-mysql --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-mysql-sock --enable-intl
  && make \
  && sudo make install

EXPOSE 9000
CMD ["php-fpm"]