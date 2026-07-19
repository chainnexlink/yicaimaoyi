#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/opt/yicai-trade/yicai-trade-backend
DOCKER_DIR="$ROOT/docker"
INCOMING="$ROOT/deploy-incoming"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/deploy-backups/$STAMP"

mkdir -p "$BACKUP" "$ROOT/target" "$DOCKER_DIR/nginx"

for item in \
  "$ROOT/target/yicai-trade-platform-1.0.0.jar" \
  "$DOCKER_DIR/docker-compose.yml" \
  "$DOCKER_DIR/.env" \
  "$DOCKER_DIR/nginx/nginx.conf"; do
  if [ -f "$item" ]; then
    cp -a "$item" "$BACKUP/$(basename "$item")"
  fi
done

install -m 0644 "$INCOMING/yicai-trade-platform-1.0.0.jar" "$ROOT/target/yicai-trade-platform-1.0.0.jar"
install -m 0644 "$INCOMING/Dockerfile.runtime" "$DOCKER_DIR/Dockerfile.runtime"
install -m 0644 "$INCOMING/docker-compose.yml" "$DOCKER_DIR/docker-compose.production.yml"

umask 077
DB_PASSWORD="$(openssl rand -hex 24)"
MYSQL_ROOT_PASSWORD="$(openssl rand -hex 32)"
REDIS_PASSWORD="$(openssl rand -hex 24)"
JWT_SECRET="$(openssl rand -base64 72 | tr -d '\n')"

{
  printf '%s\n' 'API_DOMAIN=api.chainnexlink.com'
  printf '%s\n' 'ACME_EMAIL='
  printf '%s\n' 'DB_NAME=yicai_trade'
  printf '%s\n' 'DB_USERNAME=yicai_app'
  printf 'DB_PASSWORD=%s\n' "$DB_PASSWORD"
  printf 'MYSQL_ROOT_PASSWORD=%s\n' "$MYSQL_ROOT_PASSWORD"
  printf 'REDIS_PASSWORD=%s\n' "$REDIS_PASSWORD"
  printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
  printf '%s\n' 'CORS_ALLOWED_ORIGINS=https://yicai-trade.vercel.app,https://chainnexlink.com,https://www.chainnexlink.com'
  printf '%s\n' 'EMAIL_ENABLED=false'
  printf '%s\n' 'SMS_ENABLED=false'
  printf '%s\n' 'WECHAT_ENABLED=false'
} > "$DOCKER_DIR/.env.new"
chmod 600 "$DOCKER_DIR/.env.new"
mv -f "$DOCKER_DIR/.env.new" "$DOCKER_DIR/.env"

cd "$DOCKER_DIR"
docker compose -f docker-compose.production.yml --project-name docker pull yicai-mysql yicai-redis
docker compose -f docker-compose.production.yml --project-name docker up -d --build yicai-mysql yicai-redis yicai-backend

healthy=false
for _ in $(seq 1 48); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' yicai-trade-backend 2>/dev/null || true)"
  if [ "$status" = healthy ]; then
    healthy=true
    break
  fi
  sleep 5
done

if [ "$healthy" != true ]; then
  docker compose -f docker-compose.production.yml --project-name docker ps
  docker logs --tail 180 yicai-trade-backend
  exit 1
fi

install -m 0644 "$INCOMING/nginx.ecs.final.conf" "$DOCKER_DIR/nginx/nginx.conf"
if ! docker exec yicai-trade-nginx nginx -t; then
  install -m 0644 "$BACKUP/nginx.conf" "$DOCKER_DIR/nginx/nginx.conf"
  docker exec yicai-trade-nginx nginx -t
  exit 1
fi
docker exec yicai-trade-nginx nginx -s reload

docker compose -f docker-compose.production.yml --project-name docker ps
curl --fail --silent --show-error --resolve api.chainnexlink.com:443:127.0.0.1 https://api.chainnexlink.com/healthz
printf '\nDeployment backup: %s\n' "$BACKUP"
