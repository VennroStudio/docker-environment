# Roundcube Templates

Здесь лежат настройки и скины Roundcube для Mailu.

## Elastic2022

Скин установлен из релизного архива:

```sh
make elastic2022-download ELASTIC2022_VERSION=1.7.1
make elastic2022-extract ELASTIC2022_VERSION=1.7.1
make elastic2022-write-version ELASTIC2022_VERSION=1.7.1
```

Для будущего обновления укажи новую версию:

```sh
make elastic2022-update ELASTIC2022_VERSION=1.7.2
```

После обновления перезапусти веб-почту:

```sh
docker compose -f docker-compose-mail.yml up -d webmail
```
