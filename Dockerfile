FROM lukacu/nginx-php

RUN apk add --no-cache mariadb-client sed bash curl

# install the PHP extensions we need
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-jpeg; \
	docker-php-ext-install gd zip; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps

VOLUME /var/www/html

ENV WORDPRESS_VERSION=7.1.3
ENV WORDPRESS_SHA1=491a78c7676b15dffcc69130c6054b8f49228a91

RUN set -ex; \
	curl -o /usr/src/wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 */usr/src/wordpress.tar.gz" | sha1sum -c -; \
	chown -R www-data:www-data /usr/src/wordpress.tar.gz

COPY etc/nginx/site/* /etc/nginx/site/

COPY etc/service/init/* /etc/service/init/

COPY scripts/* /

RUN chmod +x /backup.sh /wpcron.sh; \
    ln -s /backup.sh /etc/periodic/daily/databasebackup; \
    ln -s /wpcron.sh /etc/periodic/daily/wpcron

