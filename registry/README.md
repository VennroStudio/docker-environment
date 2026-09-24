# Registry

Docker Registry и Container Hub для управления образами через веб-интерфейс.

## Быстрый старт

```bash
make env
```

Отредактируйте `.env` — обязательно задайте `REGISTRY_PASSWORD`. Получите значение для авторизации Container Hub:

```bash
make ui-auth
```

Укажите результат в `REGISTRY_UI_AUTH` в `.env`. Это Base64 от логина и пароля Registry, а не шифрование; значение нельзя публиковать. Затем:

```bash
make init
```

Команда:
- создаст внешнюю Docker-сеть (если её ещё нет),
- создаст `auth/htpasswd` из `REGISTRY_USER` и `REGISTRY_PASSWORD`, если файла ещё нет,
- скачает образы и поднимет контейнеры.

## Настройка `.env`

Перед первым запуском отредактируй `.env`:

| Переменная                         | Описание                                                          |
|-------------------------------------|---------------------------------------------------------------------|
| `PROJECT_NAME`                     | Название проекта Docker Compose                                   |
| `NETWORK`                          | Имя внешней Docker-сети, к которой подключаются контейнеры        |
| `VOLUME`                           | Путь к папке для хранения образов, например `./project-volume`    |
| `REGISTRY_PORT`                    | Локальный порт хоста для Docker Registry API                      |
| `REGISTRY_USER`                    | Логин для доступа к Registry                                      |
| `REGISTRY_PASSWORD`                | Пароль для доступа к Registry                                     |
| `REGISTRY_AUTH_REALM`              | Realm для HTTP Basic Auth                                         |
| `REGISTRY_STORAGE_DELETE_ENABLED`  | `true`/`false` — разрешить удаление образов через API              |
| `REGISTRY_UI_PORT` | Порт панели на `127.0.0.1`, по умолчанию `19017` |
| `REGISTRY_UI_VOLUME` | Имя Docker volume для SQLite-базы панели |
| `REGISTRY_UI_AUTH` | Base64 от действующих логина и пароля Registry; получить через `make ui-auth` |

`auth/htpasswd` генерируется локально командой `make create-user` и монтируется в контейнер как `/auth/htpasswd`.

## Команды Makefile

Полный список — `make help`.

| Команда | Действие |
|---|---|
| `make init` | Первичная инициализация: `.env` + сеть + pull + up |
| `make up` | Поднять контейнеры |
| `make down` | Остановить и удалить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make logs` | Логи контейнеров (последние 100 строк, live) |
| `make create-user` | Создать основного пользователя из `.env`, если `auth/htpasswd` ещё нет |
| `make add-user` | Добавить пользователя в `auth/htpasswd` |
| `make change-password` | Изменить пароль пользователя |
| `make list-users` | Показать пользователей из `auth/htpasswd` |
| `make remove-user` | Удалить пользователя |
| `make ui-auth` | Получить значение `REGISTRY_UI_AUTH` из текущих переменных окружения |
| `make list-images` | Показать репозитории в Registry |
| `make list-tags` | Показать теги выбранного образа |

Для `list-images` и `list-tags` по умолчанию используются `REGISTRY_USER` и `REGISTRY_PASSWORD` из `.env`.
Можно передать другого пользователя точечно:

```bash
make list-images USER=readonly PASS='password'
make list-tags USER=readonly PASS='password'
```

## Container Hub

Панель подключается к `http://registry:5000` внутри Docker-сети. Для локального запуска откройте `http://localhost:19017`.

Для доступа к панели на сервере включите в корневом `.env` на компьютере:

```dotenv
T_REGISTRY_WEB=20017:127.0.0.1:19017
```

Из корня проекта запустите `make tunnel` и откройте `http://localhost:20017`.
Туннель `T_REGISTRY` для работы панели не требуется: он нужен только для прямого доступа к Registry API с компьютера.

Панель не имеет отдельной формы входа при отключённом OIDC. Доступ к ней даёт возможность управлять образами с настроенными учётными данными. Порт опубликован только на loopback; не добавляйте публичный прокси или проброс на роутере. Контейнеры общей Docker-сети также могут обращаться к панели.

В локальном `registry/.env.prod` задайте те же UI-переменные и `REGISTRY_UI_AUTH` от учётных данных серверного Registry. Env-файлы не попадают в Git. Существующий `make deploy-registry` отправляет `.env.prod` на сервер; выполнять его нужно отдельно, когда требуется развёртывание.

Если пароль пользователя меняется через `make change-password`, обновите также `REGISTRY_PASSWORD` в соответствующем env-файле, повторно получите `REGISTRY_UI_AUTH` и пересоздайте панель:

```bash
docker compose -f docker-compose-registry.yml up -d --no-deps a-registry
```

`make ui-auth` использует локальный `.env`; для учётных данных из `.env.prod`:

```bash
make -f Makefile -f .env.prod ui-auth
```

Панель использует тег `latest`. Для загрузки актуального образа и обновления контейнера выполните:

```bash
docker compose -f docker-compose-registry.yml pull a-registry
docker compose -f docker-compose-registry.yml up -d --no-deps a-registry
```

Volume панели хранит её SQLite-базу отдельно от образов Registry. Удаление образа через UI само по себе не освобождает всё место на диске: для неиспользуемых слоёв нужна отдельная garbage collection Registry.
