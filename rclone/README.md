# Rclone

Архивирование выбранных папок проекта и отправка архива в удалённое хранилище.

## Быстрый старт

```bash
make init
make cnf
make backup
```

Команда `make init`:
- создаст `.env` из `.env.example` (если его ещё нет),
- скачает образ `rclone/rclone`.

Команда `make cnf` запускает интерактивную настройку `rclone.conf`.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `RCLONE_REMOTE` | Куда отправлять архивы, например `yadisk:backup/docker-server` |
| `RCLONE_CRON` | Расписание cron для автоматического запуска `make backup` |
| `ARCHIVE_NAME` | Префикс имени архива |
| `ARCHIVE_KEEP` | Сколько последних архивов оставлять локально |
| `BACKUP_PATHS` | Список папок для архивации, пути указываются от корня проекта |

Пример:

```env
BACKUP_PATHS=nginx/data nginx/letsencrypt
```

## Данные

- `./config/rclone.conf` — конфиг подключения к удалённому хранилищу, в git не хранится
- `./archives` — локальные архивы перед отправкой, в git не хранятся

Архив создаётся из папок, указанных в `BACKUP_PATHS`.

## Deploy конфига

```bash
make deploy
```

Команда отправляет:

```text
rclone/config/rclone.conf
```

на сервер в:

```text
$(DOCKER_SERVER_PATH)/rclone/config/rclone.conf
```

Для deploy используются `HOST`, `PORT`, `DOCKER_SERVER_PATH` из общего `.env` в корне проекта.

## Cron

Расписание задаётся в `.env`:

```env
RCLONE_CRON=30 3 * * *
```

Пример выше запускает `make backup` каждый день в `03:30`.

Установить cron-задачу:

```bash
make cron-install
```

Показать cron-задачу:

```bash
make cron-list
```

Удалить cron-задачу:

```bash
make cron-remove
```

Логи cron пишутся в:

```text
rclone/logs/cron.log
```

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + pull |
| `make cnf` | Интерактивно настроить `rclone.conf` |
| `make archive` | Создать архив из `BACKUP_PATHS` |
| `make archive-prune` | Оставить только последние `ARCHIVE_KEEP` архивов |
| `make backup` | Создать архив и отправить его в `RCLONE_REMOTE` |
| `make deploy` | Отправить готовый `rclone.conf` на сервер |
| `make cron-install` | Установить cron-задачу для `make backup` |
| `make cron-list` | Показать cron-задачу |
| `make cron-remove` | Удалить cron-задачу |
| `make config` | Показать итоговый compose-конфиг |
