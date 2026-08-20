include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-mail.yml
ELASTIC2022_VERSION ?= $(shell sed -n '1p' templates/roundcube/skins/elastic2022.version 2>/dev/null || printf '1.7.1')
ELASTIC2022_TAG := $(patsubst v%,%,$(ELASTIC2022_VERSION))
ELASTIC2022_ARCHIVE := /tmp/roundcube-elastic2022-$(ELASTIC2022_TAG).tar.gz
ELASTIC2022_EXTRACT_DIR := /tmp/roundcube-elastic2022-$(ELASTIC2022_TAG)
ELASTIC2022_URL := https://github.com/seb1k/Elastic2022/archive/refs/tags/$(ELASTIC2022_TAG).tar.gz
ELASTIC2022_SKINS_DIR := templates/roundcube/skins
ELASTIC2022_SKIN_DIR := templates/roundcube/skins/elastic2022
ELASTIC2022_VERSION_FILE := templates/roundcube/skins/elastic2022.version

.PHONY: help env network init up down restart
.PHONY: elastic2022-update elastic2022-download elastic2022-extract elastic2022-write-version
.PHONY: docker-up docker-down docker-pull logs ps config subnet

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

network: env ## Создать внешнюю сеть proxy, если она ещё не существует
	@docker network inspect proxy >/dev/null 2>&1 || docker network create proxy

##@ Mail

init: env network docker-pull docker-up ## Инициализировать Mail
up: network docker-up ## Поднять Mail
down: docker-down ## Остановить и удалить Mail
restart: down up ## Перезапустить Mail
elastic2022-update: ## Обновить скин Roundcube Elastic2022
	$(MAKE) elastic2022-download ELASTIC2022_VERSION=$(ELASTIC2022_TAG)
	$(MAKE) elastic2022-extract ELASTIC2022_VERSION=$(ELASTIC2022_TAG)
	$(MAKE) elastic2022-write-version ELASTIC2022_VERSION=$(ELASTIC2022_TAG)

elastic2022-download: ## Скачать архив Elastic2022
	curl -fsSL "$(ELASTIC2022_URL)" -o "$(ELASTIC2022_ARCHIVE)"

elastic2022-extract: ## Распаковать архив Elastic2022
	rm -rf "$(ELASTIC2022_EXTRACT_DIR)"
	mkdir -p "$(ELASTIC2022_EXTRACT_DIR)" "$(ELASTIC2022_SKIN_DIR)"
	tar -xzf "$(ELASTIC2022_ARCHIVE)" -C "$(ELASTIC2022_EXTRACT_DIR)" --strip-components=1
	test -f "$(ELASTIC2022_EXTRACT_DIR)/meta.json"
	rsync -a --delete --exclude '/.github/' --exclude '/img/' "$(ELASTIC2022_EXTRACT_DIR)/" "$(ELASTIC2022_SKIN_DIR)/"

elastic2022-write-version: ## Записать версию Elastic2022
	mkdir -p "$(ELASTIC2022_SKINS_DIR)"
	printf '%s\n' "$(ELASTIC2022_TAG)" > "$(ELASTIC2022_VERSION_FILE)"

docker-up: ## Поднять контейнеры
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнеры
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежие образы
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнеров
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый compose-конфиг
	docker compose -f $(COMPOSE_FILE) config

subnet: ## Показать подсеть Docker-сети proxy
	docker network inspect proxy --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
