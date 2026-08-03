# GlitchTip

GlitchTip в Docker.

Использует отдельные модули:
- PostgreSQL: `postgres-container:5432`
- Redis: `redis-container:6379`

## Быстрый старт

Сначала должны быть запущены PostgreSQL и Redis:

```bash
make -C ../postgres init
make -C ../redis init
```

Затем:

```bash
make init
```

Команда:
- создаст `.env` из `.env.example` (если его ещё нет),
- создаст внешнюю Docker-сеть (если её ещё нет),
- скачает образ и поднимет контейнер.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Имя внешней Docker-сети, к которой подключается контейнер |
| `GLITCHTIP_VERSION` | Версия образа GlitchTip |
| `VOLUME` | Имя Docker volume для файлов GlitchTip |
| `GLITCHTIP_PORT` | Локальный порт хоста для доступа к GlitchTip |
| `DATABASE_URL` | Подключение к PostgreSQL |
| `VALKEY_URL` | Подключение к Redis/Valkey |
| `SECRET_KEY` | Секретный ключ GlitchTip |
| `EMAIL_URL` | SMTP или `consolemail://` |
| `DEFAULT_FROM_EMAIL` | Email отправителя |
| `GLITCHTIP_DOMAIN` | Домен GlitchTip вместе со схемой `https://` |
| `ALLOWED_HOSTS` | Разрешённые домены |
| `CSRF_TRUSTED_ORIGINS` | Разрешённые origins для CSRF |
| `ENABLE_USER_REGISTRATION` | Разрешить регистрацию пользователей |
| `ENABLE_ORGANIZATION_CREATION` | Разрешить создание организаций |
| `ENABLE_ADMIN` | Включить стандартную Django admin-панель |
| `ENABLE_OPENAPI` | Включить OpenAPI-схему |
| `GLITCHTIP_ENABLE_UPTIME` | Включить uptime monitoring |
| `GLITCHTIP_ENABLE_LOGS` | Включить logs |
| `GLITCHTIP_ENABLE_MCP` | Включить MCP |
| `GLITCHTIP_ENABLE_DUCKDB` | Включить DuckDB |
| `GLITCHTIP_RETENTION_DAYS` | Сколько дней хранить данные |
| `SERVER_ROLE` | Роль контейнера, для одного сервера используется `all_in_one` |

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + pull + up |
| `make up` | Поднять контейнер |
| `make down` | Остановить и удалить контейнер |
| `make restart` | Перезапустить контейнер |
| `make logs` | Логи контейнера (последние 100 строк, live) |
| `make ps` | Показать статус контейнера |
| `make config` | Показать итоговый compose-конфиг |
