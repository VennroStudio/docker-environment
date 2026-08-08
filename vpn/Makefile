include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-ipsec.yml
IPSEC_COMPOSE_FILE ?= docker-compose-ipsec.yml
OPENVPN_COMPOSE_FILE ?= docker-compose-o-vpn.yml
VPN_CONTAINER ?= vpn-container
OPENVPN_CONTAINER ?= o-vpn-container
CLIENT_CONFIG_DIR ?= .

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: client-configs client-ios client-android client-windows-linux
.PHONY: ipsec ipsec-up ipsec-down ipsec-restart ipsec-logs ipsec-ps ipsec-config
.PHONY: o-vpn o-vpn-up o-vpn-down o-vpn-restart o-vpn-logs o-vpn-ps o-vpn-config o-vpn-wait o-vpn-apply-config o-vpn-password

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

##@ OpenVPN

o-vpn: env network ## Инициализировать OpenVPN Access Server
	docker compose -f $(OPENVPN_COMPOSE_FILE) pull
	docker compose -f $(OPENVPN_COMPOSE_FILE) up -d
	$(MAKE) --no-print-directory o-vpn-wait
	$(MAKE) --no-print-directory o-vpn-apply-config

o-vpn-up: network ## Поднять OpenVPN Access Server
	docker compose -f $(OPENVPN_COMPOSE_FILE) up -d
	$(MAKE) --no-print-directory o-vpn-wait
	$(MAKE) --no-print-directory o-vpn-apply-config

o-vpn-down: ## Остановить и удалить OpenVPN Access Server
	docker compose -f $(OPENVPN_COMPOSE_FILE) down

o-vpn-restart: o-vpn-down o-vpn-up ## Перезапустить OpenVPN Access Server

o-vpn-logs: ## Показать логи OpenVPN Access Server
	docker compose -f $(OPENVPN_COMPOSE_FILE) logs -f --tail=100

o-vpn-ps: ## Показать статус OpenVPN Access Server
	docker compose -f $(OPENVPN_COMPOSE_FILE) ps

o-vpn-config: ## Показать итоговый OpenVPN config
	docker compose -f $(OPENVPN_COMPOSE_FILE) config

o-vpn-wait: ## Дождаться готовности OpenVPN AS
	@echo "Waiting for OpenVPN AS..."
	@for i in $$(seq 1 60); do \
		if docker exec $(OPENVPN_CONTAINER) sacli ConfigQuery >/dev/null 2>&1; then \
			echo "OpenVPN AS is ready"; \
			exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo "OpenVPN AS is not ready"; \
	exit 1

o-vpn-apply-config: ## Применить hostname и порты OpenVPN AS для профилей, QR и ссылок
	@test -n "$(OPENVPN_HOST)" || (echo "OPENVPN_HOST is required: set it to public server IP or DNS name" && exit 1)
	@test -n "$(OPENVPN_TCP_PORT)" || (echo "OPENVPN_TCP_PORT is required" && exit 1)
	@test -n "$(OPENVPN_UDP_PORT)" || (echo "OPENVPN_UDP_PORT is required" && exit 1)
	@test -n "$(OPENVPN_TCP_DAEMONS)" || (echo "OPENVPN_TCP_DAEMONS is required" && exit 1)
	@test -n "$(OPENVPN_UDP_DAEMONS)" || (echo "OPENVPN_UDP_DAEMONS is required" && exit 1)
	@test -n "$(OPENVPN_DNS)" || (echo "OPENVPN_DNS is required" && exit 1)
	docker exec $(OPENVPN_CONTAINER) sacli --key "host.name" --value "$(OPENVPN_HOST)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.daemon.tcp.port" --value "$(OPENVPN_TCP_PORT)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.daemon.udp.port" --value "$(OPENVPN_UDP_PORT)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.daemon.tcp.n_daemons" --value "$(OPENVPN_TCP_DAEMONS)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.daemon.udp.n_daemons" --value "$(OPENVPN_UDP_DAEMONS)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.client.routing.reroute_gw" --value "true" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.client.routing.reroute_dns" --value "custom" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.dhcp_option.dns.0" --value "$(OPENVPN_DNS)" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli --key "vpn.server.routing.gateway_access" --value "true" ConfigPut
	docker exec $(OPENVPN_CONTAINER) sacli start

o-vpn-password: ## Задать пароль пользователю openvpn
	@test -n "$(PASSWORD)" || (echo "Usage: make o-vpn-password PASSWORD='new-password'" && exit 1)
	docker exec $(OPENVPN_CONTAINER) sacli --user "openvpn" --new_pass "$(PASSWORD)" SetLocalPassword
	docker exec $(OPENVPN_CONTAINER) sacli start

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
