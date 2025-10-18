FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends curl netcat-traditional \
	mariadb-server \
	mariadb-client

COPY ./tools/mariadb_script.sh .

RUN chmod +x ./mariadb_script.sh

ENTRYPOINT ["bash", "mariadb_script.sh"]

