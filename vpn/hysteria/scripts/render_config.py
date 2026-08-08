import os
from pathlib import Path


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


mode = env("HYSTERIA_TLS_MODE", "cert")
certs_path = Path(env("HYSTERIA_CERTS_HOST_PATH", "./certs"))
Path("acme").mkdir(exist_ok=True)
certs_path.mkdir(parents=True, exist_ok=True)

lines = [
    f"listen: :{env('HYSTERIA_PORT', '443')}",
    "",
]

if mode == "acme":
    lines.extend(
        [
            "acme:",
            "  domains:",
            f"    - {env('HYSTERIA_HOST')}",
            f"  email: {env('HYSTERIA_ACME_EMAIL')}",
            f"  ca: {env('HYSTERIA_ACME_CA', 'letsencrypt')}",
            f"  listenHost: {env('HYSTERIA_ACME_LISTEN_HOST', '0.0.0.0')}",
            f"  dir: {env('HYSTERIA_ACME_DIR', '/etc/hysteria/acme')}",
            f"  type: {env('HYSTERIA_ACME_TYPE', 'http')}",
            "  http:",
            f"    altPort: {env('HYSTERIA_ACME_HTTP_PORT', '80')}",
            "",
        ]
    )
elif mode == "cert":
    lines.extend(
        [
            "tls:",
            f"  cert: {env('HYSTERIA_CERT_PATH')}",
            f"  key: {env('HYSTERIA_KEY_PATH')}",
            "",
        ]
    )
else:
    raise SystemExit("HYSTERIA_TLS_MODE должен быть acme или cert")

lines.extend(
    [
        "auth:",
        "  type: password",
        f"  password: {env('HYSTERIA_PASSWORD')}",
        "",
        "obfs:",
        "  type: salamander",
        "  salamander:",
        f"    password: {env('HYSTERIA_OBFS_PASSWORD')}",
        "",
        "masquerade:",
        "  type: proxy",
        "  proxy:",
        f"    url: {env('HYSTERIA_MASQUERADE_URL', 'https://www.microsoft.com')}",
        "    rewriteHost: true",
    ]
)

Path("config.yaml").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("config.yaml создан")
