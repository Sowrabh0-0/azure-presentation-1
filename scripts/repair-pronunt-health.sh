#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

path = Path("/opt/pronunt/nginx.conf")
config = path.read_text()
old = "location /health { proxy_pass http://pronunt-frontend-service:3000; }"
new = 'location = /health { access_log off; return 200 "ok\\n"; add_header Content-Type text/plain; }'
if old in config:
    config = config.replace(old, new)
elif "location = /health" not in config:
    config = config.replace("location / {", f"{new}\n        location / {{", 1)
path.write_text(config)
PY

sudo docker compose -f /opt/pronunt/docker-compose.yml restart nginx
curl -i --max-time 5 http://127.0.0.1/health
