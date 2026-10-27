# Email

Stalwart для почты, ClamAV для проверки писем и Bulwark для веб-почты. Каждый сервис работает в отдельном контейнере.

В примерах замени `example.com`, `PUBLIC_IP` и `SSH_HOST` на свой домен, IP сервера и SSH-профиль. Настройки Nginx Proxy Manager (NPM) меняй только через его панель. После запуска выполни этапы 1–8 ниже.

## Быстрый старт

На сервере, из папки `email`:

```bash
make env
```

В `.env` укажи свой `MAIL_HOSTNAME`, `WEBMAIL_JMAP_URL=https://mail.example.com`, общий с NPM `PROJECT_NAME` и `NETWORK`. Проверь:

```bash
make config
```

**При переходе с Mailu:** сохрани его данные, отдельно перенеси нужную почту и останови старые контейнеры, освободив `25/465/993/4190`. Volumes не удаляй. Затем:

```bash
make init
```

`make init` скачает образы, создаст сеть/volumes и запустит контейнеры. Это не переносит данные Mailu и не завершает настройку: выполни этапы 1–8. Из корня проекта: `make email`; отправка `.env.prod` на сервер: `make deploy-email`.

## Настройка `.env`

| Переменная | Описание |
|---|---|
| `PROJECT_NAME` | Общая группа контейнеров, `docker-environment` |
| `NETWORK` | Внешняя сеть NPM, `proxy` |
| `STALWART_CONFIG_VOLUME` | Имя volume конфигурации Stalwart |
| `STALWART_DATA_VOLUME` | Имя volume почты Stalwart |
| `CLAMAV_VOLUME` | Имя volume антивирусных баз |
| `MAIL_HOSTNAME` | Почтовое имя сервера, например `mail.example.com` |
| `STALWART_VERSION` | Версия образа Stalwart, сейчас `v1.0.0` |
| `ADMIN_PORT` | HTTP-порт первоначальной настройки и постоянной админки через SSH на `127.0.0.1`, по умолчанию `19019` |
| `HTTPS_PORT` | Отдельный HTTPS-порт Stalwart на `127.0.0.1`, по умолчанию `19018`; для описанного входа через SSH не нужен |
| `BULWARK_VERSION` | Версия веб-почты, `1.18.0`, совместимая со Stalwart 1.0 |
| `BULWARK_DATA_VOLUME` | Имя volume настроек и состояния Bulwark |
| `WEBMAIL_JMAP_URL` | Публичный URL Stalwart JMAP, например `https://mail.example.com`, без `/jmap` |
| `WEBMAIL_PORT` | Локальный порт Bulwark, по умолчанию `19020` |

Часовой пояс `Asia/Krasnoyarsk` задан в Compose. `.env` не хранится в Git. Если файл уже существует, добавь в него новые переменные из `.env.example`.

Для старого `.env`: переименуй прежний `ADMIN_PORT=19018` в `HTTPS_PORT=19018`, а `SETUP_PORT=19019` в `ADMIN_PORT=19019`. При своих портах сохрани прежние значения.

## Порты

| Порт хоста | Назначение |
|---|---|
| `25` | SMTP, приём писем от других серверов |
| `465` | SMTP TLS, отправка писем из приложений и клиентов |
| `993` | IMAP TLS, чтение почты |
| `4190` | ManageSieve, управление пользовательскими фильтрами |
| `127.0.0.1:${HTTPS_PORT}` → `443` | HTTPS Stalwart через локальный порт |
| `127.0.0.1:${ADMIN_PORT}` → `8080` | Первоначальная настройка и админка через SSH |
| `127.0.0.1:${WEBMAIL_PORT}` → `3000` | Прямой доступ к Bulwark через SSH |

ClamAV доступен только в сети `email`; фильтрацию нужно подключить отдельно (раздел «Антивирус»). Stalwart и Bulwark подключены к внешней сети `NETWORK` для NPM.

## Данные

Хранятся в именованных Docker volumes:

| Volume | Данные |
|---|---|
| `${STALWART_CONFIG_VOLUME}` | Конфигурация Stalwart, `/etc/stalwart` |
| `${STALWART_DATA_VOLUME}` | Данные Stalwart, `/var/lib/stalwart` |
| `${CLAMAV_VOLUME}` | Антивирусные базы, `/var/lib/clamav` |
| `${BULWARK_DATA_VOLUME}` | Настройки Bulwark и постоянный секрет сессий, `/app/data` |

Сохраняй имена volumes при обновлениях; папки вручную создавать не нужно. `make down` сохраняет данные. Не используй `down -v` (удаление данных) и `--remove-orphans` (общий проект с соседними модулями).

## 1. DNS и сеть

На роутере/сервере открой порты `25`, `465`, `993`, при необходимости `4190`; для NPM — `80` и `443`. Административные порты наружу не открывай.

В DNS-зоне `example.com`:

| Тип | Имя | Значение |
|---|---|---|
| A | `mail` | `PUBLIC_IP` |
| MX | `@` | `mail.example.com.`, приоритет `10` |
| TXT | `@` | `v=spf1 mx a:mail.example.com ~all` |
| CNAME | `autoconfig` | `mail.example.com.` |
| CNAME | `autodiscover` | `mail.example.com.` |

SPF-пример подходит, если отправляет только этот сервер. Не создавай вторую SPF-запись: объедини разрешённые источники в одной. Не публикуй AAAA без рабочего IPv6. У владельца IP настрой PTR на `mail.example.com`; A-запись должна указывать обратно на этот IP.

## 2. Первоначальная настройка

На своём компьютере получи временные учётные данные:

```bash
ssh SSH_HOST 'docker logs stalwart-container 2>&1 | grep -A8 "temporary administrator account"'
```

Для первого входа: `admin` и пароль из строки `password:`. Не публикуй пароль. Открой туннель:

```bash
ssh -N -L 127.0.0.1:20019:127.0.0.1:19019 SSH_HOST
```

Открой `http://127.0.0.1:20019` и пройди мастер настройки. Если меняешь `ADMIN_PORT`, замени серверный порт `19019` в команде.

| Поле мастера | Значение |
|---|---|
| Server Hostname | `mail.example.com` |
| Default Email Domain | `example.com` |
| Automatically Obtain TLS Certificate | Выключить на время мастера; настроить в этапе 7 |
| Generate Email Signing Keys | Включить |
| Main Data Storage | RocksDB, `/var/lib/stalwart/` |
| Write buffer size | `128 MB` |
| Block cache size | Для небольшого сервера можно задать `256 MB`, не `256 B` |
| Attachment / Full-Text Search | `Use data store` |
| Cache & Temporary Data | `Local in-process store` |
| Account Directory | `Use the internal directory` |
| Logging | Консоль, уровень `Info`, tracer включён; файловые логи требуют постоянного volume |
| DNS Management | `Manual DNS server management` |

Заверши мастер и сохрани выданные данные постоянного администратора (например, `admin@example.com`). **На сервере** перезапусти только Stalwart и проверь логи:

```bash
docker restart stalwart-container
docker logs --tail=100 stalwart-container
```

Далее используй постоянного администратора. Для устранения `Unknown client id` зарегистрируй OAuth-клиент в этапе 3.

Для общего `make tunnel` добавь в корневой `.env` нужные строки без `#` перед значением:

```dotenv
T_NGINX=20005:127.0.0.1:19005
T_EMAIL_ADMIN=20019:127.0.0.1:19019
T_EMAIL_WEBMAIL=20020:127.0.0.1:19020
```

Это корневой `.env` **на своём компьютере**; `HOST`/`PORT` должны вести на сервер. Закрой прежний туннель (`Ctrl+C`) и выполни `make tunnel` из корня проекта. NPM открой на `http://127.0.0.1:20005`. `T_EMAIL_WEBMAIL` необязателен; `T_EMAIL_ADMIN` нужен и после настройки.

## 3. Админка через SSH

Оставь туннель из этапа 2 открытым. В другом терминале своего компьютера **один раз** зарегистрируй OAuth-клиент. Замени `admin@example.com` на постоянного администратора; `curl` запросит пароль отдельно:

```bash
curl --fail-with-body --silent --show-error \
  --user 'admin@example.com' \
  --header 'Content-Type: application/json' \
  --data-binary @- \
  http://127.0.0.1:20019/jmap <<'JSON'
{
  "using": ["urn:ietf:params:jmap:core", "urn:stalwart:jmap"],
  "methodCalls": [["x:OAuthClient/set", {
    "create": {
      "tunnelAdmin": {
        "clientId": "http://127.0.0.1:20019/admin/oauth-client.json",
        "description": "Admin via SSH tunnel",
        "firstParty": true,
        "redirectUris": {
          "http://127.0.0.1:20019/admin/oauth/callback": true
        },
        "postLogoutRedirectUris": {
          "http://127.0.0.1:20019/admin/login": true
        },
        "grantTypes": {
          "authorizationCode": true,
          "refreshToken": true
        }
      }
    }
  }, "tunnel-admin"]]
}
JSON
```

Проверь `created.tunnelAdmin.id` в `methodResponses`, отсутствие `error`/`notCreated`; одного HTTP `200` недостаточно. Дубликат клиента не создавай.

Открой `http://127.0.0.1:20019/admin/login`, войди постоянным администратором и подтверди согласие, если оно запрошено. Проверь список пользователей и обновление страницы. Перезапуск не нужен.

URL клиента и возврата должны совпадать с адресом браузера: не заменяй `127.0.0.1` на `localhost`. Публичный DNS и `/etc/hosts` менять не нужно. `firstParty` предназначен только для доверенной админки и не отменяет пароль. Не публикуй `8080/19019` наружу; HTTP здесь работает через SSH.

Документация: [OAuth clients](https://stalw.art/docs/auth/oauth/clients/).

## 4. Пользователи и защита администратора

В **Management → Directory → Accounts** создай рабочий ящик (например, `info@example.com`) и `postmaster@example.com` с ролью **User**. `postmaster` нужен для служебной почты и отчётов; административные права ему не нужны. `admin@example.com` оставь только для управления сервером.

**До публикации ограничь административный API.** Почта и управление используют общий `/jmap`: блокировки `/admin` и локального порта недостаточно.

В Stalwart открой **Management → Directory → Accounts → нужный администратор → Credentials → Password → Allowed IPs**. Укажи только точный IP, который Stalwart видит при входе через SSH-туннель. Его можно определить по `remoteIp` успешного входа в логах. Это обычно адрес Docker-шлюза, а не `127.0.0.1`. Не копируй чужой IP и не разрешай всю Docker-сеть. Сначала сохрани открытую рабочую админскую сессию, затем проверь новый вход через туннель.

Ограничь также каждый административный API-ключ и каждый дополнительный пароль. Повтори для всех администраторов. У HTTP оставь **Client IP source = TCP peer address**: доверие произвольным forwarded-заголовкам может изменить результат проверки. Не включай IP NPM или Bulwark в список администратора.

После этапа 5 проверь отказ администратору через публичный URL, включая ранее выданные токены, и успешный новый вход через туннель. Повторяй проверку после изменений сети или учётных данных.

## 5. Веб-почта и доступ через NPM

Bulwark уже запущен отдельным контейнером, без установки Application в Stalwart. Его админка отключена. Веб-почту используй под ролью **User**. `extra_hosts` направляет Bulwark к NPM на том же Docker-хосте, сохраняя доменное имя для TLS.

После этапа 4 создай Proxy Host в панели NPM:

| Поле | Значение |
|---|---|
| Domain Names | Твой `MAIL_HOSTNAME`, например `mail.example.com` |
| Scheme | `http` |
| Forward Hostname / IP | `bulwark-container` |
| Forward Port | `3000` |
| Websockets Support | Включить |
| Cache Assets | Выключить |

В **SSL** выбери действующий сертификат либо **Request a new SSL Certificate → Let's Encrypt** для `mail.example.com`; контакт `postmaster@example.com`, принятие условий, **Force SSL**. Во вкладке **Settings / Advanced** добавь и сохрани:

```nginx
client_max_body_size 50m;

location ~* ^/(admin|setup|api/(admin|setup))(/|$) {
    return 404;
}

location ~ ^/(jmap(/|$)|\.well-known/jmap$) {
    set $stalwart_upstream stalwart-container;
    proxy_pass http://$stalwart_upstream:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_read_timeout 300s;
}

location ~* ^/(mail/config-v1\.1\.xml|\.well-known/(autoconfig/mail/config-v1\.1\.xml|mail-v1\.xml)|autodiscover/autodiscover\.(xml|json)(/[^/]+)?)$ {
    set $stalwart_discovery stalwart-container;
    proxy_pass http://$stalwart_discovery:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Authorization "";
    proxy_set_header Cookie "";
}

# NPM serves its own ACME tokens; missing tokens go to Stalwart.
error_page 404 = @stalwart_acme;

location @stalwart_acme {
    if ($uri !~ "^/\.well-known/acme-challenge/[A-Za-z0-9_-]+$") {
        return 404;
    }
    set $stalwart_acme_upstream stalwart-container;
    proxy_pass http://$stalwart_acme_upstream:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Authorization "";
    proxy_set_header Cookie "";
}
```

Не добавляй второй `location ^~ /.well-known/acme-challenge/`: NPM уже создаёт его. Fallback отправляет в Stalwart только отсутствующие ACME-токены; остальные локальные `404` остаются закрытыми. Проверено с NPM `2.15.1`; после обновления повтори проверки маршрутов и ACME.

Удали прежнее перенаправление `/` на `/webmail/`, если оно было. Главная страница и обычный `/api/` идут в Bulwark. JMAP, автонастройка клиентов и ACME направляются в Stalwart только по указанным маршрутам. Не перенаправляй весь `/api` в Stalwart.

Адреса: веб-почта `https://mail.example.com/`, админка через SSH `http://127.0.0.1:20019/admin/login`, прямой Bulwark через SSH `http://127.0.0.1:20020`. Публичный `/jmap` защищается ограничениями этапа 4, а не блокировкой страниц в NPM.

Документация: [Docker Bulwark](https://bulwarkmail.org/docs/deployment/docker), [настройки](https://bulwarkmail.org/docs/getting-started/configuration), [reverse proxy](https://bulwarkmail.org/docs/deployment/docker/reverse-proxy).

В Bulwark `1.18.0` для сохранения входа по паролю после обновления страницы включай «Запомнить меня» только на своём устройстве. Публичная веб-почта должна работать по HTTPS.

## 6. DKIM, отчёты и автонастройка клиентов

В **Management → Domains → Domains → домен → DNS Zone File** скопируй актуальные DKIM TXT-записи RSA и Ed25519 с их селекторами. Части длинного RSA-значения соединяются без пробела; скобки zone-файла в DNS-панель не вставляй.

Добавь/обнови записи, не создавая дубликаты:

| Тип | Имя | Значение |
|---|---|---|
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com` |
| TXT | `_smtp._tls` | `v=TLSRPTv1; rua=mailto:postmaster@example.com` |
| SRV | `_imaps._tcp` | приоритет `10`, вес `1`, порт `993`, цель `mail.example.com.` |
| SRV | `_submissions._tcp` | приоритет `10`, вес `1`, порт `465`, цель `mail.example.com.` |

Старый DKIM Mailu удаляй после прекращения отправки через Mailu и прохождения уже отправленных писем. Записи других приложений не трогай. При ручном DNS следи за актуальностью селекторов при смене DKIM-ключей.

`rua` задаёт адрес отчётов, но не создаёт ящик. TLS-RPT не включает MTA-STS: не публикуй `_mta-sts` без отдельно настроенной HTTPS-политики.

В **Settings → Network → Services** оставь рекламируемые IMAP, SMTP, JMAP и ManageSieve. Для IMAP/SMTP выключи cleartext, не рекламируй POP3 и другие неиспользуемые сервисы. Если изменения ещё не применились, перезапусти только Stalwart и проверь XML на этапе 8.

В панели NPM создай **отдельный Proxy Host**:

| Поле | Значение |
|---|---|
| Domain Names | `autoconfig.example.com` и `autodiscover.example.com` |
| Scheme | `http` |
| Forward Hostname / IP | `stalwart-container` |
| Forward Port | `8080` |
| Cache Assets / Websockets Support | Выключить |
| SSL | Выпустить Let's Encrypt на оба имени, контакт `postmaster@example.com`, принять условия, включить Force SSL |

В **Advanced** вставь:

```nginx
location ~* ^/(mail/config-v1\.1\.xml|\.well-known/(autoconfig/mail/config-v1\.1\.xml|mail-v1\.xml)|autodiscover/autodiscover\.(xml|json)(/[^/]+)?)$ {
    set $stalwart_discovery stalwart-container;
    proxy_pass http://$stalwart_discovery:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Authorization "";
    proxy_set_header Cookie "";
}

location / {
    return 404;
}
```

На этих двух именах доступны только ответы автонастройки, без админки и JMAP. Поддержка автонастройки зависит от почтового клиента; это не Exchange/ActiveSync.

## 7. Сертификат Stalwart для SMTP/IMAP

Сертификат NPM защищает веб, но не SMTP/IMAP: для них нужен сертификат в Stalwart. Сначала сохрани этап 5 в NPM и проверь DNS `mail.example.com` и доступность `80/443` извне.

В **Settings → TLS → ACME Providers → Create provider**:

| Поле | Значение |
|---|---|
| Description | `Let's Encrypt HTTP-01` |
| Directory URL | `https://acme-v02.api.letsencrypt.org/directory` |
| Challenge type | `HTTP-01` |
| Contact Email | `postmaster@example.com`, нажать Add |
| Renew before | Значение по умолчанию |
| Preferred chain / EAB Key ID / HMAC Key | Пусто; проверь, что браузер не подставил пароль |
| Reuse key | Выключено |

Прими условия Let’s Encrypt и сохрани провайдера. `postmaster` — контакт ACME-аккаунта, отдельные сертификаты для ящиков не нужны.

В **Management → Domains → Domains → example.com**:

1. Certificate Management: **ACME TLS certificate management**.
2. ACME Provider: **Let's Encrypt HTTP-01**.
3. Additional Hostnames: введи **`mail`** и нажми Add; домен дописывается автоматически. Не оставляй список пустым: это включает стандартный набор дополнительных имён.
4. Save. Проверь **Settings → TLS → Certificates** и логи:

```bash
docker logs --since 10m stalwart-container 2>&1 | grep -iE 'acme|certificate'
```

Успех — `acme.order-completed` для `mail.example.com` и проверка TLS на портах `465/993`. Stalwart применяет сертификат автоматически; после успешного выпуска перезапуск не нужен. Продление автоматическое: маршрут ACME и порт `80` должны оставаться доступными. При ошибке смотри **Management → Tasks → Failed**, не создавай провайдера повторно.

## 8. Итоговая проверка

DNS:

```bash
dig +short MX example.com
dig +short TXT example.com
dig +short TXT _dmarc.example.com
dig +short TXT _smtp._tls.example.com
dig +short CNAME autoconfig.example.com
dig +short CNAME autodiscover.example.com
```

Отдельно проверь TXT каждого DKIM-селектора из Stalwart. При задержке сравни ответ с `dig @AUTHORITATIVE_NS TXT NAME`.

TLS (OpenSSL с актуальным хранилищем доверенных CA):

```bash
openssl s_client -connect mail.example.com:465 -servername mail.example.com -verify_hostname mail.example.com -verify_return_error </dev/null
openssl s_client -connect mail.example.com:993 -servername mail.example.com -verify_hostname mail.example.com -verify_return_error </dev/null
openssl s_client -starttls smtp -connect mail.example.com:25 -servername mail.example.com -verify_hostname mail.example.com -verify_return_error </dev/null
```

Ожидается `Verify return code: 0 (ok)`, правильное имя и срок действия. Не используй `-k` и отключение проверки сертификата.

Автонастройка:

```bash
curl --fail-with-body 'https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=postmaster%40example.com'
curl --fail-with-body -H 'Content-Type: text/xml' \
  --data '<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006"><Request><EMailAddress>postmaster@example.com</EMailAddress><AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema></Request></Autodiscover>' \
  https://autodiscover.example.com/autodiscover/autodiscover.xml
```

Оба ответа должны содержать `mail.example.com`, IMAP `993`, SMTP `465`, SSL. `password-cleartext` в XML означает пароль внутри TLS, а не передачу по открытому соединению.

Добавь ящик в почтовый клиент: полный email и пароль пользователя. Если автонастройка не поддерживается, задай вручную сервер `mail.example.com`, IMAP `993` и SMTP `465`, оба SSL/TLS, SMTP с авторизацией.

Проверь вручную:

1. Веб-почта: вход обычным пользователем, чтение, отправка, вложения и обновление страницы.
2. На `mail.example.com` пути `/admin/login`, `/setup`, `/api/admin/config`, `/api/setup` возвращают `404`.
3. На `autoconfig` и `autodiscover` пути `/`, `/admin/login`, `/setup`, `/jmap` возвращают `404`.
4. Через SSH `http://127.0.0.1:20019/admin/login` открывает админку и список пользователей.
5. Административные JMAP-вызовы с теми же данными через публичный URL получают отказ; обычному пользователю административные методы запрещены. Проверяй `methodResponses`, не только HTTP-код.
6. Тестовое письмо во внешнюю почту и ответ обратно доставляются. В заголовках внешнего получателя SPF, DKIM и DMARC должны проходить проверки.

Документация: [ACME](https://stalw.art/docs/server/tls/acme/configuration/), [автонастройка](https://stalw.art/docs/server/autoconfig/), [DMARC rua](https://www.rfc-editor.org/rfc/rfc7489.html#section-6.3), [TLS Reporting](https://www.rfc-editor.org/rfc/rfc8460.html#section-3).

## Антивирус

Наличие ClamAV не включает фильтрацию автоматически. Отдельно подключи Milter в Stalwart к `stalwart-antivirus:7357`, включи временный отказ при недоступности фильтра и проверь обработку вложений через SMTP/JMAP. Не считай антивирус настроенным без теста. Alias `antivirus` сохранён внутри сети `email`.

## Ошибка прав при выпуске сертификата NPM

При `Permission denied: /data/logs/letsencrypt.log` проверь владельца этого файла и UID/GID процесса Certbot/NPM. В проверенной установке процесс работал как `1000:1000`, файл принадлежал `root`; исправлялся только владелец файла:

```bash
# Только после подтверждения UID/GID процесса 1000:1000.
docker exec --user 0 nginx-container chown 1000:1000 /data/logs/letsencrypt.log
```

Не используй рекурсивный `chown` или `777`. Повтори выпуск через панель NPM; сгенерированные конфиги вручную не редактируй.

## Команды Makefile

| Команда | Действие |
|---|---|
| `make help` | Показать команды с описаниями |
| `make env` | Создать `.env` из примера без перезаписи |
| `make network` | Создать внешнюю сеть, если она отсутствует |
| `make init` | Скачать образы и поднять контейнеры |
| `make up` | Поднять контейнеры и применить изменения Compose или `.env` |
| `make pull SERVICE=webmail` | Скачать только образ веб-почты |
| `make up SERVICE=webmail` | Запустить или обновить только Bulwark, не перезапуская почтовый сервер |
| `make down` | Остановить и удалить контейнеры, сохранив данные |
| `make restart` | Перезапустить существующие контейнеры |
| `make pull` | Скачать образы указанных версий |
| `make logs` | Логи всех контейнеров (последние 100 строк, live) |
| `make logs SERVICE=stalwart` | Логи почтового сервера |
| `make logs SERVICE=stalwart-antivirus` | Логи антивируса |
| `make logs SERVICE=webmail` | Логи веб-почты |
| `make ps` | Показать состояние контейнеров |
| `make config` | Проверить и показать итоговый Compose-конфиг |

После изменения Compose или `.env` используй `make up`, а не `make restart`. `make config` не проверяет DNS, сертификаты, доставку писем и ограничения доступа.

## Обновление

Сначала сделай резервную копию и проверь инструкции перехода на выбранную версию. Измени `STALWART_VERSION` в `.env`, затем:

```bash
make pull
make up
```
