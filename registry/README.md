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
- создаст `auth/htpasswd` из `REGISTRY_USER` и `REGISTRY_PASSWORD`, если файла ещё нет,
- скачает образы и поднимет контейнеры.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная                         | Описание                                                          |
|-------------------------------------|---------------------------------------------------------------------|
| `PROJECT_NAME`                     | Название проекта Docker Compose                                   |
| `NETWORK`                          | Имя внешней Docker-сети, к которой подключаются контейнеры        |
| `VOLUME`                           | Путь к папке для хранения образов, например `./project-volume`    |
| `REGISTRY_PORT`                    | Локальный порт хоста для Docker Registry API                      |
| `REGISTRY_USER`                    | Логин для доступа к Registry                                      |
| `REGISTRY_PASSWORD`                | Пароль для доступа к Registry                                     |
| `REGISTRY_AUTH_REALM`              | Realm для HTTP Basic Auth                                         |
| `REGISTRY_STORAGE_DELETE_ENABLED`  | `true`/`false` — разрешить удаление образов через API              |

`auth/htpasswd` генерируется локально командой `make create-user` и монтируется в контейнер как `/auth/htpasswd`.

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + pull + up |
| `make up` | Поднять контейнеры |
| `make down` | Остановить и удалить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make logs` | Логи контейнеров (последние 100 строк, live) |
| `make create-user` | Создать основного пользователя из `.env`, если `auth/htpasswd` ещё нет |
| `make add-user` | Добавить пользователя в `auth/htpasswd` |
| `make change-password` | Изменить пароль пользователя |
| `make list-users` | Показать пользователей из `auth/htpasswd` |
| `make remove-user` | Удалить пользователя |
| `make list-images` | Показать репозитории в Registry |
| `make list-tags` | Показать теги выбранного образа |
