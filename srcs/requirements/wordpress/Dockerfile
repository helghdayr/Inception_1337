FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    netcat-traditional \
    php php-fpm \
    php-mysql \
    openssl \
    ca-certificates

RUN mkdir -p /run/php

COPY ./tools/wordpress_script.sh .

RUN chmod +x ./wordpress_script.sh

ENTRYPOINT ["bash", "wordpress_script.sh"]
