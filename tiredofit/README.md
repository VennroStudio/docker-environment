# TiredOfIt DB Backup

Контейнер для автоматических дампов базы данных.

## Быстрый старт

```bash
make init
```

Команда:
- создаст `.env` из `.env.example` (если его ещё нет),
- скачает образ и поднимет контейнер.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Имя внешней Docker-сети, к которой подключается контейнер |
| `TIMEZONE` | Часовой пояс контейнера |
| `DEFAULT_BACKUP_LOCATION` | Куда сохранять бэкапы, сейчас `FILESYSTEM` |
| `DEFAULT_FILESYSTEM_PATH` | Путь внутри контейнера для дампов, сейчас `/backup` |
| `DEFAULT_BACKUP_INTERVAL` | Интервал автоматического бэкапа в минутах |
| `DEFAULT_BACKUP_BEGIN` | Время первого запуска в формате `HHMM`, например `0300` |
| `DEFAULT_CLEANUP_TIME` | Через сколько минут удалять старые дампы |
| `DEFAULT_COMPRESSION` | Сжатие дампов, например `GZ` |
| `DB01_TYPE` | Тип базы данных, например `mysql` |
| `DB01_HOST` | Хост базы данных внутри Docker-сети |
| `DB01_PORT` | Порт базы данных |
| `DB01_NAME` | Имя базы или `ALL` для всех баз |
| `DB01_USER` | Пользователь базы данных |
| `DB01_PASS` | Пароль пользователя базы данных |
| `DB01_SPLIT_DB` | `TRUE` — сохранять базы отдельными файлами |
| `DB01_MYSQL_SINGLE_TRANSACTION` | `TRUE` — делать консистентный dump без блокировки InnoDB |

## Данные

- `./backup` — дампы баз данных
- `./logs` — логи контейнера

Обе папки не хранятся в git.

## Ручной запуск бэкапа

Запустить все jobs прямо сейчас:

```bash
make backup
```

Запустить конкретный job:

```bash
make backup-job JOB=01
```

## Восстановление

Интерактивное восстановление:

```bash
make restore
```

Восстановить конкретный файл:

```bash
make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database
```

`FILE` — путь внутри контейнера, обычно `/backup/...`.
`JOB` — номер блока переменных `DB01`, `DB02`, `DB03` и т.д.

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + pull + up |
| `make up` | Поднять backup-контейнер |
| `make down` | Остановить и удалить backup-контейнер |
| `make restart` | Перезапустить backup-контейнер |
| `make backup` | Запустить все backup jobs прямо сейчас |
| `make backup-job JOB=01` | Запустить один backup job |
| `make restore` | Интерактивно восстановить базу |
| `make restore-file JOB=01 FILE=/backup/file.sql.gz DB_NAME=database` | Восстановить конкретный файл |
| `make logs` | Логи контейнера (последние 100 строк, live) |
| `make ps` | Показать статус контейнера |
| `make config` | Показать итоговый compose-конфиг |
