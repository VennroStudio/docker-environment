COMPOSE_FILE ?= docker-compose-rustfs.yml

.PHONY: help env init up down restart docker-up docker-down docker-pull docker-build logs ps config

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

##@ RustFS

init: env docker-down docker-pull docker-build docker-up ## Инициализировать проект
up: docker-up ## Поднять проект
down: docker-down ## Удалить проект
restart: down up ## Перезапустить проект

docker-up: ## Поднять контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнер
	docker compose -f $(COMPOSE_FILE) down --remove-orphans

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

docker-build: ## Пересобрать образ
	docker compose -f $(COMPOSE_FILE) build --pull

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config