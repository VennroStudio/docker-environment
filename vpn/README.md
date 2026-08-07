# VPN

Модуль с двумя VPN-вариантами:

- IPsec/IKEv2 на образе `hwdsl2/ipsec-vpn-server`;
- OpenVPN Access Server на образе `openvpn/openvpn-as`.

## Быстрый старт

IPsec/IKEv2 запускается по умолчанию:

```bash
make init
```

OpenVPN запускается отдельной командой:

```bash
make o-vpn
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
| `OPENVPN_ADMIN_PORT` | Локальный порт хоста для web/admin UI OpenVPN              |
| `OPENVPN_HOST` | Публичный IP или DNS-имя сервера для профилей, QR и ссылок OpenVPN |
| `OPENVPN_TCP_PORT` | Публичный TCP-порт OpenVPN                                   |
| `OPENVPN_UDP_PORT` | Публичный UDP-порт OpenVPN                                   |
| `OPENVPN_VOLUME` | Папка с данными OpenVPN Access Server                         |

## IPsec/IKEv2

IPsec/IKEv2 использует UDP-порты:

| Порт | Протокол | Назначение |
|---|---|---|
| `500` | UDP | IKE/IPsec |
| `4500` | UDP | IPsec NAT-T |

Эти порты должны быть открыты на сервере и у хостинг-провайдера. Через Nginx Proxy Manager их проксировать не нужно: это не HTTP/WebSocket-трафик.

## OpenVPN

OpenVPN Access Server использует:

| Порт | Протокол | Назначение |
|---|---|---|
| `OPENVPN_ADMIN_PORT -> 943` | TCP | Web UI и admin UI |
| `OPENVPN_TCP_PORT -> OPENVPN_TCP_PORT` | TCP | OpenVPN TCP |
| `OPENVPN_UDP_PORT -> OPENVPN_UDP_PORT` | UDP | OpenVPN UDP |

Admin UI доступна на сервере:

```text
https://127.0.0.1:${OPENVPN_ADMIN_PORT}/admin
```

Пароль пользователю `openvpn` можно задать так:

```bash
make o-vpn-password PASSWORD='new-password'
```

Чтобы профили, QR и ссылки сразу генерировались с нужным адресом и портом, укажи в `.env`:

```env
OPENVPN_HOST=vpn.example.com
OPENVPN_TCP_PORT=9443
OPENVPN_UDP_PORT=1194
```

`OPENVPN_HOST` обязателен. Это должен быть публичный IP сервера или DNS-имя, которое указывает на сервер. Не ставь сюда `127.0.0.1` или локальный hosts-домен.

Если хочешь подключаться по домену, создай в DNS A-запись:

```text
vpn.example.com -> <PUBLIC_SERVER_IP>
```

После этого в `.env` на сервере укажи:

```env
OPENVPN_HOST=vpn.example.com
```

После изменения этих значений применить настройки можно так:

```bash
make o-vpn-apply-config
```

После применения скачай профиль или открой QR заново: старые уже скачанные профили сами не поменяются.

Если нужен OpenVPN именно через TCP `443`, выставь:

```env
OPENVPN_TCP_PORT=443
```

Но на этой же машине порт `443` не должен быть занят Nginx Proxy Manager или другим контейнером. Через Nginx Proxy Manager OpenVPN-трафик проксировать не надо: это не обычный HTTP-сайт.

## Данные

Данные IPsec хранятся в `./data`, который монтируется в `/etc/ipsec.d`.

Данные OpenVPN хранятся в `OPENVPN_VOLUME`, по умолчанию `./openvpn-data`.

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
| `make init` | Первичная инициализация IPsec: `.env` + сеть + pull + up |
| `make up` | Поднять IPsec |
| `make down` | Остановить и удалить IPsec |
| `make restart` | Перезапустить IPsec |
| `make logs` | Логи IPsec (последние 100 строк, live) |
| `make ps` | Показать статус IPsec |
| `make ipsec-config` | Показать итоговый IPsec Docker Compose config |
| `make o-vpn` | Первичная инициализация OpenVPN Access Server |
| `make o-vpn-up` | Поднять OpenVPN Access Server |
| `make o-vpn-down` | Остановить и удалить OpenVPN Access Server |
| `make o-vpn-restart` | Перезапустить OpenVPN Access Server |
| `make o-vpn-logs` | Логи OpenVPN Access Server |
| `make o-vpn-ps` | Показать статус OpenVPN Access Server |
| `make o-vpn-apply-config` | Применить `OPENVPN_HOST`, `OPENVPN_TCP_PORT`, `OPENVPN_UDP_PORT` в OpenVPN AS |
| `make o-vpn-password PASSWORD='new-password'` | Задать пароль пользователю `openvpn` |
| `make o-vpn-config` | Показать итоговый OpenVPN Docker Compose config |
| `make client-ios` | Скопировать `vpnclient.mobileconfig` для iOS и macOS |
| `make client-android` | Скопировать `vpnclient.sswan` для Android |
| `make client-windows-linux` | Скопировать `vpnclient.p12` для Windows и Linux |
| `make client-configs` | Скопировать все клиентские конфиги |
| `make config` | Показать итоговый IPsec Docker Compose config |
