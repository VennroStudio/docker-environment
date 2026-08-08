# Hysteria 2

Hysteria 2 работает поверх QUIC, поэтому нужен открытый UDP-порт. Nginx Proxy Manager HTTP/WebSocket-прокси здесь не участвует.

## Нужен ли домен

Домен не строго обязателен, но для нормальной прод-настройки лучше использовать домен и доверенный TLS-сертификат.

Варианты:

| Вариант | Что нужно | Когда использовать |
|---|---|---|
| Домен + доверенный cert | DNS A/AAAA на сервер и TLS-сертификат | Рекомендуемый вариант |
| Без домена | Self-signed cert, `insecure=1`, `pinSHA256` | Если хочешь подключаться по IP |

Hysteria требует TLS. Если сертификат self-signed, клиенту нужно либо доверять CA, либо использовать `insecure=1` вместе с `pinSHA256`.

## Быстрый старт с доменом и готовым cert

```bash
make gen-env
```

Заполни `.env`:

```dotenv
HYSTERIA_HOST=vpn.example.com
HYSTERIA_SNI=vpn.example.com
HYSTERIA_TLS_MODE=cert
HYSTERIA_CERTS_HOST_PATH=./certs
HYSTERIA_CERT_PATH=/etc/hysteria/certs/fullchain.pem
HYSTERIA_KEY_PATH=/etc/hysteria/certs/privkey.pem
HYSTERIA_CLIENT_INSECURE=0
HYSTERIA_CLIENT_PIN_SHA256=
```

Положи сертификаты:

```bash
mkdir -p certs
cp /path/to/fullchain.pem certs/fullchain.pem
cp /path/to/privkey.pem certs/privkey.pem
```

Запуск:

```bash
make init
make link
```

## Быстрый старт с доменом и ACME

Этот режим выпускает сертификат через Hysteria. Для HTTP-челленджа нужен доступный TCP `80` или проброс/реверс-прокси на `HYSTERIA_ACME_HTTP_PORT`.

```dotenv
HYSTERIA_HOST=vpn.example.com
HYSTERIA_SNI=vpn.example.com
HYSTERIA_TLS_MODE=acme
HYSTERIA_ACME_EMAIL=admin@example.com
HYSTERIA_ACME_TYPE=http
HYSTERIA_ACME_HTTP_PORT=80
HYSTERIA_CLIENT_INSECURE=0
HYSTERIA_CLIENT_PIN_SHA256=
```

Запуск с дополнительным TCP-портом для ACME:

```bash
make init-acme
make link
```

Если TCP `80` уже занят NPM, проще использовать готовый сертификат из NPM/Let's Encrypt через `HYSTERIA_TLS_MODE=cert` или настраивать ACME DNS challenge отдельно.

## Быстрый старт без домена

```bash
make gen-env
```

В `.env`:

```dotenv
HYSTERIA_HOST=<server-ip>
HYSTERIA_SNI=bing.com
HYSTERIA_TLS_MODE=cert
HYSTERIA_CLIENT_INSECURE=1
```

Создай сертификат и pin:

```bash
make cert-selfsigned
make fingerprint
```

Значение из `make fingerprint` вставь в:

```dotenv
HYSTERIA_CLIENT_PIN_SHA256=<hex-from-fingerprint>
```

Потом:

```bash
make init
make link
```

## Порты

Открыть на сервере и у провайдера:

| Порт | Протокол | Назначение |
|---|---|---|
| `HYSTERIA_PORT` | UDP | Hysteria 2 / QUIC |
| `HYSTERIA_ACME_HTTP_PORT` | TCP | Только для `make init-acme` и ACME HTTP |

Если `HYSTERIA_PORT=443`, это не конфликтует с NPM на `443/tcp`, потому что Hysteria слушает `443/udp`.

## Команды

| Команда | Действие |
|---|---|
| `make gen-env` | Создать `.env` с новыми паролями |
| `make cert-selfsigned` | Создать self-signed cert |
| `make fingerprint` | Показать `pinSHA256` для cert |
| `make render` | Собрать `config.yaml` из `.env` |
| `make init` | Сгенерировать конфиг и поднять контейнер |
| `make init-acme` | Поднять контейнер с TCP-портом для ACME HTTP |
| `make link` | Показать `hysteria2://` ссылку |
| `make logs` | Логи |
| `make ps` | Статус |
| `make down` | Остановить и удалить контейнер |

## Источники

- [Hysteria 2 Full Server Config](https://v2.hysteria.network/docs/advanced/Full-Server-Config/)
- [Hysteria 2 Client TLS](https://v2.hysteria.network/docs/getting-started/Client/)
- [Hysteria 2 URI Scheme](https://v2.hysteria.network/docs/developers/URI-Scheme/)
