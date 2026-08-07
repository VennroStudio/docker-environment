# VPN

IPsec VPN-сервер в Docker-контейнере на образе `hwdsl2/ipsec-vpn-server`.

## Быстрый старт

```bash
make init
```

Команда:
- создаст `.env` из `.env.example` (если его ещё нет),
- создаст внешнюю сеть (если её ещё нет),
- скачает образ и поднимет контейнер.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная       | Описание                                                        |
|------------------|-----------------------------------------------------------------|
| `PROJECT_NAME`   | Название проекта Docker Compose                                |
| `NETWORK`        | Имя внешней Docker-сети, к которой подключается контейнер      |
| `VPN_IPSEC_PSK`  | Pre-shared key для IPsec                                       |
| `VPN_USER`       | Логин VPN-пользователя                                         |
| `VPN_PASSWORD`   | Пароль VPN-пользователя                                        |

## Порты

VPN использует UDP-порты:

| Порт | Протокол | Назначение |
|---|---|---|
| `500` | UDP | IKE/IPsec |
| `4500` | UDP | IPsec NAT-T |

Эти порты должны быть открыты на сервере и у хостинг-провайдера. Через Nginx Proxy Manager их проксировать не нужно: это не HTTP/WebSocket-трафик.

## Данные

Данные контейнера хранятся в `./data`, который монтируется в `/etc/ipsec.d`.

## Подключение на устройствах

Инструкции для подключения на устройствах: [Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#ios).

Конфигурация клиента доступна внутри Docker-контейнера:

| Файл в контейнере | Для чего |
|---|---|
| `/etc/ipsec.d/vpnclient.p12` | Windows и Linux |
| `/etc/ipsec.d/vpnclient.sswan` | Android |
| `/etc/ipsec.d/vpnclient.mobileconfig` | iOS и macOS |

Скопировать конфиги из контейнера на хост:

```bash
make client-ios
make client-android
make client-windows-linux
```

Скопировать все сразу:

```bash
make client-configs
```

По умолчанию файлы копируются в текущую папку модуля `vpn`. Чтобы скопировать в отдельную папку:

```bash
make client-configs CLIENT_CONFIG_DIR=./client-configs
```

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
| `make client-ios` | Скопировать `vpnclient.mobileconfig` для iOS и macOS |
| `make client-android` | Скопировать `vpnclient.sswan` для Android |
| `make client-windows-linux` | Скопировать `vpnclient.p12` для Windows и Linux |
| `make client-configs` | Скопировать все клиентские конфиги |
| `make config` | Показать итоговый Docker Compose config |
