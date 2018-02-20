FROM debian:stretch

MAINTAINER Stephane Mullings

RUN apt-get update \
  && apt install -y build-essential \
                    checkinstall \
                    zip \
                    autoconf \
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

RUN cd /tmp \
  && wget https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz \
  && tar xzf openssl-1.0.1u.tar.gz \
  && cd openssl-1.0.1u \
  && ./config shared --openssldir=/usr/local/openssl/ enable-ec_nistp_64_gcc_128 \
  && make depend \
  && make \
  && make install \
  && ln -s /usr/local/openssl/lib /usr/local/openssl/lib/x86_64-linux-gnu\

## compile old curl
RUN cd /tmp \
    && wget https://curl.haxx.se/download/curl-7.26.0.tar.gz \
    && tar xzf curl-7.26.0.tar.gz \
    && cd curl-7.26.0 \
    && env PKG_CONFIG_PATH=/usr/local/openssl/lib/pkgconfig LDFLAGS=-Wl,-rpath=/usr/local/openssl/lib \
    && ./configure \
      --with-ssl=/usr/local/openssl \
      --with-zlib \
      --prefix=/usr/local/curl \
    && make \
    && make install

## old libc-client
RUN wget http://http.debian.net/debian/pool/main/u/uw-imap/uw-imap_2007f\~dfsg-2.dsc \
    && wget http://http.debian.net/debian/pool/main/u/uw-imap/uw-imap_2007f\~dfsg.orig.tar.gz \
    && wget http://http.debian.net/debian/pool/main/u/uw-imap/uw-imap_2007f\~dfsg-2.debian.tar.gz \
    && dpkg-source -x uw-imap_2007f\~dfsg-2.dsc imap-2007f \
    && mv imap-2007f /usr/local/ \
    && cd /usr/local/imap-2007f/ \
    && touch {ipv6,lnxok} \
    && make slx SSLINCLUDE=/usr/local/openssl/include/ SSLLIB=/usr/local/openssl/lib EXTRAAUTHENTICATORS=gss \
    && mkdir lib include \
    && cp c-client/*.c lib/ \
    && cp c-client/*.h include/ \
    && cp c-client/c-client.a lib/libc-client.a \
    && ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a \

RUN  wget http://fr2.php.net/get/php-5.4.45.tar.gz/from/this/mirror -O php.tar.gz \
  && tar -xzf php.tar.gz \
  && cd php-* \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" './configure'  --prefix=/usr/local/php'--with-zlib-dir' '--with-freetype-dir' '--enable-fpm' '--enable-mbstring' '--with-libxml-dir=/usr' '--enable-soap' '--enable-calendar' '--with-curl=/usr/local/curl' '--with-mcrypt' '--with-zlib' '--with-gd' '--disable-rpath' '--enable-inline-optimization' '--with-bz2' '--with-zlib' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-mbregex' '--with-mhash' '--enable-zip' '--with-pcre-regex' '--with-mysql' '--with-pdo-mysql' '--with-mysqli' '--with-jpeg-dir=/usr' '--with-png-dir=/usr' '--enable-gd-native-ttf' '--enable-cgi' '--with-pear' '--enable-memcache' '--with-openssl=/usr/local/openssl' '--with-imap=/usr/local/imap-2007f' '--with-kerberos' '--with-imap-ssl' '--with-libdir=lib/x86_64-linux-gnu' \
  && LDFLAGS="-Wl,-rpath=/usr/local/openssl/lib,-rpath=/usr/local/curl/lib" make \
  && make install

EXPOSE 9000
CMD ["php-fpm"]