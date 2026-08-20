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

Главный сценарий: создать почтовый ящик.

Сначала создай домен:

```sh
make mailu-domain-create DOMAIN_NAME=example.ru
```

Потом создай пользователя:

```sh
make mailu-user-create EMAIL=user@example.ru PASSWORD='strong-password'
```

`EMAIL` всегда указывается целиком: `имя@домен`.

Создать администратора:

```sh
make mailu-admin-create EMAIL=postmaster@example.ru PASSWORD='strong-password'
```

Обновить пароль администратора:

```sh
make mailu-admin-create EMAIL=postmaster@example.ru PASSWORD='new-password' MODE=update
```

Сменить пароль пользователя:

```sh
make mailu-password EMAIL=user@example.ru PASSWORD='new-password'
```

Отключить пользователя:

```sh
make mailu-user-delete EMAIL=user@example.ru
```

Удалить пользователя полностью:

```sh
make mailu-user-delete EMAIL=user@example.ru DELETE_FLAGS='--really'
```

Создать алиас:

```sh
make mailu-alias-create EMAIL=info@example.ru DESTINATION='user@example.ru'
```

Создать wildcard-алиас:

```sh
make mailu-alias-create EMAIL=anything@example.ru DESTINATION='user@example.ru' ALIAS_FLAGS='--wildcard'
```

Удалить алиас:

```sh
make mailu-alias-delete EMAIL=info@example.ru
```

Показать домены, пользователей и алиасы:

```sh
make mailu-domains
make mailu-users
make mailu-aliases
```

Показать DNS-записи:

```sh
make mailu-dns
```

Для редких команд есть универсальный вход в Mailu CLI:

```sh
make mailu CMD='config-export user'
```

Реально это выполнит:

```sh
docker compose -f docker-compose-mail.yml exec -T admin flask mailu config-export user
```

Еще примеры:

```sh
make mailu CMD='config-export'
make mailu CMD='config-export --dns domain.dns_mx domain.dns_spf'
make mailu CMD='setlimits example.ru -1 -1 0'
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
