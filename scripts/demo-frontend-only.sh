#!/usr/bin/env bash
set -euo pipefail

demo_frontend_only() {
APP_NAME="${1:?app name is required}"
SERVICE_NAME="${2:?frontend service name is required}"
APP_DIR="/opt/${APP_NAME}"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"
DEMO_FILE="${APP_DIR}/docker-compose.demo.yml"
NGINX_FILE="${APP_DIR}/nginx-demo.conf"
FRONTEND_IMAGE="${3:-}"

if ! command -v docker >/dev/null 2>&1; then
  for attempt in 1 2 3 4 5; do
    curl -fsSL https://get.docker.com | sudo sh && break
    sleep 30
  done
fi

command -v docker
sudo systemctl enable docker
sudo systemctl start docker

sudo sh -n /var/lib/cloud/instance/scripts/runcmd
sudo sed -n '/docker login/p' /var/lib/cloud/instance/scripts/runcmd | sudo sh || true

if [ -z "${FRONTEND_IMAGE}" ]; then
  FRONTEND_IMAGE="$(awk -v service="${SERVICE_NAME}" '
    $0 ~ "^[[:space:]]*" service ":" { in_service=1; next }
    in_service && $1 == "image:" { print $2; exit }
    in_service && $0 ~ "^[[:space:]]*[a-zA-Z0-9_-]+:" { exit }
  ' "${COMPOSE_FILE}")"
fi

if [ -z "${FRONTEND_IMAGE}" ]; then
  echo "Could not find frontend image for ${SERVICE_NAME} in ${COMPOSE_FILE}" >&2
  exit 1
fi

sudo tee "${NGINX_FILE}" >/dev/null <<EOF
server {
  listen 80 default_server;
  server_name _;
  location = /health {
    access_log off;
    add_header Content-Type text/plain;
    return 200 "ok\\n";
  }
  location / {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass http://frontend:3000;
  }
}
EOF

sudo tee "${DEMO_FILE}" >/dev/null <<EOF
services:
  nginx:
    image: nginx:1.27-alpine
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ${NGINX_FILE}:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - frontend

  frontend:
    image: ${FRONTEND_IMAGE}
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      HOSTNAME: 0.0.0.0
EOF

sudo docker compose -f "${COMPOSE_FILE}" down --remove-orphans || true
sudo docker compose -f "${DEMO_FILE}" pull
sudo docker compose -f "${DEMO_FILE}" up -d
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
curl -i --max-time 10 http://127.0.0.1/health
curl -I --max-time 10 http://127.0.0.1/
}

if [ "$#" -gt 0 ]; then
  demo_frontend_only "$@"
fi
