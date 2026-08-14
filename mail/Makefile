include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-mail.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config subnet

##@ Помощь

help: ## Показать список команд
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} \
	   /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
	   /^[a-zA-Z_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
	   $(MAKEFILE_LIST)
	@echo ""

##@ .env

env: ## Безопасно скопировать .env из example
	@[ -f .env ] || cp .env.example .env

##@ Сеть

network: env ## Создать внешнюю сеть proxy, если она ещё не существует
	@docker network inspect proxy >/dev/null 2>&1 || docker network create proxy

##@ Mail

init: env network docker-pull docker-up ## Инициализировать Mail
up: network docker-up ## Поднять Mail
down: docker-down ## Остановить и удалить Mail
restart: down up ## Перезапустить Mail

docker-up: ## Поднять контейнеры
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнеры
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежие образы
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнеров
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый compose-конфиг
	docker compose -f $(COMPOSE_FILE) config

subnet: ## Показать подсеть Docker-сети proxy
	docker network inspect proxy --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
