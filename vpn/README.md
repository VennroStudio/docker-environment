# VPN

Модуль оставлен только для IPsec/IKEv2 на образе `hwdsl2/ipsec-vpn-server`.

## Быстрый старт

Перед первым запуском отредактируй `.env`:

```bash
make env
```

Запуск:

```bash
make init
```

Команда создаёт `.env`, создаёт внешнюю Docker-сеть, скачивает образ и поднимает контейнер.

## Настройка `.env`

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Имя внешней Docker-сети |
| `VPN_IPSEC_PSK` | Pre-shared key для IPsec |
| `VPN_USER` | Логин IPsec-пользователя |
| `VPN_PASSWORD` | Пароль IPsec-пользователя |

## Порты

IPsec/IKEv2 использует UDP-порты:

| Порт | Протокол | Назначение |
|---|---|---|
| `500` | UDP | IKE/IPsec |
| `4500` | UDP | IPsec NAT-T |

Эти порты должны быть открыты на сервере и у хостинг-провайдера. Через Nginx Proxy Manager их проксировать не нужно: это не HTTP/WebSocket-трафик.

## Клиентские конфиги

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

## Команды

Полный список:

```bash
make help
```

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация IPsec |
| `make up` | Поднять IPsec |
| `make down` | Остановить и удалить IPsec |
| `make restart` | Перезапустить IPsec |
| `make logs` | Логи IPsec |
| `make ps` | Показать статус IPsec |
| `make config` | Показать итоговый Docker Compose config |
| `make client-ios` | Скопировать `vpnclient.mobileconfig` |
| `make client-android` | Скопировать `vpnclient.sswan` |
| `make client-windows-linux` | Скопировать `vpnclient.p12` |
| `make client-configs` | Скопировать все клиентские конфиги |
