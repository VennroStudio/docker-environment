# VPN

Модуль с двумя вариантами:

- IPsec/IKEv2 на образе `hwdsl2/ipsec-vpn-server`;
- Xray через панель `3x-ui` для VLESS + REALITY.

## Быстрый старт

IPsec/IKEv2 запускается по умолчанию:

```bash
make init
```

Xray/3x-ui запускается отдельной командой:

```bash
make xray
```

Команда:
- создаст `.env` из `.env.example` (если его ещё нет),
- создаст внешнюю сеть (если её ещё нет),
- скачает образ и поднимет контейнер.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Название проекта Docker Compose |
| `NETWORK` | Имя внешней Docker-сети, к которой подключаются контейнеры |
| `VPN_IPSEC_PSK` | Pre-shared key для IPsec |
| `VPN_USER` | Логин IPsec-пользователя |
| `VPN_PASSWORD` | Пароль IPsec-пользователя |
| `XUI_PANEL_PORT` | Локальный порт хоста для панели 3x-ui |
| `XUI_INTERNAL_PORT` | Внутренний порт панели 3x-ui в контейнере |
| `XUI_WEB_BASE_PATH` | Начальный путь панели 3x-ui |
| `XUI_ENABLE_FAIL2BAN` | Включить Fail2ban/IP-limit в 3x-ui |
| `XUI_DATA_VOLUME` | Папка с SQLite-базой 3x-ui |
| `XUI_CERT_VOLUME` | Папка сертификатов 3x-ui |
| `XUI_ACME_VOLUME` | Папка состояния acme.sh |
| `XRAY_REALITY_PORT` | Публичный TCP-порт VLESS + REALITY inbound |

## IPsec/IKEv2

IPsec/IKEv2 использует UDP-порты:

| Порт | Протокол | Назначение |
|---|---|---|
| `500` | UDP | IKE/IPsec |
| `4500` | UDP | IPsec NAT-T |

Эти порты должны быть открыты на сервере и у хостинг-провайдера. Через Nginx Proxy Manager их проксировать не нужно: это не HTTP/WebSocket-трафик.

## Xray / 3x-ui

3x-ui использует:

| Порт | Протокол | Назначение |
|---|---|---|
| `127.0.0.1:XUI_PANEL_PORT -> XUI_INTERNAL_PORT` | TCP | Web-панель 3x-ui |
| `XRAY_REALITY_PORT -> XRAY_REALITY_PORT` | TCP | VLESS + REALITY inbound |

Панель не публикуется наружу. Открывать её нужно через SSH-туннель:

```bash
ssh -N -L 19019:127.0.0.1:19019 root@<SERVER>
```

После этого локально:

```text
http://127.0.0.1:19019/
```

3x-ui при первом запуске генерирует случайный логин и пароль. Путь панели берётся из `XUI_WEB_BASE_PATH`, у нас по умолчанию `/`. Посмотреть текущие настройки:

```bash
make xray-settings
```

Задать свой логин и пароль:

```bash
make xray-password USERNAME='admin' PASSWORD='new-password'
```

Команда также сбрасывает 2FA, если она была включена.

## VLESS + REALITY

В 3x-ui создай inbound:

| Поле | Значение |
|---|---|
| Protocol | `VLESS` |
| Port | значение `XRAY_REALITY_PORT` |
| Network | `TCP` / `Raw` |
| Security | `REALITY` |
| Flow | `xtls-rprx-vision` |
| Fingerprint | `chrome` |
| Dest | реальный внешний TLS-сайт, например `www.microsoft.com:443` |
| SNI / Server Name | тот же домен, например `www.microsoft.com` |

Для каждого человека создавай отдельного клиента в этом inbound. Так можно отдельно отключать доступ, смотреть трафик и выдавать отдельную ссылку/QR.

Перед отправкой ссылки проверь, что в ней указан публичный домен или IP сервера, а не `127.0.0.1`. Если панель подставила локальный адрес из SSH-туннеля, замени host в ссылке на публичный домен/IP сервера.

VLESS + REALITY — это proxy. Чтобы на устройстве это работало как VPN для всего трафика, в клиенте вроде Karing нужно включить TUN/global mode.

Если порт `443` свободен, для маскировки обычно лучше использовать:

```env
XRAY_REALITY_PORT=443
```

Если `443` уже занят Nginx Proxy Manager или другим контейнером, оставь отдельный порт, например:

```env
XRAY_REALITY_PORT=9443
```

Через Nginx Proxy Manager VLESS + REALITY проксировать не нужно: Xray должен принимать сырой TCP-трафик напрямую.

## Данные

Данные IPsec хранятся в `./data`, который монтируется в `/etc/ipsec.d`.

Данные 3x-ui хранятся в:

| Папка | Для чего |
|---|---|
| `XUI_DATA_VOLUME` | SQLite-база и настройки панели |
| `XUI_CERT_VOLUME` | Сертификаты панели |
| `XUI_ACME_VOLUME` | Состояние acme.sh |

Для полной чистой переустановки Xray/3x-ui:

```bash
make xray-clean
make xray
```

Это удалит пользователей, inbounds, ссылки, сертификаты и старые настройки 3x-ui.

## Подключение IPsec на устройствах

Инструкции для подключения на устройствах: [Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#ios).

Конфигурация IPsec-клиента доступна внутри Docker-контейнера:

| Файл в контейнере | Для чего |
|---|---|
| `/etc/ipsec.d/vpnclient.p12` | Windows и Linux |
| `/etc/ipsec.d/vpnclient.sswan` | Android |
| `/etc/ipsec.d/vpnclient.mobileconfig` | iOS и macOS |

Скопировать IPsec-конфиги из контейнера на хост:

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
| `make init` | Первичная инициализация IPsec: `.env` + сеть + pull + up |
| `make up` | Поднять IPsec |
| `make down` | Остановить и удалить IPsec |
| `make restart` | Перезапустить IPsec |
| `make logs` | Логи IPsec |
| `make ps` | Показать статус IPsec |
| `make ipsec-config` | Показать итоговый IPsec Docker Compose config |
| `make xray` | Первичная инициализация Xray/3x-ui |
| `make xray-up` | Поднять Xray/3x-ui |
| `make xray-down` | Остановить и удалить Xray/3x-ui контейнер |
| `make xray-restart` | Перезапустить Xray/3x-ui |
| `make xray-logs` | Логи Xray/3x-ui |
| `make xray-ps` | Показать статус Xray/3x-ui |
| `make xray-settings` | Показать настройки панели 3x-ui |
| `make xray-password USERNAME='admin' PASSWORD='new-password'` | Задать логин и пароль панели 3x-ui |
| `make xray-config` | Показать итоговый Xray/3x-ui Docker Compose config |
| `make xray-clean` | Остановить Xray/3x-ui и удалить локальные данные |
| `make client-ios` | Скопировать `vpnclient.mobileconfig` для iOS и macOS |
| `make client-android` | Скопировать `vpnclient.sswan` для Android |
| `make client-windows-linux` | Скопировать `vpnclient.p12` для Windows и Linux |
| `make client-configs` | Скопировать все IPsec-клиентские конфиги |
| `make config` | Показать итоговый IPsec Docker Compose config |
