# Roundcube Templates

Здесь лежат настройки и скины Roundcube для Mailu.

## Workbench

Скин установлен из релизного архива:

```sh
./scripts/update-roundcube-workbench.sh v1.2.1
```

Для будущего обновления укажи новую версию:

```sh
make workbench-update WORKBENCH_VERSION=v1.2.2
```

После обновления перезапусти веб-почту:

```sh
docker compose -f docker-compose-mail.yml up -d webmail
```
