FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends openssl nginx

RUN mkdir -p /etc/ssl/certs /etc/ssl/private

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/ssl/private/server.key \
	-out /etc/ssl/certs/server.crt \
	-subj "/C=MA/ST=KH/OU=1337/CN=hael-ghd.42.fr"

RUN chmod 600 /etc/ssl/private/server.key

RUN chmod 644 /etc/ssl/certs/server.crt

COPY ./conf/default.conf /etc/nginx/conf.d

ENTRYPOINT ["nginx", "-g", "daemon off;"]
