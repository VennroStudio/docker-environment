include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-registry.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: create-user add-user change-password list-users remove-user
.PHONY: list-images list-tags storage-size

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

init: env network docker-down docker-pull docker-up ## Инициализировать проект
up: network docker-up ## Поднять проект
down: docker-down ## Удалить проект
restart: down up ## Перезапустить проект

docker-up: create-user ## Поднять контейнеры
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

##@ Пользователи

create-user: env ## Создать основного пользователя Registry из REGISTRY_USER/REGISTRY_PASSWORD
	@mkdir -p auth
	@test -n "$${REGISTRY_USER}" || (echo "Заполни REGISTRY_USER"; exit 1)
	@test -n "$${REGISTRY_PASSWORD}" || (echo "Заполни REGISTRY_PASSWORD"; exit 1)
	@test "$${REGISTRY_PASSWORD}" != "change-me" || (echo "Поменяй REGISTRY_PASSWORD"; exit 1)
	@if [ ! -f auth/htpasswd ]; then \
		printf '%s\n' "$${REGISTRY_PASSWORD}" | docker run --rm -i --entrypoint htpasswd httpd:2 -Bni "$${REGISTRY_USER}" > auth/htpasswd; \
		echo "Пользователь '$${REGISTRY_USER}' создан"; \
	else \
		echo "Файл auth/htpasswd уже существует"; \
	fi


add-user: ## Добавить нового пользователя
	@test -f auth/htpasswd || (echo "Сначала создай auth/htpasswd через make create-user"; exit 1)
	@echo "Введите имя пользователя:"
	@read username && \
	echo "Введите пароль для пользователя $$username:" && \
	htpasswd -B auth/htpasswd "$$username" && \
	echo "Пользователь $$username добавлен"
	@docker compose -f $(COMPOSE_FILE) restart registry


change-password: ## Изменить пароль существующего пользователя
	@test -f auth/htpasswd || (echo "Сначала создай auth/htpasswd через make create-user"; exit 1)
	@echo "Введите имя пользователя:"
	@read username && \
	echo "Введите новый пароль для пользователя $$username:" && \
	htpasswd -B auth/htpasswd "$$username" && \
	echo "Пароль для $$username изменен"
	@docker compose -f $(COMPOSE_FILE) restart registry


list-users: ## Показать список пользователей
	@test -f auth/htpasswd || (echo "Файл auth/htpasswd не найден"; exit 1)
	@echo "Пользователи Registry:"
	@cat auth/htpasswd | cut -d: -f1

remove-user: ## Удалить пользователя
	@test -f auth/htpasswd || (echo "Файл auth/htpasswd не найден"; exit 1)
	@echo "Введите имя пользователя для удаления:"
	@read username && \
	htpasswd -D auth/htpasswd "$$username" && \
	echo "Пользователь $$username удален"
	@docker compose -f $(COMPOSE_FILE) restart registry

##@ Образы

list-images: ## Просмотр образов в Registry
	@echo "Образы в Registry:"
	@curl -su "$${REGISTRY_USER}:$${REGISTRY_PASSWORD}" "http://127.0.0.1:$${REGISTRY_PORT}/v2/_catalog" | jq -r '.repositories[]?' 2>/dev/null || \
	curl -su "$${REGISTRY_USER}:$${REGISTRY_PASSWORD}" "http://127.0.0.1:$${REGISTRY_PORT}/v2/_catalog"

list-tags: ## Просмотр тегов образа
	@echo "Введите имя образа (например: app-php-fpm):"
	@read image && \
	curl -su "$${REGISTRY_USER}:$${REGISTRY_PASSWORD}" "http://127.0.0.1:$${REGISTRY_PORT}/v2/$$image/tags/list" | jq '.' 2>/dev/null || \
	curl -su "$${REGISTRY_USER}:$${REGISTRY_PASSWORD}" "http://127.0.0.1:$${REGISTRY_PORT}/v2/$$image/tags/list"

storage-size: ## Проверка размера хранилища
	@echo "Размер хранилища Registry:"
	@du -sh "$${VOLUME}" 2>/dev/null || echo "Папка $${VOLUME} не найдена"
