include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-centrifugo.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config

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

##@ Конфиг

cnf: ## Безопасно скопировать config.yaml из example
	@[ -f config.yaml ] || cp config.yaml.example config.yaml

##@ Сеть

network: env ## Создать внешнюю сеть, если она ещё не существует
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ Centrifugo

init: env network docker-pull docker-up ## Инициализировать проект
up: network docker-up ## Поднять контейнер
down: docker-down ## Остановить и удалить контейнер
restart: down up ## Перезапустить контейнер

docker-up: ## Поднять контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config