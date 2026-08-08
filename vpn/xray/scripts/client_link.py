import os
from urllib.parse import quote, urlencode


uuid = os.environ["XRAY_CLIENT_UUID"]
host = os.environ["XRAY_HOST"]
port = os.environ["XRAY_PORT"]
name = quote(os.environ.get("XRAY_CLIENT_NAME", "xray"), safe="")

query = {
    "encryption": os.environ.get("XRAY_CLIENT_ENCRYPTION", "none"),
    "flow": os.environ.get("XRAY_CLIENT_FLOW", "xtls-rprx-vision"),
    "security": "reality",
    "sni": os.environ["XRAY_REALITY_SERVER_NAME"],
    "fp": os.environ.get("XRAY_CLIENT_FINGERPRINT", "chrome"),
    "pbk": os.environ["XRAY_REALITY_PUBLIC_KEY"],
    "sid": os.environ["XRAY_REALITY_SHORT_ID"],
    "spx": os.environ.get("XRAY_REALITY_SPIDER_X", "/"),
    "type": "tcp",
}

print(f"vless://{uuid}@{host}:{port}?{urlencode(query)}#{name}")
