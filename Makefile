include .env
export

COMPOSE_FILE := docker-compose-$(ENV).yml

init: down delete-proxy add-proxy up

up:
	docker compose -f $(COMPOSE_FILE) pull && \
	docker compose -f $(COMPOSE_FILE) up -d --build --pull always --force-recreate

down:
	docker compose -f $(COMPOSE_FILE) down

start:
	docker compose -f $(COMPOSE_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) stop

clean:
	docker compose -f $(COMPOSE_FILE) down -v

logs-nginx:
	docker compose -f $(COMPOSE_FILE) logs -f nginx-container

logs-db:
	docker compose -f $(COMPOSE_FILE) logs -f mariadb-container

logs-pma:
	docker compose -f $(COMPOSE_FILE) logs -f phpmyadmin-container

go-db:
	docker exec -it mariadb-container sh

import-env:
	scp -P $(SERVER_PORT) docker/ansible/.env.server $(SSH):$(SERVER_DUMP_PATH).env

import-db-h:
	docker exec -i mariadb-container mysql -u root -p${MYSQL_ROOT_PASSWORD} ${DB_NAME} < ${HOME_DUMP_PATH}${DUMP_NAME}

import-db-gz:
	gunzip -c ${HOME_DUMP_PATH}${DUMP_NAME} | docker exec -i mariadb-container mysql -u root -p${MYSQL_ROOT_PASSWORD} ${DB_NAME}

upload-dump:
	scp ${HOME_DUMP_PATH}${DUMP_NAME} ${SSH}:${SERVER_DUMP_PATH}

generate-user:
	mkdir -p ./docker/server/registry/auth
	htpasswd -Bbc ./docker/server/registry/auth/htpasswd ${REGISTRY_USER} ${REGISTRY_PASSWORD}

ansible-build:
	docker compose -f docker-compose-ansible.yml build

ansible-setup:
	docker compose -f docker-compose-ansible.yml run --rm ansible -i inventory.ini deploy.yml

ansible-clean:
	docker compose -f docker-compose-ansible.yml down
	docker rmi vennro-ansible 2>/dev/null || true

minio-up:
	docker compose -f docker-compose-minio.yml up -d

minio-pull:
	docker compose -f docker-compose-minio.yml pull

minio-stop:
	docker compose -f docker-compose-minio.yml stop

minio-clean:
	docker compose -f docker-compose-minio.yml down
	docker rmi minio/minio 2>/dev/null || true

redis-up:
	docker compose -f docker-compose-redis.yml up -d

redis-pull:
	docker compose -f docker-compose-redis.yml pull

redis-stop:
	docker compose -f docker-compose-redis.yml stop

redis-clean:
	docker compose -f docker-compose-redis.yml down
	docker rmi redis:7-alpine 2>/dev/null || true

rclone-install:
	sudo -v ; curl https://rclone.org/install.sh | sudo bash

rclone-config:
	rclone config

rclone-test:
	rclone ls yadisk:test-connect/

rclone-backup-s3:
	rclone copy /home/vennro/infrastructure/storage yadisk:backup/storage

add-proxy:
	docker network create proxy

delete-proxy:
	docker network rm proxy

push:
	git add .
	git commit -m "update"
	git push

help:
	@echo "Доступные команды:"
	@echo "  make init             - Полная перезагрузка (down + up)"
	@echo "  make up               - Запуск с пересборкой образов"
	@echo "  make down             - Остановка контейнеров"
	@echo "  make start            - Запуск существующих контейнеров"
	@echo "  make stop             - Остановка контейнеров"
	@echo "  make clean            - Очистка (удаление volumes)"
	@echo "  make logs-nginx       - Логи Nginx"
	@echo "  make logs-db          - Логи MariaDB"
	@echo "  make logs-pma         - Логи phpMyAdmin"
	@echo "  make go-db            - Вход в shell MariaDB"
	@echo "  make import-db-h      - Импорт SQL дампа (.sql)"
	@echo "  make import-db-gz     - Импорт сжатого дампа (.sql.gz)"
	@echo "  make upload-dump      - Загрузка дампа на сервер"
	@echo "  make generate-user    - Создание пользователя Registry"
	@echo "  make ansible-build    - Собрать контейнер Ansible"
	@echo "  make ansible-setup    - Выполнить установку Ansible на сервере"
	@echo "  make ansible-clean    - Удалить контейнер Ansible"
	@echo "  make minio-up         - Запустить контейнер MinIO"
	@echo "  make minio-pull       - Скачать/обновить образ MinIO"
	@echo "  make minio-stop       - Остановить контейнер MinIO"
	@echo "  make minio-clean      - Удалить контейнер и образ MinIO"
	@echo "  make redis-up         - Запустить контейнер Redis"
	@echo "  make redis-pull       - Скачать/обновить образ Redis"
	@echo "  make redis-stop       - Остановить контейнер Redis"
	@echo "  make redis-clean      - Удалить контейнер и образ Redis"
	@echo "  make rclone-install   - Установить rclone на сервер"
	@echo "  make rclone-config    - Настроить подключение к Яндекс Диску"
	@echo "  make rclone-test      - Проверить подключение к Яндекс Диску"
	@echo "  make rclone-backup-s3 - Создать бекап MinIO на Яндекс Диск"

.PHONY: init up down start stop clean logs-nginx logs-db logs-pma go-db import-db-h import-db-gz upload-dump generate-user ansible-build ansible-setup ansible-clean minio-up minio-pull minio-stop minio-clean redis-up redis-pull redis-stop redis-clean rclone-install rclone-config rclone-test rclone-backup-s3 push help