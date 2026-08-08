SHELL := /bin/bash

include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-xray.yml

.PHONY: help env gen-env ensure-env network init up down restart
.PHONY: keys uuid render link docker-up docker-down docker-pull logs ps config test-config

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

gen-env: ## Создать .env с UUID, REALITY-ключами и shortId, если .env ещё нет
	@set -euo pipefail; \
	if [ -f .env ]; then echo ".env уже существует: не перезаписываю"; exit 1; fi; \
	cp .env.example .env; \
	uuid=$$(uuidgen | tr '[:upper:]' '[:lower:]'); \
	keys=$$(docker run --rm $(XRAY_IMAGE) x25519); \
	private_key=$$(printf "%s\n" "$$keys" | awk -F': ' '/^(PrivateKey|Private key)/ {print $$2; exit}'); \
	public_key=$$(printf "%s\n" "$$keys" | awk -F': ' '/^(Password \(PublicKey\)|Public key)/ {print $$2; exit}'); \
	test -n "$$private_key"; \
	test -n "$$public_key"; \
	short_id=$$(openssl rand -hex 4); \
	perl -0pi -e "s|^XRAY_CLIENT_UUID=.*|XRAY_CLIENT_UUID=$$uuid|m; s|^XRAY_REALITY_PRIVATE_KEY=.*|XRAY_REALITY_PRIVATE_KEY=$$private_key|m; s|^XRAY_REALITY_PUBLIC_KEY=.*|XRAY_REALITY_PUBLIC_KEY=$$public_key|m; s|^XRAY_REALITY_SHORT_ID=.*|XRAY_REALITY_SHORT_ID=$$short_id|m" .env; \
	echo ".env создан. Теперь заполни XRAY_HOST и при необходимости XRAY_PORT."

ensure-env: env ## Проверить, что .env заполнен
	@set -euo pipefail; \
	test "$${XRAY_HOST}" != "vpn.example.com"; \
	test "$${XRAY_CLIENT_UUID}" != "change-me"; \
	test "$${XRAY_REALITY_PRIVATE_KEY}" != "change-me"; \
	test "$${XRAY_REALITY_PUBLIC_KEY}" != "change-me"; \
	test "$${XRAY_REALITY_SHORT_ID}" != "change-me"

##@ Сеть

network: env ## Создать внешнюю Docker-сеть, если её ещё нет
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)

##@ Ключи

keys: ## Сгенерировать REALITY private/public key
	docker run --rm $(XRAY_IMAGE) x25519

uuid: ## Сгенерировать UUID клиента
	@uuidgen | tr '[:upper:]' '[:lower:]'

##@ Конфиг

render: ensure-env ## Сгенерировать config.json из .env
	@python3 scripts/render_config.py

link: env ## Сгенерировать vless:// ссылку для клиента
	@python3 scripts/client_link.py

test-config: render ## Проверить config.json через xray run -test
	docker run --rm -v "$$PWD/config.json:/etc/xray/config.json:ro" $(XRAY_IMAGE) run -test -config /etc/xray/config.json

##@ Docker

init: render network docker-pull docker-up ## Сгенерировать конфиг и поднять Xray
up: render network docker-up ## Поднять Xray
down: docker-down ## Остановить и удалить Xray
restart: down up ## Перезапустить Xray

docker-up: ## Поднять контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать образ
	docker compose -f $(COMPOSE_FILE) pull

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус
	docker compose -f $(COMPOSE_FILE) ps

config: render ## Показать итоговый Docker Compose config
	docker compose -f $(COMPOSE_FILE) config
