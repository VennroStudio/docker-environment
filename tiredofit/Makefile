include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-tiredofit.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: backup backup-job restore restore-file

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

##@ TiredOfIt DB Backup

init: env network docker-pull docker-up ## Инициализировать backup-контейнер
up: env network docker-up ## Поднять backup-контейнер
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
	docker compose -f $(COMPOSE_FILE) exec tiredofit backup-now

backup-job: up ## Запустить один job: make backup-job JOB=01
	@[ -n "$(JOB)" ] || (echo "JOB is required, example: make backup-job JOB=01" >&2; exit 1)
	docker compose -f $(COMPOSE_FILE) exec tiredofit backup$(JOB)-now

restore: up ## Интерактивно восстановить базу из backup-файла
	docker compose -f $(COMPOSE_FILE) exec tiredofit restore

restore-file: up ## Восстановить файл: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database
	@[ -n "$(JOB)" ] || (echo "JOB is required, example: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database" >&2; exit 1)
	@[ -n "$(FILE)" ] || (echo "FILE is required, example: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database" >&2; exit 1)
	@[ -n "$(DB_NAME)" ] || (echo "DB_NAME is required, example: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database" >&2; exit 1)
	docker compose -f $(COMPOSE_FILE) exec tiredofit restore "$(FILE)" "$(DB$(JOB)_TYPE)" "$(DB$(JOB)_HOST)" "$(DB_NAME)" "$(DB$(JOB)_USER)" "$(DB$(JOB)_PASS)" "$(DB$(JOB)_PORT)"

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
