include .env.example
-include .env
-include ../.env
export

COMPOSE_FILE ?= docker-compose-rclone.yml
MAKE_BIN ?= $(shell command -v make)

.PHONY: help env init config archive archive-prune backup deploy
.PHONY: cron-install cron-list cron-remove
.PHONY: docker-pull logs ps compose-config

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

##@ Rclone

init: env docker-pull ## Инициализировать rclone

cnf: env ## Интерактивно настроить rclone.conf
	docker compose -f $(COMPOSE_FILE) run --rm rclone config

archive: env ## Создать архив из BACKUP_PATHS
	@mkdir -p archives
	@set -eu; \
	if [ -z "$(strip $(BACKUP_PATHS))" ]; then \
		echo "BACKUP_PATHS must be set in .env" >&2; \
		exit 1; \
	fi; \
	for path in $(BACKUP_PATHS); do \
		if [ ! -e "../$$path" ]; then \
			echo "Missing backup path: $$path" >&2; \
			exit 1; \
		fi; \
	done; \
	tar -czf "archives/$(ARCHIVE_NAME)-$$(date +%Y-%m-%d_%H-%M-%S).tar.gz" -C .. $(BACKUP_PATHS)

archive-prune: env ## Оставить только последние ARCHIVE_KEEP архивов
	@set -eu; \
	count=0; \
	for file in $$(ls -1t archives/$(ARCHIVE_NAME)-*.tar.gz 2>/dev/null || true); do \
		count=$$((count + 1)); \
		if [ "$$count" -gt "$(ARCHIVE_KEEP)" ]; then \
			rm -f "$$file"; \
		fi; \
	done

backup: archive archive-prune ## Создать архив и отправить его на удалённое хранилище
	docker compose -f $(COMPOSE_FILE) run --rm rclone copy /archives $(RCLONE_REMOTE) --progress

deploy: ## Отправить готовый rclone.conf на сервер
	scp -P $(PORT) config/rclone.conf $(HOST):$(DOCKER_SERVER_PATH)/rclone/config/rclone.conf

cron-install: env ## Установить cron-задачу для автоматического rclone backup
	@mkdir -p logs
	@(crontab -l 2>/dev/null | grep -v 'docker-server rclone backup'; \
	  echo '$(RCLONE_CRON) cd $(CURDIR) && $(MAKE_BIN) backup >> logs/cron.log 2>&1 # docker-server rclone backup') | crontab -

cron-list: ## Показать cron-задачи rclone
	@crontab -l 2>/dev/null | grep 'docker-server rclone backup' || true

cron-remove: ## Удалить cron-задачу rclone
	@crontab -l 2>/dev/null | grep -v 'docker-server rclone backup' | crontab -

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Логи

logs: ## Показать логи
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый compose-конфиг
	docker compose -f $(COMPOSE_FILE) config
