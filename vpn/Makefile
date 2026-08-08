include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-ipsec.yml
IPSEC_COMPOSE_FILE ?= docker-compose-ipsec.yml
VPN_CONTAINER ?= vpn-container
CLIENT_CONFIG_DIR ?= .

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: client-configs client-ios client-android client-windows-linux
.PHONY: ipsec ipsec-up ipsec-down ipsec-restart ipsec-logs ipsec-ps ipsec-config

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

##@ IPsec

init: env network docker-pull docker-up ## Инициализировать IPsec
up: network docker-up ## Поднять IPsec
down: docker-down ## Остановить и удалить IPsec
restart: down up ## Перезапустить IPsec

ipsec: init ## Инициализировать IPsec
ipsec-up: network ## Поднять IPsec
	docker compose -f $(IPSEC_COMPOSE_FILE) up -d

ipsec-down: ## Остановить и удалить IPsec
	docker compose -f $(IPSEC_COMPOSE_FILE) down

ipsec-restart: ipsec-down ipsec-up ## Перезапустить IPsec

ipsec-logs: ## Показать логи IPsec
	docker compose -f $(IPSEC_COMPOSE_FILE) logs -f --tail=100

ipsec-ps: ## Показать статус IPsec
	docker compose -f $(IPSEC_COMPOSE_FILE) ps

ipsec-config: ## Показать итоговый IPsec config
	docker compose -f $(IPSEC_COMPOSE_FILE) config

##@ Docker

docker-up: ## Поднять контейнер
	docker compose -f $(COMPOSE_FILE) up -d

docker-down: ## Остановить и удалить контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Клиентские конфиги

client-configs: client-ios client-android client-windows-linux ## Скопировать все клиентские конфиги

client-ios: ## Скопировать конфиг для iOS и macOS
	mkdir -p $(CLIENT_CONFIG_DIR)
	docker cp $(VPN_CONTAINER):/etc/ipsec.d/vpnclient.mobileconfig $(CLIENT_CONFIG_DIR)/

client-android: ## Скопировать конфиг для Android
	mkdir -p $(CLIENT_CONFIG_DIR)
	docker cp $(VPN_CONTAINER):/etc/ipsec.d/vpnclient.sswan $(CLIENT_CONFIG_DIR)/

client-windows-linux: ## Скопировать конфиг для Windows и Linux
	mkdir -p $(CLIENT_CONFIG_DIR)
	docker cp $(VPN_CONTAINER):/etc/ipsec.d/vpnclient.p12 $(CLIENT_CONFIG_DIR)/

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
