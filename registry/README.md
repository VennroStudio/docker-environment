# Registry

Docker Registry.

## Быстрый старт

```bash
make env
```

Отредактируйте `.env` — обязательно задайте `REGISTRY_PASSWORD`. Затем:

```bash
make init
```

Команда:
- создаст внешнюю Docker-сеть (если её ещё нет),
- скачает образы и поднимет контейнеры.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная                         | Описание                                                          |
|-------------------------------------|---------------------------------------------------------------------|
| `PROJECT_NAME`                     | Название проекта Docker Compose                                   |
| `NETWORK`                          | Имя внешней Docker-сети, к которой подключаются контейнеры        |
| `VOLUME`                           | Путь к папке для хранения образов, например `./project-volume`    |
| `REGISTRY_PORT`                    | Локальный порт хоста для Docker Registry API                      |
| `AUTH_PATH`                        | Путь к файлу `htpasswd` (по умолчанию `auth/htpasswd`)             |
| `REGISTRY_USER`                    | Логин для доступа к Registry                                      |
| `REGISTRY_PASSWORD`                | Пароль для доступа к Registry                                     |
| `REGISTRY_AUTH_REALM`              | Realm для HTTP Basic Auth                                         |
| `REGISTRY_STORAGE_DELETE_ENABLED`  | `true`/`false` — разрешить удаление образов через API              |

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + pull + up |
| `make up` | Поднять контейнеры |
| `make down` | Остановить и удалить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make logs` | Логи контейнеров (последние 100 строк, live) |
