-include .env
export

.PHONY: env help init centrifugo livekit mariadb postgres nginx portainer rabbitmq redis registry rustfs glitchtip tiredofit mail-single
.PHONY: deploy deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx
.PHONY: deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs deploy-postgres deploy-glitchtip deploy-tiredofit deploy-rclone
.PHONY: archive unarchive clear-mac-copy hosts tunnel hex-32 hex-64 push

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

init: centrifugo livekit mariadb nginx portainer rabbitmq redis registry rustfs ## Инициализировать все сервисы

centrifugo: ## Инициализировать Centrifugo
	$(MAKE) -C centrifugo init

livekit: ## Инициализировать LiveKit
	$(MAKE) -C livekit init

mariadb: ## Инициализировать MariaDB
	$(MAKE) -C mariadb init

postgres: ## Инициализировать PostgreSQL
	$(MAKE) -C postgres init

nginx: ## Инициализировать Nginx
	$(MAKE) -C nginx init

portainer: ## Инициализировать Portainer
	$(MAKE) -C portainer init

rabbitmq: ## Инициализировать RabbitMQ
	$(MAKE) -C rabbitmq init

redis: ## Инициализировать Redis
	$(MAKE) -C redis init

registry: ## Инициализировать Registry
	$(MAKE) -C registry init

rustfs: ## Инициализировать RustFS
	$(MAKE) -C rustfs init

glitchtip: ## Инициализировать GlitchTip
	$(MAKE) -C glitchtip init

tiredofit: ## Инициализировать TiredOfIt DB Backup
	$(MAKE) -C tiredofit init

mail-single: ## Инициализировать Mailu на одном сервере
	$(MAKE) -C mail/single init

##@ Production

deploy: deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs deploy-postgres deploy-glitchtip deploy-tiredofit deploy-rclone ## Отправить production-конфиги на сервер

deploy-centrifugo: ## Отправить .env.prod Centrifugo на сервер
	scp -P $(PORT) centrifugo/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/centrifugo/.env

deploy-livekit: ## Отправить .env.prod LiveKit на сервер
	scp -P $(PORT) livekit/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/livekit/.env

deploy-mariadb: ## Отправить .env.prod MariaDB на сервер
	scp -P $(PORT) mariadb/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/mariadb/.env

deploy-nginx: ## Отправить .env.prod Nginx на сервер
	scp -P $(PORT) nginx/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/nginx/.env

deploy-portainer: ## Отправить .env.prod Portainer на сервер
	scp -P $(PORT) portainer/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/portainer/.env

deploy-rabbitmq: ## Отправить .env.prod RabbitMQ на сервер
	scp -P $(PORT) rabbitmq/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/rabbitmq/.env

deploy-redis: ## Отправить .env.prod Redis на сервер
	scp -P $(PORT) redis/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/redis/.env

deploy-registry: ## Отправить .env.prod Registry на сервер
	scp -P $(PORT) registry/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/registry/.env

deploy-rustfs: ## Отправить .env.prod RustFS на сервер
	scp -P $(PORT) rustfs/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/rustfs/.env

deploy-postgres: ## Отправить .env.prod PostgreSQL на сервер
	scp -P $(PORT) postgres/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/postgres/.env

deploy-glitchtip: ## Отправить .env.prod GlitchTip на сервер
	scp -P $(PORT) glitchtip/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/glitchtip/.env

deploy-tiredofit: ## Отправить .env.prod TiredOfIt на сервер
	scp -P $(PORT) tiredofit/.env.prod $(HOST):$(DOCKER_SERVER_PATH)/tiredofit/.env

deploy-rclone: ## Отправить rclone.conf на сервер
	$(MAKE) -C rclone deploy

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

hex-32: ## Сгенерировать случайную строку из 32 символов
	openssl rand -hex 32

hex-64: ## Сгенерировать случайную строку из 64 символов
	openssl rand -hex 64

##@ Git
push: ## Auto save
	git add .
	git commit -m "update"
	git push
