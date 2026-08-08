include .env.example
-include .env
export

COMPOSE_FILE ?= docker-compose-xray.yml

.PHONY: help env cnf

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

##@ Конфиг

cnf: ## Безопасно скопировать config.cnf из example
	@[ -f config.json ] || cp config.json.example config.json
