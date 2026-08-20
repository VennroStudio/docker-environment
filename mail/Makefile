include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-mail.yml
NPM_CONTAINER ?= nginx-container
NPM_CERT ?=
DOMAIN_NAME ?= $(DOMAIN)
MODE ?= create
REALLY ?= false
WILDCARD ?= false
EXPORT_ARGS ?=
IMPORT_FILE ?=
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
.PHONY: npm-certs npm-cert-copy npm-cert-install cert-reload cert-check
.PHONY: mailu-config-export mailu-config-import mailu-dns mailu-domains mailu-users mailu-aliases
.PHONY: mailu-domain-create mailu-admin-create mailu-user-create mailu-password
.PHONY: mailu-user-delete mailu-alias-create mailu-alias-delete mailu-setlimits mailu-setmanager

##@ Помощь

help: ## Показать список команд
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} \
	   /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
	   /^[a-zA-Z0-9_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
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

##@ Сертификаты

npm-certs: ## Показать сертификаты NPM, NPM_CONTAINER=nginx-container
	@docker exec "$(NPM_CONTAINER)" sh -c 'for dir in $$(ls /etc/letsencrypt/live); do if [ -f "/etc/letsencrypt/live/$$dir/cert.pem" ]; then echo "=== $$dir ==="; openssl x509 -in "/etc/letsencrypt/live/$$dir/cert.pem" -noout -subject; fi; done'

npm-cert-copy: ## Скопировать сертификат NPM в Mailu, NPM_CERT=npm-18 NPM_CONTAINER=nginx-container
	@test -n "$(NPM_CERT)" || (echo "Передай NPM_CERT, пример: make npm-cert-copy NPM_CERT=npm-18"; exit 1)
	@mkdir -p certs
	@docker exec "$(NPM_CONTAINER)" test -f "/etc/letsencrypt/live/$(NPM_CERT)/fullchain.pem"
	@docker exec "$(NPM_CONTAINER)" test -f "/etc/letsencrypt/live/$(NPM_CERT)/privkey.pem"
	@docker exec "$(NPM_CONTAINER)" cat "/etc/letsencrypt/live/$(NPM_CERT)/fullchain.pem" > certs/cert.pem
	@docker exec "$(NPM_CONTAINER)" cat "/etc/letsencrypt/live/$(NPM_CERT)/privkey.pem" > certs/key.pem
	@chmod 600 certs/key.pem
	@echo "Сертификат $(NPM_CERT) скопирован в certs/cert.pem и certs/key.pem"

npm-cert-install: npm-cert-copy cert-reload ## Скопировать сертификат NPM и перезагрузить TLS, NPM_CERT=npm-18

cert-reload: ## Перезагрузить TLS в front после замены certs/cert.pem и certs/key.pem
	@docker compose -f $(COMPOSE_FILE) exec -T front nginx -s reload
	@docker compose -f $(COMPOSE_FILE) exec -T front doveadm reload

cert-check: ## Проверить текущий сертификат Mailu в certs/cert.pem
	@test -f certs/cert.pem || (echo "certs/cert.pem не найден"; exit 1)
	@openssl x509 -in certs/cert.pem -noout -subject -issuer -dates

##@ Mailu CLI

mailu-config-export: ## Экспорт конфигурации, EXPORT_ARGS='--dns domain user'
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-export $(EXPORT_ARGS)

mailu-config-import: ## Импорт конфигурации, IMPORT_FILE=backup.yml
	@test -n "$(IMPORT_FILE)" || (echo "Передай IMPORT_FILE, пример: make mailu-config-import IMPORT_FILE=backup.yml"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-import < "$(IMPORT_FILE)"

mailu-dns: ## Показать DNS-записи Mailu, EXPORT_ARGS='domain.dns_mx domain.dns_spf'
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-export --dns $(EXPORT_ARGS)

mailu-domains: ## Показать домены Mailu
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-export domain

mailu-users: ## Показать пользователей Mailu
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-export user

mailu-aliases: ## Показать алиасы Mailu
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu config-export alias

mailu-domain-create: ## Создать домен, DOMAIN_NAME=domain.ru
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME, пример: make mailu-domain-create DOMAIN_NAME=domain.ru"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu domain "$(DOMAIN_NAME)"

mailu-admin-create: ## Создать/обновить админа, LOCALPART=postmaster DOMAIN_NAME=domain.ru PASSWORD='pass' MODE=create|update|ifmissing
	@test -n "$(LOCALPART)" || (echo "Передай LOCALPART, пример: make mailu-admin-create LOCALPART=postmaster DOMAIN_NAME=domain.ru PASSWORD='pass'"; exit 1)
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$${PASSWORD}" || (echo "Передай PASSWORD"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu admin --mode "$(MODE)" "$(LOCALPART)" "$(DOMAIN_NAME)" "$${PASSWORD}"

mailu-user-create: ## Создать пользователя, LOCALPART=user DOMAIN_NAME=domain.ru PASSWORD='pass'
	@test -n "$(LOCALPART)" || (echo "Передай LOCALPART, пример: make mailu-user-create LOCALPART=user DOMAIN_NAME=domain.ru PASSWORD='pass'"; exit 1)
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$${PASSWORD}" || (echo "Передай PASSWORD"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu user "$(LOCALPART)" "$(DOMAIN_NAME)" "$${PASSWORD}"

mailu-password: ## Сменить пароль, LOCALPART=user DOMAIN_NAME=domain.ru PASSWORD='pass'
	@test -n "$(LOCALPART)" || (echo "Передай LOCALPART, пример: make mailu-password LOCALPART=user DOMAIN_NAME=domain.ru PASSWORD='pass'"; exit 1)
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$${PASSWORD}" || (echo "Передай PASSWORD"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu password "$(LOCALPART)" "$(DOMAIN_NAME)" "$${PASSWORD}"

mailu-user-delete: ## Отключить пользователя, EMAIL=user@domain.ru REALLY=true удалит полностью
	@test -n "$(EMAIL)" || (echo "Передай EMAIL, пример: make mailu-user-delete EMAIL=user@domain.ru"; exit 1)
	@if [ "$(REALLY)" = "true" ]; then \
		docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu user-delete "$(EMAIL)" --really; \
	else \
		docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu user-delete "$(EMAIL)"; \
	fi

mailu-alias-create: ## Создать алиас, LOCALPART=info DOMAIN_NAME=domain.ru DESTINATION='user@domain.ru' WILDCARD=true
	@test -n "$(LOCALPART)" || (echo "Передай LOCALPART, пример: make mailu-alias-create LOCALPART=info DOMAIN_NAME=domain.ru DESTINATION='user@domain.ru'"; exit 1)
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$(DESTINATION)" || (echo "Передай DESTINATION"; exit 1)
	@if [ "$(WILDCARD)" = "true" ]; then \
		docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu alias "$(LOCALPART)" "$(DOMAIN_NAME)" "$(DESTINATION)" --wildcard; \
	else \
		docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu alias "$(LOCALPART)" "$(DOMAIN_NAME)" "$(DESTINATION)"; \
	fi

mailu-alias-delete: ## Удалить алиас, EMAIL=info@domain.ru
	@test -n "$(EMAIL)" || (echo "Передай EMAIL, пример: make mailu-alias-delete EMAIL=info@domain.ru"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu alias-delete "$(EMAIL)"

mailu-setlimits: ## Лимиты домена, DOMAIN_NAME=domain.ru MAX_USERS=-1 MAX_ALIASES=-1 MAX_QUOTA_BYTES=0
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$(MAX_USERS)" || (echo "Передай MAX_USERS"; exit 1)
	@test -n "$(MAX_ALIASES)" || (echo "Передай MAX_ALIASES"; exit 1)
	@test -n "$(MAX_QUOTA_BYTES)" || (echo "Передай MAX_QUOTA_BYTES"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu setlimits "$(DOMAIN_NAME)" "$(MAX_USERS)" "$(MAX_ALIASES)" "$(MAX_QUOTA_BYTES)"

mailu-setmanager: ## Сделать пользователя менеджером домена, DOMAIN_NAME=domain.ru LOCALPART=user
	@test -n "$(DOMAIN_NAME)" || (echo "Передай DOMAIN_NAME"; exit 1)
	@test -n "$(LOCALPART)" || (echo "Передай LOCALPART"; exit 1)
	@docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu setmanager "$(DOMAIN_NAME)" "$(LOCALPART)"
