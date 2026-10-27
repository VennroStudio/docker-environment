# Cloudflared

Временная публичная HTTPS-ссылка на запущенный веб-контейнер.
Один Compose-файл, без скриптов и генерируемых конфигов.

## Быстрый старт

Из папки `cloudflared`:

```bash
make env
```

Укажи в `.env` свой `PROJECT_NAME` и существующую сеть приложения в `NETWORK`. Затем:

```bash
make init
make share CONTAINER=project-container PORT=project-port
```

Или из корня проекта:

```bash
make -C cloudflared share CONTAINER=project-container PORT=project-port NETWORK=project-network
```

- `CONTAINER` — имя контейнера или сервиса в Docker-сети.
- `PORT` — внутренний порт приложения, не опубликованный порт компьютера.
- Приложение должно быть уже запущено и доступно из указанной сети.

`project-container`, `project-port` и `project-network` — шаблоны: замени их именем контейнера, числовым портом и именем сети своего приложения.

Ссылка `https://....trycloudflare.com` появится в терминале.
Терминал остаётся занят туннелем. `Ctrl+C` останавливает туннель и удаляет его контейнер.
Само приложение продолжает работать. Следующий запуск создаёт новую ссылку.

## Настройка `.env`

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Существующая внешняя Docker-сеть приложения |
| `CLOUDFLARED_VERSION` | Версия образа `cloudflare/cloudflared` |
| `CLOUDFLARED_PROTOCOL` | Транспорт до Cloudflare, по умолчанию `http2` |

`CONTAINER` и `PORT` передаются в команду. Сеть можно переопределить через `NETWORK=project-network`.
Env-файлы в Git не попадают. Для будущего deploy `.env.prod` предусмотрен корневой `make deploy-cloudflared`.

## Команды Makefile

| Команда | Действие |
|---|---|
| `make help` | Список команд |
| `make env` | Создать `.env` без перезаписи существующего |
| `make init` | Подготовить `.env` и скачать образ, без запуска туннеля |
| `make docker-pull` | Скачать образ |
| `make share CONTAINER=project-container PORT=project-port` | Запустить туннель; остановка через `Ctrl+C` |
| `make config CONTAINER=project-container PORT=project-port` | Проверить Compose-конфиг |

## Ограничения

Ссылка публичная: не публикуй админки и сервисы с секретами без собственной авторизации.
Настройка NPM, свой домен и аккаунт Cloudflare не требуются.
Quick Tunnels предназначены для демонстраций: без гарантии доступности, до 200 одновременных запросов, без SSE.
При ошибке `502` проверь имя контейнера, внутренний порт и общую Docker-сеть.

[Документация Cloudflare Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/).
