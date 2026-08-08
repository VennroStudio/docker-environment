import json
import os
from pathlib import Path


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


client = {
    "id": env("XRAY_CLIENT_UUID"),
    "email": env("XRAY_CLIENT_NAME", "client"),
}

flow = env("XRAY_CLIENT_FLOW")
if flow and flow != "none":
    client["flow"] = flow

config = {
    "log": {"loglevel": env("XRAY_LOG_LEVEL", "warning")},
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": int(env("XRAY_PORT", "9443")),
            "protocol": "vless",
            "settings": {
                "clients": [client],
                "decryption": "none",
            },
            "sniffing": {
                "enabled": True,
                "destOverride": ["http", "tls", "quic"],
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": False,
                    "dest": env("XRAY_REALITY_DEST", "www.microsoft.com:443"),
                    "xver": 0,
                    "serverNames": [env("XRAY_REALITY_SERVER_NAME", "www.microsoft.com")],
                    "privateKey": env("XRAY_REALITY_PRIVATE_KEY"),
                    "shortIds": [env("XRAY_REALITY_SHORT_ID")],
                },
            },
        }
    ],
    "outbounds": [
        {"protocol": "freedom", "tag": "direct"},
        {"protocol": "blackhole", "tag": "blocked"},
    ],
}

Path("config.json").write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
print("config.json создан")
