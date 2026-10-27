include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-email.yml
COMPOSE = docker compose -f $(COMPOSE_FILE)

.PHONY: help env network init up down restart pull logs antivirus-logs antivirus-logs-follow ps config

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

##@ Email

init: env network ## Скачать образы и запустить; предварительно заполнить .env
	@$(MAKE) pull
	@$(MAKE) up

up: network ## Запустить контейнеры; SERVICE=webmail только веб-почту
	@$(COMPOSE) up -d $(SERVICE)

down: ## Остановить и удалить контейнеры, сохранив данные
	@$(COMPOSE) down

restart: ## Перезапустить контейнеры без применения изменений Compose или .env
	@$(COMPOSE) restart

pull: ## Скачать образы; SERVICE=webmail только веб-почту
	@$(COMPOSE) pull $(SERVICE)

logs: ## Смотреть логи, SERVICE=stalwart, stalwart-antivirus или webmail; без SERVICE все
	@$(COMPOSE) logs -f --tail=100 $(SERVICE)

antivirus-logs: ## Последние 50 строк журнала обнаружений; пример: make antivirus-logs
	@$(COMPOSE) exec -T stalwart-antivirus tail -n 50 /var/log/clamav/milter.log

antivirus-logs-follow: ## Следить за обнаружениями в реальном времени; пример: make antivirus-logs-follow
	@$(COMPOSE) exec -T stalwart-antivirus tail -f /var/log/clamav/milter.log

ps: ## Показать состояние контейнеров
	@$(COMPOSE) ps

config: ## Проверить и показать итоговую конфигурацию Compose
	@$(COMPOSE) config
