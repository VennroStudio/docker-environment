-include .env
export

.PHONY: env help init centrifugo livekit mariadb postgres nginx portainer rabbitmq redis registry rustfs glitchtip tiredofit rclone mail vpn
.PHONY: deploy deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx
.PHONY: deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs deploy-postgres deploy-glitchtip deploy-tiredofit deploy-rclone deploy-mail deploy-vpn
.PHONY: archive unarchive clear-mac-copy hosts tunnel hex-32 hex-64 push

TUNNELS = $(T_CENTRIFUGO_WS) $(T_CENTRIFUGO_API) $(T_MARIADB) $(T_PMA) $(T_GLITCHTIP) \
$(T_LIVEKIT) $(T_NGINX) $(T_RUSTFS_API) $(T_RUSTFS_WEB) $(T_PORTAINER) $(T_REDIS) \
$(T_REDIS_WEB) $(T_RABBIT_AMQP) $(T_RABBIT_WEB) $(T_POSTGRES) $(T_POSTGRES_WEB) $(T_REGISTRY) \
$(T_ROUTER)

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

##@ Инициализация

init: centrifugo livekit mariadb nginx portainer rabbitmq redis registry rustfs postgres glitchtip tiredofit rclone mail vpn ## Инициализировать все сервисы

define check-env
	@if [ -f $(1)/.env ]; then \
		$(MAKE) -C $(1) init; \
	else \
		echo "⚠️  $(1)/.env не найден, пропускаем инициализацию $(1)"; \
	fi
endef

centrifugo: ## Инициализировать Centrifugo
	$(call check-env,centrifugo)

livekit: ## Инициализировать LiveKit
	$(call check-env,livekit)

mariadb: ## Инициализировать MariaDB
	$(call check-env,mariadb)

postgres: ## Инициализировать PostgreSQL
	$(call check-env,postgres)

nginx: ## Инициализировать Nginx
	$(call check-env,nginx)

portainer: ## Инициализировать Portainer
	$(call check-env,portainer)

rabbitmq: ## Инициализировать RabbitMQ
	$(call check-env,rabbitmq)

redis: ## Инициализировать Redis
	$(call check-env,redis)

registry: ## Инициализировать Registry
	$(call check-env,registry)

rustfs: ## Инициализировать RustFS
	$(call check-env,rustfs)

glitchtip: ## Инициализировать GlitchTip
	$(call check-env,glitchtip)

tiredofit: ## Инициализировать TiredOfIt DB Backup
	$(call check-env,tiredofit)

rclone: ## Инициализировать Rclone
	$(call check-env,rclone)

mail: ## Инициализировать Mail
	$(call check-env,mail)

vpn: ## Инициализировать VPN
	$(call check-env,vpn)

##@ Production

deploy: deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs deploy-postgres deploy-glitchtip deploy-tiredofit deploy-rclone deploy-mail deploy-vpn ## Отправить production-конфиги на сервер

define check-deploy
	@if [ -f $(1)/.env.prod ]; then \
		scp -P $(PORT) $(1)/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/$(1)/.env; \
	else \
		echo "⚠️  $(1)/.env.prod не найден, пропускаем деплой $(1)"; \
	fi
endef

deploy-centrifugo: ## Отправить .env.prod Centrifugo на сервер
	$(call check-deploy,centrifugo)

deploy-livekit: ## Отправить .env.prod LiveKit на сервер
	$(call check-deploy,livekit)

deploy-mariadb: ## Отправить .env.prod MariaDB на сервер
	$(call check-deploy,mariadb)

deploy-nginx: ## Отправить .env.prod Nginx на сервер
	$(call check-deploy,nginx)

deploy-portainer: ## Отправить .env.prod Portainer на сервер
	$(call check-deploy,portainer)

deploy-rabbitmq: ## Отправить .env.prod RabbitMQ на сервер
	$(call check-deploy,rabbitmq)

deploy-redis: ## Отправить .env.prod Redis на сервер
	$(call check-deploy,redis)

deploy-registry: ## Отправить .env.prod Registry на сервер
	$(call check-deploy,registry)

deploy-rustfs: ## Отправить .env.prod RustFS на сервер
	$(call check-deploy,rustfs)

deploy-postgres: ## Отправить .env.prod PostgreSQL на сервер
	$(call check-deploy,postgres)

deploy-glitchtip: ## Отправить .env.prod GlitchTip на сервер
	$(call check-deploy,glitchtip)

deploy-tiredofit: ## Отправить .env.prod TiredOfIt на сервер
	$(call check-deploy,tiredofit)

deploy-rclone: ## Отправить .env.prod Rclone на сервер
	$(call check-deploy,rclone)

deploy-mail: ## Отправить .env.prod Mail на сервер
	$(call check-deploy,mail)

deploy-vpn: ## Отправить .env.prod VPN на сервер
	$(call check-deploy,vpn)

##@ Архиватор
archive: ## Архивирование в формате data-DD-MM-YYYY, передать FOLDER=folderName
	tar -czvf "data-$(DATE).tar.gz" "$(FOLDER)/"

unarchive: ## Разархивирование для формата data-DD-MM-YYYY, передать DATE-ARG=DD-MM-YYYY
	tar -xzvf "data-$(DATE-ARG).tar.gz"

clear-mac-copy: ## Очистка файлов MAC в архиве
	find . -type f -name '._*' -delete

##@ Hosts
hosts: ## Добавить локальный домен
	sudo nano /etc/hosts

##@ SSH

tunnel: ## Открыть SSH-туннели к серверу
	ssh -N -p $(PORT) $(foreach TUNNEL,$(TUNNELS),-L $(TUNNEL)) $(HOST)

##@ hex

hex-8: ## Сгенерировать случайную строку из 8 байт
	openssl rand -hex 8

hex-16: ## Сгенерировать случайную строку из 16 байт
	openssl rand -hex 16

hex-32: ## Сгенерировать случайную строку из 32 байт
	openssl rand -hex 32

hex-64: ## Сгенерировать случайную строку из 64 байт
	openssl rand -hex 64

##@ Git
push: ## Auto save
	git add .
	git commit -m "update"
	git push
