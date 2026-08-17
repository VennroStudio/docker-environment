include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-redis.yml

.PHONY: help env acl network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: volume-inspect volume-rm

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

acl: env ## Сгенерировать users.acl из .env
	@if [ "$$REDIS_USER" = "default" ]; then \
		printf 'user default on >%s ~* &* +@all\n' "$$REDIS_PASSWORD" > users.acl; \
	else \
		printf 'user %s on >%s ~* &* +@all\nuser default off\n' "$$REDIS_USER" "$$REDIS_PASSWORD" > users.acl; \
	fi
	@chmod 640 users.acl

##@ Сеть

network: env ## Создать внешнюю сеть, если она ещё не существует
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ Redis

init: env acl network docker-pull docker-up ## Инициализировать проект
up: acl network docker-up ## Поднять контейнеры
down: docker-down ## Остановить и удалить контейнеры
restart: down up ## Перезапустить контейнеры

docker-up: ## Поднять контейнеры
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнеры
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежие образы
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнеров
	docker compose -f $(COMPOSE_FILE) ps

##@ Хранилище

volume-inspect: ## Показать информацию о хранилище
	docker volume inspect $(VOLUME)

volume-rm: ## Удалить хранилище (полная потеря данных)
	docker volume rm $(VOLUME)

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
