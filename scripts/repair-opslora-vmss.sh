#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  for attempt in 1 2 3 4 5; do
    curl -fsSL https://get.docker.com | sudo sh && break
    sleep 30
  done
fi

command -v docker
sudo usermod -aG docker azureuser || true
sudo systemctl enable docker
sudo systemctl start docker

sudo sh /var/lib/cloud/instance/scripts/runcmd

python3 - <<'PY'
from pathlib import Path

path = Path("/opt/opslora/nginx.conf")
config = path.read_text()
health = '        location = /health { access_log off; return 200 "ok\\n"; add_header Content-Type text/plain; }\n'
needle = "        location / { proxy_pass http://frontend-service:3000;"
if "location = /health" not in config:
    config = config.replace(needle, health + needle, 1)
path.write_text(config)
PY

sudo docker compose -f /opt/opslora/docker-compose.yml restart nginx
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
curl -i --max-time 5 http://127.0.0.1/health
