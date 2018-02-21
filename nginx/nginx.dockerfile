FROM docker_php

COPY ./supervisord.conf /etc/supervisor/conf.d/

ENV NGINX_CONF_DIR=/etc/nginx

RUN	apt update \
	&& apt install -y nginx\
	&& rm -rf  ${NGINX_CONF_DIR}/sites-enabled/* ${NGINX_CONF_DIR}/sites-available/* \
	# Install supervisor
	&& apt install -y supervisor \
	&& mkdir -p /var/log/supervisor \
	&& chown www-data:www-data /var/www/ -Rf \
	# Cleaning
	&& apt autoremove -y \
	&& apt clean \
	&& rm -rf /var/lib/apt/lists/* \
	# Forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./config/nginx.conf ${NGINX_CONF_DIR}/nginx.conf
COPY ./config/app.conf ${NGINX_CONF_DIR}/sites-enabled/app.conf
COPY ./config/www.conf /etc/php5/fpm/pool.d/www.conf

COPY ./certs/leasyluxe.local.crt /etc/nginx/certs/leasyluxe.local.crt
COPY ./certs/leasyluxe.local.key /etc/nginx/certs/leasyluxe.local.key

WORKDIR /var/www/

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]