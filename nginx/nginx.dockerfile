FROM leasyluxphp

COPY ./supervisord.conf /etc/supervisor/conf.d/

ENV NGINX_CONF_DIR=/etc/nginx

RUN	\
	buildDeps='software-properties-common python-software-properties' \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y $buildDeps \
	&& apt-get install -y nginx \
	&& rm -rf  ${NGINX_CONF_DIR}/sites-enabled/* ${NGINX_CONF_DIR}/sites-available/* \
	# Install supervisor
	&& apt-get install -y supervisor && mkdir -p /var/log/supervisor \
	&& chown www-data:www-data /var/www/app/ -Rf \
	# Cleaning
	&& apt-get purge -y --auto-remove $buildDeps \
	&& apt-get autoremove -y && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	# Forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./config/nginx.conf ${NGINX_CONF_DIR}/nginx.conf
COPY ./config/app.conf ${NGINX_CONF_DIR}/sites-enabled/app.conf
COPY ./config/www.conf /etc/php5/fpm/pool.d/www.conf

WORKDIR /var/www/leasylux/

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]