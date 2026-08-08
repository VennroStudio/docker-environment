SHELL := /bin/bash

include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-hysteria.yml
ACME_COMPOSE_FILE ?= docker-compose-hysteria-acme.yml

.PHONY: help env gen-env ensure-env network init up down restart
.PHONY: init-acme up-acme config-acme render cert-selfsigned fingerprint link
.PHONY: docker-up docker-up-acme docker-down docker-pull logs ps config

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

gen-env: ## Создать .env с новыми паролями, если .env ещё нет
	@set -euo pipefail; \
	if [ -f .env ]; then echo ".env уже существует: не перезаписываю"; exit 1; fi; \
	cp .env.example .env; \
	password=$$(openssl rand -hex 24); \
	obfs_password=$$(openssl rand -hex 24); \
	perl -0pi -e "s|^HYSTERIA_PASSWORD=.*|HYSTERIA_PASSWORD=$$password|m; s|^HYSTERIA_OBFS_PASSWORD=.*|HYSTERIA_OBFS_PASSWORD=$$obfs_password|m" .env; \
	echo ".env создан. Теперь заполни HYSTERIA_HOST, HYSTERIA_SNI и TLS-настройки."

ensure-env: env ## Проверить, что .env заполнен
	@set -euo pipefail; \
	test "$${HYSTERIA_HOST}" != "vpn.example.com"; \
	test "$${HYSTERIA_SNI}" != "vpn.example.com"; \
	test "$${HYSTERIA_PASSWORD}" != "change-me"; \
	test "$${HYSTERIA_OBFS_PASSWORD}" != "change-me"; \
	if [ "$${HYSTERIA_TLS_MODE}" = "acme" ]; then \
		test "$${HYSTERIA_ACME_EMAIL}" != "admin@example.com"; \
	elif [ "$${HYSTERIA_TLS_MODE}" = "cert" ]; then \
		test -d "$${HYSTERIA_CERTS_HOST_PATH}"; \
	else \
		echo "HYSTERIA_TLS_MODE должен быть acme или cert"; \
		exit 1; \
	fi

##@ Сеть

network: env ## Создать внешнюю Docker-сеть, если её ещё нет
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ Конфиг

render: ensure-env ## Сгенерировать config.yaml из .env
	@python3 scripts/render_config.py

cert-selfsigned: env ## Создать self-signed сертификат в ./certs
	@set -euo pipefail; \
	mkdir -p certs; \
	openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
		-keyout certs/privkey.pem \
		-out certs/fullchain.pem \
		-days 3650 -nodes \
		-subj "/CN=$${HYSTERIA_SNI}"; \
	echo "Создано: certs/fullchain.pem и certs/privkey.pem"; \
	echo "Для клиента поставь HYSTERIA_CLIENT_INSECURE=1 и pin из make fingerprint"

fingerprint: env ## Показать pinSHA256 для self-signed сертификата
	@openssl x509 -in "$${HYSTERIA_CERTS_HOST_PATH}/fullchain.pem" -outform der \
		| openssl dgst -sha256 -binary \
		| xxd -p -c 256

link: env ## Сгенерировать hysteria2:// ссылку для клиента
	@python3 scripts/client_link.py

##@ Docker

init: render network docker-pull docker-up ## Сгенерировать конфиг и поднять Hysteria 2
up: render network docker-up ## Поднять Hysteria 2
init-acme: render network docker-pull docker-up-acme ## Поднять Hysteria 2 с TCP-портом для ACME HTTP
up-acme: render network docker-up-acme ## Поднять Hysteria 2 с TCP-портом для ACME HTTP
down: docker-down ## Остановить и удалить Hysteria 2
restart: down up ## Перезапустить Hysteria 2

docker-up: ## Поднять контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-up-acme: ## Поднять контейнер с ACME HTTP портом
	docker compose -f $(COMPOSE_FILE) -f $(ACME_COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус
	docker compose -f $(COMPOSE_FILE) ps

config: render ## Показать итоговый Docker Compose config
	docker compose -f $(COMPOSE_FILE) config

config-acme: render ## Показать итоговый Docker Compose config с ACME HTTP портом
	docker compose -f $(COMPOSE_FILE) -f $(ACME_COMPOSE_FILE) config
