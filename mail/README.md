# Mail

Сначала нужно заполнить `.env`. Сейчас от `.env.example` отличаются эти поля, их надо проверить на каждом сервере:

- `COMPOSE_PROJECT_NAME` - имя Docker Compose проекта.
- `SITENAME` - название почты в интерфейсе.
- `DOMAIN` - основной почтовый домен, часть после `@`.
- `HOSTNAMES` - публичные имена почтового сервера через запятую.
- `WEBSITE` - ссылка на веб-интерфейс.
- `TLS_FLAVOR` - режим TLS сертификатов.
- `API_TOKEN` - секретный токен REST API, обязательно заменить.
- `SECRET_KEY` - секрет Flask/Mailu, обязательно заменить.

Реальный `.env` не коммитится. Для шаблона используется `.env.example`.

## Быстрый запуск

```sh
make env
make subnet
make init
```

`make env` создает `.env` из `.env.example`, если файла еще нет.

`make subnet` показывает подсеть Docker-сети `proxy`. Ее значение нужно использовать в `REAL_IP_FROM`, если Mailu стоит за Nginx Proxy Manager в этой сети.

`make init` создает сеть `proxy`, скачивает образы и поднимает контейнеры.

## TLS сертификат

Mailu требует TLS сертификат для имени из `HOSTNAMES`.

Если Mailu работает без Nginx Proxy Manager и сам принимает HTTP/HTTPS, обычно используется:

```env
TLS_FLAVOR=letsencrypt
```

В этом режиме Mailu сам получает сертификат Let's Encrypt. Для этого DNS `A/AAAA` для всех имен из `HOSTNAMES` должен вести на сервер, а порт `80` должен доходить до Mailu.

Если Mailu стоит за Nginx Proxy Manager, как в этом окружении, используется внешний сертификат из NPM:

```env
TLS_FLAVOR=mail
```

В этом режиме веб-интерфейс открывается через NPM, а Mailu берет сертификат из файлов:

```text
certs/cert.pem
certs/key.pem
```

Посмотреть сертификаты в NPM:

```sh
make npm-certs
```

Скопировать нужный сертификат из NPM:

```sh
make npm-cert-copy NPM_CERT=npm-18
```

Скопировать сертификат и сразу перезагрузить TLS в Mailu:

```sh
make npm-cert-install NPM_CERT=npm-18
```

Проверить локальный сертификат:

```sh
make cert-check
```

Если сертификат был заменен вручную, перезагрузить TLS:

```sh
make cert-reload
```

## Управление

Переменные после команды `make` подставляются внутрь Docker-команды.

Пример:

```sh
make mailu-config-export EXPORT_ARGS='--dns domain user'
```

Внутри выполнится:

```sh
docker compose -f docker-compose-mail.yml exec -T admin flask mailu config-export --dns domain user
```

`EXPORT_ARGS` здесь просто добавляется в конец команды `flask mailu config-export`.

Создать домен:

```sh
make mailu-domain-create DOMAIN_NAME=example.ru
```

Создать администратора:

```sh
make mailu-admin-create LOCALPART=postmaster DOMAIN_NAME=example.ru PASSWORD='strong-password'
```

Обновить пароль администратора:

```sh
make mailu-admin-create LOCALPART=postmaster DOMAIN_NAME=example.ru PASSWORD='new-password' MODE=update
```

Создать обычного пользователя:

```sh
make mailu-user-create LOCALPART=user DOMAIN_NAME=example.ru PASSWORD='strong-password'
```

Сменить пароль пользователя:

```sh
make mailu-password LOCALPART=user DOMAIN_NAME=example.ru PASSWORD='new-password'
```

Отключить пользователя:

```sh
make mailu-user-delete EMAIL=user@example.ru
```

Удалить пользователя полностью:

```sh
make mailu-user-delete EMAIL=user@example.ru REALLY=true
```

Создать алиас:

```sh
make mailu-alias-create LOCALPART=info DOMAIN_NAME=example.ru DESTINATION='user@example.ru'
```

Удалить алиас:

```sh
make mailu-alias-delete EMAIL=info@example.ru
```

Экспорт конфигурации:

```sh
make mailu-config-export
```

Экспорт DNS-записей:

```sh
make mailu-dns EXPORT_ARGS='domain.dns_mx domain.dns_spf'
```

Показать домены, пользователей и алиасы:

```sh
make mailu-domains
make mailu-users
make mailu-aliases
```

Импорт конфигурации:

```sh
make mailu-config-import IMPORT_FILE=backup.yml
```

## Roundcube

Здесь используются настройки и скины Roundcube для Mailu.

Сейчас используется скин `Elastic2022`. Он установлен из релизного архива.

Для будущего обновления укажи новую версию:

```sh
make elastic2022-update ELASTIC2022_VERSION=1.7.2
```

Раздельные шаги:

```sh
make elastic2022-download ELASTIC2022_VERSION=1.7.1
make elastic2022-extract ELASTIC2022_VERSION=1.7.1
make elastic2022-write-version ELASTIC2022_VERSION=1.7.1
```

После обновления перезапусти веб-почту:

```sh
docker compose -f docker-compose-mail.yml up -d webmail
```

## Проверка

```sh
make config
make ps
make logs
```

`make config` проверяет compose-синтаксис и итоговую сборку конфига. Он не проверяет DNS, открытые порты, сертификаты, доставку писем и вход в веб-интерфейс.
