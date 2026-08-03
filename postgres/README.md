# PostgreSQL

PostgreSQL с pgAdmin в Docker.

## Быстрый старт

```bash
make init
```

Команда:
- создаст `.env` из `.env.example` (если его ещё нет),
- создаст внешнюю Docker-сеть (если её ещё нет),
- скачает образы и поднимет контейнеры.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Имя внешней Docker-сети, к которой подключается контейнер |
| `VOLUME` | Имя Docker volume для хранения данных PostgreSQL |
| `POSTGRES_PORT` | Локальный порт хоста для PostgreSQL |
| `POSTGRES_VERSION` | Версия PostgreSQL |
| `POSTGRES_DB` | База, которая создаётся при первом запуске |
| `POSTGRES_USER` | Пользователь, который создаётся при первом запуске |
| `POSTGRES_PASSWORD` | Пароль пользователя |
| `PGADMIN_EMAIL` | Логин для pgAdmin |
| `PGADMIN_PASSWORD` | Пароль для pgAdmin |
| `PGADMIN_PORT` | Локальный порт хоста для pgAdmin |

Доступ внутри Docker-сети:
- **Host:** `postgres-container`
- **Port:** `5432`

pgAdmin:
- **URL:** `http://localhost:${PGADMIN_PORT}`
- **Email:** значение `PGADMIN_EMAIL`
- **Password:** значение `PGADMIN_PASSWORD`

Подключение PostgreSQL в pgAdmin:
- **Host:** `postgres-container`
- **Port:** `5432`
- **Database:** значение `POSTGRES_DB`
- **Username:** значение `POSTGRES_USER`
- **Password:** значение `POSTGRES_PASSWORD`

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + pull + up |
| `make up` | Поднять контейнеры |
| `make down` | Остановить и удалить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make logs` | Логи контейнеров (последние 100 строк, live) |
| `make ps` | Показать статус контейнеров |
| `make volume-inspect` | Показать информацию о хранилище |
| `make volume-rm` | Удалить хранилище вручную (полная потеря данных) |
