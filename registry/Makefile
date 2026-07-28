include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-registry.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: auth

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

network: env ## Создать внешнюю сеть, если она ещё не существует
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ Registry

init: env network auth docker-down docker-pull docker-up ## Инициализировать проект
up: network auth docker-up ## Поднять проект
down: docker-down ## Удалить проект
restart: down up ## Перезапустить проект

auth: env ## Создать htpasswd для Registry, если он ещё не существует
	@[ -f $(AUTH_PATH) ] && exit 0; \
	mkdir -p $(dir $(AUTH_PATH)); \
	docker run --rm --entrypoint htpasswd httpd:2 -Bbn "$(REGISTRY_USER)" "$(REGISTRY_PASSWORD)" > $(AUTH_PATH); \
	chmod 600 $(AUTH_PATH)

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

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
