include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-tiredofit.yml

.PHONY: help env init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: backup backup-job

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

##@ TiredOfIt DB Backup

init: env docker-pull docker-up ## Инициализировать backup-контейнер
up: env docker-up ## Поднять backup-контейнер
down: docker-down ## Остановить и удалить backup-контейнер
restart: down up ## Перезапустить backup-контейнер

docker-up: ## Поднять backup-контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить backup-контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Бэкап

backup: up ## Запустить все backup jobs прямо сейчас
	docker compose -f $(COMPOSE_FILE) exec db-backup backup-now

backup-job: up ## Запустить один job: make backup-job JOB=01
	@[ -n "$(JOB)" ] || (echo "JOB is required, example: make backup-job JOB=01" >&2; exit 1)
	docker compose -f $(COMPOSE_FILE) exec db-backup backup$(JOB)-now

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
