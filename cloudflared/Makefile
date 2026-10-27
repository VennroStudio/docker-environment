include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-cloudflared.yml

.PHONY: help env init docker-pull share config

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

##@ Cloudflared

init: env docker-pull ## Подготовить модуль, без публикации сервисов

docker-pull: ## Скачать образ cloudflared
	docker compose -f $(COMPOSE_FILE) pull cloudflared

share: env ## Опубликовать контейнер: make share CONTAINER=web PORT=3000 NETWORK=proxy; остановка Ctrl+C
	@[ -n "$$CONTAINER" ] && [ -n "$$PORT" ] || { echo 'Use: make share CONTAINER=web PORT=3000' >&2; exit 1; }
	docker compose -f $(COMPOSE_FILE) run --rm --no-deps cloudflared

##@ Проверка

config: ## Показать Compose-конфиг: make config CONTAINER=web PORT=3000
	docker compose -f $(COMPOSE_FILE) config
