# Registry

Docker Registry с админ-панелью `a-registry`.

## Быстрый старт

```bash
make env
```

Отредактируй `.env`, задай `REGISTRY_PASSWORD`, затем:

```bash
make init
```

Команда:
- создаст внешнюю Docker-сеть, если её ещё нет,
- создаст `auth/htpasswd`,
- остановит старые контейнеры,
- скачает образы и поднимет контейнеры.

## Настройка `.env`

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Внешняя Docker-сеть |
| `VOLUME` | Имя Docker volume для хранения данных |
| `REGISTRY_PORT` | Порт Registry на хосте |
| `REGISTRY_USER` | Пользователь Registry |
| `REGISTRY_PASSWORD` | Пароль Registry |
| `REGISTRY_AUTH_REALM` | Realm для basic auth |
| `REGISTRY_STORAGE_DELETE_ENABLED` | `true`/`false` — разрешить удаление образов |
| `A_REGISTRY_TITLE` | Заголовок админ-панели |
| `A_REGISTRY_AUTH` | `true`/`false` — включить auth в админ-панели |
| `A_REGISTRY_DELETE_IMAGES` | `true`/`false` — разрешить удаление из админ-панели |

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + auth + down + pull + up |
| `make up` | Поднять контейнеры |
| `make down` | Остановить и удалить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make auth` | Пересоздать `auth/htpasswd` |
| `make logs` | Логи контейнеров (последние 100 строк, live) |
| `make ps` | Статус контейнеров |
| `make config` | Итоговый Docker Compose config |
| `make volume-rm` | Удалить хранилище вручную |
