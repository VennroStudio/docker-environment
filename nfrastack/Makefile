include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-nfrastack.yml

.PHONY: help env network init up down restart
.PHONY: docker-up docker-down docker-pull logs ps config
.PHONY: backup backup-job restore restore-file

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

##@ Nfrastack DB Backup

init: env network docker-pull docker-up ## Инициализировать backup-контейнер
up: env network docker-up ## Поднять backup-контейнер
down: docker-down ## Остановить и удалить backup-контейнер
restart: down up ## Перезапустить backup-контейнер

docker-up: ## Поднять backup-контейнер
	docker compose -f $(COMPOSE_FILE) up -d --wait --wait-timeout 90

docker-down: ## Остановить и удалить backup-контейнер
	docker compose -f $(COMPOSE_FILE) down

docker-pull: ## Скачать свежий образ
	docker compose -f $(COMPOSE_FILE) pull

##@ Бэкап

backup: up ## Запустить все backup jobs прямо сейчас
	docker compose -f $(COMPOSE_FILE) exec -T nfrastack backup-now

backup-job: ## Запустить один job: make backup-job JOB=01
	@case "$(JOB)" in 0[1-9]|[1-9][0-9]) ;; *) echo "JOB must be 01..99, example: make backup-job JOB=01" >&2; exit 1;; esac
	@[ -n "$(DB$(JOB)_TYPE)" ] || (echo "DB$(JOB)_TYPE is required" >&2; exit 1)
	@$(MAKE) up
	docker compose -f $(COMPOSE_FILE) exec -T nfrastack backup$(JOB)-now

restore: up ## Интерактивно восстановить базу из backup-файла
	docker compose -f $(COMPOSE_FILE) exec nfrastack restore

restore-file: ## Восстановить файл: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database
	@case "$(JOB)" in 0[1-9]|[1-9][0-9]) ;; *) echo "JOB must be 01..99, example: make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database" >&2; exit 1;; esac
	@[ -n "$(FILE)" ] || (echo "FILE is required, example: make restore-file JOB=01 FILE=/backup/file.sql.gz" >&2; exit 1)
	@case "$(FILE)" in /*) ;; *) echo "FILE must be an absolute container path, example: /backup/file.sql.gz" >&2; exit 1;; esac
	@[ -n "$(DB$(JOB)_TYPE)" ] || (echo "DB$(JOB)_TYPE is required" >&2; exit 1)
	@[ -n "$(DB$(JOB)_HOST)" ] && [ -n "$(DB$(JOB)_PORT)" ] && [ -n "$(DB$(JOB)_USER)" ] || (echo "DB$(JOB)_HOST, DB$(JOB)_PORT and DB$(JOB)_USER are required" >&2; exit 1)
	@case "$(if $(DB_NAME),$(DB_NAME),$(DB$(JOB)_NAME))" in ""|ALL|all) echo "DB_NAME must name one target database" >&2; exit 1;; esac
	@$(MAKE) up
	docker compose -f $(COMPOSE_FILE) exec -T nfrastack /command/with-contenv bash -o pipefail -c \
		'pass_var="DB$${1}_PASS"; test -f "$$2" || { echo "Backup file not found: $$2" >&2; exit 1; }; \
		case "$$2" in *.gz) gzip -t "$$2" || exit 1;; esac; \
		source /usr/local/bin/restore "$$2" "$$3" "$$4" "$$5" "$$6" "$${!pass_var}" "$$7" "$$8"; exit "$${exit_code:-1}"' \
		restore-file "$(JOB)" "$(FILE)" "$(DB$(JOB)_TYPE)" "$(DB$(JOB)_HOST)" \
		"$(if $(DB_NAME),$(DB_NAME),$(DB$(JOB)_NAME))" "$(DB$(JOB)_USER)" \
		"$(DB$(JOB)_PORT)" "$(or $(DB$(JOB)_MYSQL_ENABLE_TLS),FALSE)"

##@ Логи

logs: ## Показать логи (последние 100)
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

ps: ## Показать статус контейнера
	docker compose -f $(COMPOSE_FILE) ps

##@ Проверка

config: ## Показать итоговый конфиг
	docker compose -f $(COMPOSE_FILE) config
