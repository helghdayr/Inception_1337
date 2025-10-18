docker_compose_file = ./srcs/docker-compose.yml

up : down
	@docker compose -f $(docker_compose_file) up -d --build

down :
	@docker compose -f $(docker_compose_file) down
