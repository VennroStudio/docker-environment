-include .env
export

.PHONY: help init centrifugo livekit mariadb nginx portainer rabbitmq redis registry rustfs
.PHONY: deploy deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx
.PHONY: deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs

##@ Помощь

help: ## Показать список команд
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} \
	   /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
	   /^[a-zA-Z_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
	   $(MAKEFILE_LIST)
	@echo ""

##@ Инициализация

init: centrifugo livekit mariadb nginx portainer rabbitmq redis registry rustfs ## Инициализировать все сервисы

centrifugo: ## Инициализировать Centrifugo
	$(MAKE) -C centrifugo init

livekit: ## Инициализировать LiveKit
	$(MAKE) -C livekit init

mariadb: ## Инициализировать MariaDB
	$(MAKE) -C mariadb init

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

##@ Production

deploy: deploy-centrifugo deploy-livekit deploy-mariadb deploy-nginx deploy-portainer deploy-rabbitmq deploy-redis deploy-registry deploy-rustfs ## Отправить все .env.prod на сервер

deploy-centrifugo: ## Отправить .env.prod Centrifugo на сервер
	scp -P $(PORT) centrifugo/.env.prod $(HOST):centrifugo/.env

deploy-livekit: ## Отправить .env.prod LiveKit на сервер
	scp -P $(PORT) livekit/.env.prod $(HOST):livekit/.env

deploy-mariadb: ## Отправить .env.prod MariaDB на сервер
	scp -P $(PORT) mariadb/.env.prod $(HOST):mariadb/.env

deploy-nginx: ## Отправить .env.prod Nginx на сервер
	scp -P $(PORT) nginx/.env.prod $(HOST):nginx/.env

deploy-portainer: ## Отправить .env.prod Portainer на сервер
	scp -P $(PORT) portainer/.env.prod $(HOST):portainer/.env

deploy-rabbitmq: ## Отправить .env.prod RabbitMQ на сервер
	scp -P $(PORT) rabbitmq/.env.prod $(HOST):rabbitmq/.env

deploy-redis: ## Отправить .env.prod Redis на сервер
	scp -P $(PORT) redis/.env.prod $(HOST):redis/.env

deploy-registry: ## Отправить .env.prod Registry на сервер
	scp -P $(PORT) registry/.env.prod $(HOST):registry/.env

deploy-rustfs: ## Отправить .env.prod RustFS на сервер
	scp -P $(PORT) rustfs/.env.prod $(HOST):rustfs/.env

##@ Rclone
rclone-install: ## Установить rclone на сервер
	sudo -v ; curl https://rclone.org/install.sh | sudo bash

rclone-config: ## Настроить подключение к Яндекс Диску
	rclone config

rclone-test: ## Проверить подключение к Яндекс Диску
	rclone ls yadisk:test-connect/

rclone-backup-s3: ## Создать бекап FOLDER=/folderName на Яндекс Диск в BACKUP_NAME=name
	rclone copy $(FOLDER) yadisk:backup/$(BACKUP_NAME)

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

##@ Git
push: ## Auto save
	git add .
	git commit -m "update"
	git push