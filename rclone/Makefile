include .env.example
-include .env
-include ../.env
export

COMPOSE_FILE ?= docker-compose-rclone.yml

.PHONY: help env init config backup deploy
.PHONY: docker-pull logs ps compose-config

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

##@ Rclone

init: env docker-pull ## Инициализировать rclone

cnf: env ## Интерактивно настроить rclone.conf
	docker compose -f $(COMPOSE_FILE) run --rm rclone config

backup: env ## Отправить storage на удалённое хранилище
	docker compose -f $(COMPOSE_FILE) run --rm rclone copy /storage $(RCLONE_REMOTE) --progress

deploy: ## Отправить готовый rclone.conf на сервер
	scp -P $(PORT) config/rclone.conf $(HOST):$(DOCKER_SERVER_PATH)/rclone/config/rclone.conf

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый compose-конфиг
	docker compose -f $(COMPOSE_FILE) config
