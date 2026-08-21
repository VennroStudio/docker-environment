include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-mariadb.yml
DB_NAME ?=
DB_USER ?=
DB_HOST ?= 172.18.0.1
DB_PASSWORD ?=
SQL ?=
MARIADB_ROOT = docker compose -f $(COMPOSE_FILE) exec -T -e MYSQL_PWD="$(MYSQL_ROOT_PASSWORD)" mariadb mariadb -uroot

.PHONY: help env cnf network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: volume-inspect volume-rm
.PHONY: mariadb-sql db-users db-create db-user-create db-grant db-user-grants db-user-drop db-app-create

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

cnf: ## Безопасно скопировать config.cnf из example
	@[ -f config.cnf ] || cp config.cnf.example config.cnf
	@[ -f phpmyadmin/config.inc.php ] || cp phpmyadmin/config.inc.php.example phpmyadmin/config.inc.php

##@ Сеть

network: env ## Создать внешнюю сеть, если она ещё не существует
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ MariaDB

init: env cnf network docker-pull docker-up ## Инициализировать проект
up: network docker-up ## Поднять контейнеры
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

##@ MariaDB CLI

mariadb-sql: ## Выполнить SQL под root, пример: SQL='SHOW DATABASES;'
	@$(MARIADB_ROOT) -e "$(SQL)"

db-users: ## Показать пользователей MariaDB как пары user@host
	@$(MARIADB_ROOT) -e "SELECT User, Host FROM mysql.user ORDER BY User, Host;"

db-create: ## Создать БД, пример: DB_NAME=v-project
	@$(MARIADB_ROOT) -e "CREATE DATABASE IF NOT EXISTS \`$(DB_NAME)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

db-user-create: ## Создать/обновить пользователя user@host, пример: DB_USER=v-project DB_HOST=172.18.0.1 DB_PASSWORD='pass'
	@$(MARIADB_ROOT) -e "CREATE USER IF NOT EXISTS '$(DB_USER)'@'$(DB_HOST)' IDENTIFIED BY '$(DB_PASSWORD)'; ALTER USER '$(DB_USER)'@'$(DB_HOST)' IDENTIFIED BY '$(DB_PASSWORD)';"

db-grant: ## Дать user@host права только на БД, пример: DB_NAME=v-project DB_USER=v-project DB_HOST=172.18.0.1
	@$(MARIADB_ROOT) -e "GRANT ALL PRIVILEGES ON \`$(DB_NAME)\`.* TO '$(DB_USER)'@'$(DB_HOST)';"

db-user-grants: ## Показать права user@host, пример: DB_USER=v-project DB_HOST=172.18.0.1
	@$(MARIADB_ROOT) -e "SHOW GRANTS FOR '$(DB_USER)'@'$(DB_HOST)';"

db-user-drop: ## Удалить конкретного пользователя user@host, пример: DB_USER=vennro DB_HOST=172.18.0.11
	@$(MARIADB_ROOT) -e "DROP USER '$(DB_USER)'@'$(DB_HOST)';"

db-app-create: ## Создать БД, пользователя и права, пример: DB_NAME=v-project DB_USER=v-project DB_HOST=172.18.0.1 DB_PASSWORD='pass'
	@$(MAKE) db-create DB_NAME="$(DB_NAME)"
	@$(MAKE) db-user-create DB_USER="$(DB_USER)" DB_HOST="$(DB_HOST)" DB_PASSWORD="$(DB_PASSWORD)"
	@$(MAKE) db-grant DB_NAME="$(DB_NAME)" DB_USER="$(DB_USER)" DB_HOST="$(DB_HOST)"
	@$(MAKE) db-user-grants DB_USER="$(DB_USER)" DB_HOST="$(DB_HOST)"
