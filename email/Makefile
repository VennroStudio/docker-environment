.DEFAULT_GOAL := ps

COMPOSE = docker compose --env-file .env -f docker-compose-email.yml

.PHONY: init up down restart pull logs ps config

init: ## Скачать образы и запустить; предварительно заполнить .env
	@$(MAKE) pull
	@$(MAKE) up

up: ## Запустить контейнеры и применить изменения Compose или .env
	@$(COMPOSE) up -d

down: ## Остановить и удалить контейнеры, сохранив данные
	@$(COMPOSE) down

restart: ## Перезапустить контейнеры без применения изменений Compose или .env
	@$(COMPOSE) restart

pull: ## Скачать образы указанных в Compose и .env версий
	@$(COMPOSE) pull

logs: ## Смотреть логи, SERVICE=stalwart или SERVICE=antivirus; без SERVICE все
	@$(COMPOSE) logs -f --tail=100 $(SERVICE)

ps: ## Показать состояние контейнеров
	@$(COMPOSE) ps

config: ## Проверить и показать итоговую конфигурацию Compose
	@$(COMPOSE) config
