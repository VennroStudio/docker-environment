# Xray VLESS + REALITY

Минимальный модуль без панели. Он поднимает один inbound `VLESS + TCP + REALITY + Vision`.

## Нужен ли домен

Для REALITY домен сервера не обязателен как TLS-сертификат: Xray не выпускает сертификат на твой домен. Но клиенту всё равно нужен адрес сервера:

| Переменная | Что писать |
|---|---|
| `XRAY_HOST` | IP или домен твоего сервера |
| `XRAY_REALITY_SERVER_NAME` | SNI маскировочного сайта, например `www.microsoft.com` |
| `XRAY_REALITY_DEST` | Тот же сайт с портом, например `www.microsoft.com:443` |

Если есть свой домен, можешь поставить его в `XRAY_HOST`, но `XRAY_REALITY_SERVER_NAME` должен совпадать с маскировочным сайтом из `XRAY_REALITY_DEST`, а не обязательно с твоим доменом.

## Быстрый старт

Создать `.env` с UUID, REALITY-ключами и shortId:

```bash
make gen-env
```

Заполни:

```dotenv
XRAY_HOST=<server-ip-or-domain>
XRAY_PORT=9443
```

Запуск:

```bash
make init
```

Получить ссылку:

```bash
make link
```

## Порты

Открыть на сервере и у провайдера:

| Порт | Протокол | Назначение |
|---|---|---|
| `XRAY_PORT` | TCP | VLESS + REALITY |

Лучший порт для маскировки обычно `443/tcp`, но если на сервере уже живёт NPM, оставь `9443/tcp` или другой свободный порт.

## Клиенты

Импортируй ссылку из `make link` в клиент, который поддерживает VLESS + REALITY + Vision. Для Karing/Hiddify/v2rayN/v2rayNG это обычно импорт из буфера или QR-код из ссылки.

## Команды

| Команда | Действие |
|---|---|
| `make gen-env` | Создать `.env` с UUID, REALITY-ключами и shortId |
| `make keys` | Напечатать новую пару REALITY ключей |
| `make uuid` | Напечатать UUID |
| `make render` | Собрать `config.json` из `.env` |
| `make test-config` | Проверить `config.json` через Xray |
| `make init` | Сгенерировать конфиг и поднять контейнер |
| `make link` | Показать `vless://` ссылку |
| `make logs` | Логи |
| `make ps` | Статус |
| `make down` | Остановить и удалить контейнер |

## Источники

- [Xray transport security and REALITY](https://xtls.github.io/en/config/transport.html)
- [XTLS Xray-core official package](https://github.com/orgs/XTLS/packages/container/package/xray-core)
- [XTLS VLESS TCP XTLS Vision REALITY example](https://github.com/XTLS/Xray-examples/tree/main/VLESS-TCP-XTLS-Vision-REALITY)
