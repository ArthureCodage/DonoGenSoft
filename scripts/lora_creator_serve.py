"""Run LoRA Creator behind a login (HTTP Basic auth).

LoRA Creator has no login of its own; on a rented GPU its port is reachable from
the internet, so DonoGenSoft wraps it with the same user/password as the other UIs.

Usage (with kohya_ss's Python):  python lora_creator_serve.py <lora-creator dir>
Env: DGS_USER, DGS_PASS, LC_HOST (default 0.0.0.0), LC_PORT (default 7870),
     LORA_CREATOR_CONFIG (config.json written by start.sh).
"""

import base64
import os
import secrets
import sys
from pathlib import Path

app_dir = (Path(sys.argv[1]) / "app").resolve()
sys.path.insert(0, str(app_dir))
os.chdir(app_dir)

import server  # noqa: E402  (LoRA Creator's FastAPI app)
import uvicorn  # noqa: E402

user = os.environ.get("DGS_USER", "dono")
password = os.environ["DGS_PASS"]
expected = b"Basic " + base64.b64encode(f"{user}:{password}".encode())
inner = server.app


async def app(scope, receive, send):
    if scope["type"] in ("http", "websocket"):
        auth = dict(scope.get("headers") or []).get(b"authorization", b"")
        if not secrets.compare_digest(auth, expected):
            if scope["type"] == "websocket":
                await send({"type": "websocket.close", "code": 1008})
                return
            await send({
                "type": "http.response.start",
                "status": 401,
                "headers": [
                    (b"www-authenticate", b'Basic realm="LoRA Creator", charset="UTF-8"'),
                    (b"content-type", b"text/plain; charset=utf-8"),
                ],
            })
            await send({"type": "http.response.body", "body": b"Login required"})
            return
    await inner(scope, receive, send)


if __name__ == "__main__":
    host = os.environ.get("LC_HOST", "0.0.0.0")
    port = int(os.environ.get("LC_PORT", "7870"))
    print(f"LoRA Creator listening on {host}:{port} (login required)", flush=True)
    uvicorn.run(app, host=host, port=port, log_level="warning")
