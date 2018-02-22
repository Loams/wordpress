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

## compile php 5.4.45
RUN mkdir -p /opt/php-5.4 \
  && mkdir -p /var/www \
  && mkdir -p /usr/local/src/php5.4-build \
  && cd /usr/local/src/php5.4-build \
  && wget http://fr2.php.net/get/php-5.4.45.tar.gz/from/this/mirror -O php-5.4.45.tar.gz \
  && tar xzf php-5.4.45.tar.gz \
  && cd php-5.4.45 \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" './configure'  --prefix=/opt/php-5.4 '--with-zlib-dir' '--with-freetype-dir' '--enable-fpm' '--enable-mbstring' '--with-libxml-dir=/usr' '--enable-soap' '--enable-calendar' '--with-curl=/usr/local/curl' '--with-mcrypt' '--with-zlib' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-mbregex' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-mysql' '--with-pdo-mysql' '--with-mysqli' '--with-jpeg-dir=/usr' '--with-png-dir=/usr' '--enable-gd-native-ttf' '--enable-cgi' '--with-pear' '--enable-memcache' '--with-openssl=/usr/local/openssl'  '--with-kerberos' '--enable-embedded-mysqli' '--with-libdir=lib/x86_64-linux-gnu' '--enable-fpm' '--with-fpm-user=www-data' '--with-fpm-group=www-data' '--with-mysql-sock' \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" make \
  && make install

## create src directory
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

# install php-mysql dependency
RUN wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-mysql_5.4.45-0+deb7u12_amd64.deb -O php-mysql.deb \
  && wget http://security.debian.org/debian-security/pool/updates/main/m/mysql-5.5/libmysqlclient18_5.5.59-0+deb7u1_amd64.deb -O libmysqlclient.deb \
  && wget http://ftp.br.debian.org/debian-security/pool/updates/main/p/php5/php5-mysqlnd_5.4.45-0+deb7u12_amd64.deb -O php5-mysqlnd.deb \
  && dpkg -i libmysqlclient.deb \
  && dpkg -i php5-mysqlnd.deb \
  && dpkg -i php-mysql.deb

# install php-curl
RUN wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-curl_5.4.45-0+deb7u12_amd64.deb -O php5-curl.deb \
  && dpkg -i php5-curl.deb


#install php-gd dependency
RUN wget http://ftp.us.debian.org/debian/pool/main/libj/libjpeg8/libjpeg8_8d-1+deb7u1_amd64.deb -O libjpeg8.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libp/libpng/libpng12-0_1.2.49-1+deb7u2_amd64.deb -O libpng12.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libx/libxau/libxau6_1.0.7-1_amd64.deb -O libxau6.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libx/libxdmcp/libxdmcp6_1.1.1-1_amd64.deb -O libxdmcp6.deb \
  && dpkg -i libjpeg8.deb \
  && dpkg -i libpng12.deb \
  && dpkg -i libxdmcp6.deb \
  && dpkg -i libxau6.deb

# install libx11
RUN wget http://security.debian.org/debian-security/pool/updates/main/libx/libx11/libx11-6_1.5.0-1+deb7u4_amd64.deb -O libx11.deb \
  && wget http://security.debian.org/debian-security/pool/updates/main/libx/libx11/libx11-data_1.5.0-1+deb7u4_all.deb -O libx11-data.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libx/libxcb/libxcb1_1.8.1-2+deb7u1_amd64.deb -O libxcb1.deb \
  && dpkg -i libxcb1.deb \
  && dpkg -i libx11-data.deb \
  && dpkg -i libx11.deb

# install libxpm4
RUN wget http://security.debian.org/debian-security/pool/updates/main/libx/libxpm/libxpm4_3.5.10-1+deb7u1_amd64.deb -O libxpm4.deb \
  && dpkg -i libxpm4.deb

# install xfonts-utils
RUN wget http://ftp.us.debian.org/debian/pool/main/x/xfonts-utils/xfonts-utils_7.7~1_amd64.deb -O xfonts-utils.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/libf/libfontenc/libfontenc1_1.1.1-1_amd64.deb -O libfontenc1.deb \
  && wget http://security.debian.org/debian-security/pool/updates/main/libx/libxfont/libxfont1_1.4.5-5+deb7u1_amd64.deb -O libxfont1.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/x/xorg/x11-common_7.7+3~deb7u1_all.deb -O x11-common.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/x/xfonts-encodings/xfonts-encodings_1.0.4-1_all.deb -O xfonts-encodings.deb \
  && dpkg -i libfontenc1.deb \
  && dpkg -i libxfont1.deb \
  && dpkg -i x11-common.deb \
  && dpkg -i xfonts-encodings.deb \
  && dpkg -i xfonts-utils.deb

# install gsfonts
RUN wget http://ftp.us.debian.org/debian/pool/main/g/gsfonts/gsfonts_8.11+urwcyr1.0.7~pre44-4.2_all.deb -O gsfonts.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/g/gsfonts-x11/gsfonts-x11_0.22_all.deb -O gsfonts-x11.deb \
  && dpkg -i gsfonts.deb \
  && dpkg -i gsfonts-x11.deb

# install fontconfig-config
RUN wget http://security.debian.org/debian-security/pool/updates/main/f/fontconfig/fontconfig-config_2.9.0-7.1+deb7u1_all.deb -O fontconfig-config.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/t/ttf-dejavu/ttf-dejavu-core_2.33-3_all.deb -O ttf-dejavu-core.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/t/ttf-bitstream-vera/ttf-bitstream-vera_1.10-8_all.deb -O ttf-bitstream.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/f/fonts-freefont/fonts-freefont-ttf_20120503-1_all.deb -O fonts-freefont-ttf.deb \
  && wget http://ftp.us.debian.org/debian/pool/main/f/fonts-freefont/ttf-freefont_20120503-1_all.deb -O ttf-freefont.deb \
  && dpkg -i ttf-dejavu-core.deb \
  && dpkg -i ttf-bitstream.deb \
  && dpkg -i fonts-freefont-ttf.deb \
  && dpkg -i ttf-freefont.deb \
  && dpkg -i fontconfig-config.deb

# install libfontconfig
RUN wget http://security.debian.org/debian-security/pool/updates/main/f/fontconfig/libfontconfig1_2.9.0-7.1+deb7u1_amd64.deb -O libfontconfig1.deb \
  && wget http://security.debian.org/debian-security/pool/updates/main/e/expat/libexpat1_2.1.0-1+deb7u5_amd64.deb -O libexpat1.deb \
  && dpkg -i libexpat1.deb \
  && dpkg -i libfontconfig1.deb

# install libgd2-xpm
RUN wget http://security.debian.org/debian-security/pool/updates/main/libg/libgd2/libgd2-xpm_2.0.36~rc1~dfsg-6.1+deb7u11_amd64.deb -O libgd2-xpm.deb \
  && dpkg -i libgd2-xpm.deb

# install php-gd
RUN wget http://security.debian.org/debian-security/pool/updates/main/p/php5/php5-gd_5.4.45-0+deb7u12_amd64.deb -O php5-gd.deb \
  && dpkg -i php5-gd.deb

RUN cp /usr/local/src/php5.4-build/php-5.4.45/php.ini-production /etc/php5/php.ini

COPY ./config/php-fpm.conf /etc/php5/fpm/php-fpm.conf
COPY ./config/www.conf /etc/php5/fpm/pool.d/www.conf
COPY ./config/php.ini /etc/php5/fpm/conf.d/custom.ini

WORKDIR /var/www

EXPOSE 9000

# PHP_DATA_DIR store sessions
VOLUME ["${PHP_RUN_DIR}", "${PHP_DATA_DIR}"]

CMD ["/usr/sbin/php5-fpm"]