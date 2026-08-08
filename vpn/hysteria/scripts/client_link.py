import os
from urllib.parse import quote, urlencode


auth = quote(os.environ["HYSTERIA_PASSWORD"], safe="")
host = os.environ["HYSTERIA_HOST"]
port = os.environ["HYSTERIA_PORT"]
name = quote(os.environ.get("HYSTERIA_CLIENT_NAME", "hysteria"), safe="")

query = {
    "obfs": "salamander",
    "obfs-password": os.environ["HYSTERIA_OBFS_PASSWORD"],
    "sni": os.environ.get("HYSTERIA_SNI") or host,
    "insecure": os.environ.get("HYSTERIA_CLIENT_INSECURE", "0"),
}

pin = os.environ.get("HYSTERIA_CLIENT_PIN_SHA256", "")
if pin:
    query["pinSHA256"] = pin

print(f"hysteria2://{auth}@{host}:{port}/?{urlencode(query)}#{name}")
