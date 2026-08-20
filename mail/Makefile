include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-mail.yml
NPM_CONTAINER ?= nginx-container
NPM_CERT ?=
DOMAIN_NAME ?= $(DOMAIN)
MODE ?= create
DELETE_FLAGS ?=
ALIAS_FLAGS ?=
CMD ?=
MAILU = docker compose -f $(COMPOSE_FILE) exec -T admin flask mailu
EMAIL_LOCALPART = $(firstword $(subst @, ,$(EMAIL)))
EMAIL_DOMAIN = $(word 2,$(subst @, ,$(EMAIL)))
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
.PHONY: mailu mailu-dns mailu-domains mailu-users mailu-aliases
.PHONY: mailu-domain-create mailu-admin-create mailu-user-create mailu-password
.PHONY: mailu-user-delete mailu-alias-create mailu-alias-delete

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

npm-cert-copy: ## Скопировать сертификат NPM в Mailu, NPM_CERT=npm-18
	@mkdir -p certs
	@docker exec "$(NPM_CONTAINER)" cat "/etc/letsencrypt/live/$(NPM_CERT)/fullchain.pem" > certs/cert.pem
	@docker exec "$(NPM_CONTAINER)" cat "/etc/letsencrypt/live/$(NPM_CERT)/privkey.pem" > certs/key.pem
	@chmod 600 certs/key.pem

npm-cert-install: npm-cert-copy cert-reload ## Скопировать сертификат NPM и перезагрузить TLS, NPM_CERT=npm-18

cert-reload: ## Перезагрузить TLS в front после замены certs/cert.pem и certs/key.pem
	@docker compose -f $(COMPOSE_FILE) exec -T front nginx -s reload
	@docker compose -f $(COMPOSE_FILE) exec -T front doveadm reload

cert-check: ## Проверить текущий сертификат Mailu в certs/cert.pem
	@openssl x509 -in certs/cert.pem -noout -subject -issuer -dates

##@ Mailu CLI

mailu: ## Выполнить любую Mailu CLI команду, CMD='config-export user'
	@$(MAILU) $(CMD)

mailu-dns: ## Показать основные DNS-записи Mailu
	@$(MAILU) config-export --dns domain.dns_mx domain.dns_spf domain.dns_dkim domain.dns_dmarc

mailu-domains: ## Показать домены Mailu
	@$(MAILU) config-export domain

mailu-users: ## Показать пользователей Mailu
	@$(MAILU) config-export user

mailu-aliases: ## Показать алиасы Mailu
	@$(MAILU) config-export alias

mailu-domain-create: ## Создать домен, DOMAIN_NAME=domain.ru
	@$(MAILU) domain "$(DOMAIN_NAME)"

mailu-admin-create: ## Создать/обновить админа, EMAIL=postmaster@domain.ru PASSWORD='pass' MODE=create|update|ifmissing
	@$(MAILU) admin --mode "$(MODE)" "$(EMAIL_LOCALPART)" "$(EMAIL_DOMAIN)" "$(PASSWORD)"

mailu-user-create: ## Создать пользователя, EMAIL=user@domain.ru PASSWORD='pass'
	@$(MAILU) user "$(EMAIL_LOCALPART)" "$(EMAIL_DOMAIN)" "$(PASSWORD)"

mailu-password: ## Сменить пароль, EMAIL=user@domain.ru PASSWORD='pass'
	@$(MAILU) password "$(EMAIL_LOCALPART)" "$(EMAIL_DOMAIN)" "$(PASSWORD)"

mailu-user-delete: ## Отключить пользователя, EMAIL=user@domain.ru DELETE_FLAGS='--really' удалит полностью
	@$(MAILU) user-delete "$(EMAIL)" $(DELETE_FLAGS)

mailu-alias-create: ## Создать алиас, EMAIL=info@domain.ru DESTINATION='user@domain.ru' ALIAS_FLAGS='--wildcard'
	@$(MAILU) alias "$(EMAIL_LOCALPART)" "$(EMAIL_DOMAIN)" "$(DESTINATION)" $(ALIAS_FLAGS)

mailu-alias-delete: ## Удалить алиас, EMAIL=info@domain.ru
	@$(MAILU) alias-delete "$(EMAIL)"
