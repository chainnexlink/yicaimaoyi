#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker 未安装，请先运行 server-init.sh"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose V2 未安装"
  exit 1
fi

if [ ! -f ../target/yicai-trade-platform-1.0.0.jar ]; then
  echo "缺少后端 JAR：../target/yicai-trade-platform-1.0.0.jar"
  exit 1
fi

if [ ! -f .env ]; then
  umask 077
  DB_PASSWORD="$(openssl rand -hex 24)"
  MYSQL_ROOT_PASSWORD="$(openssl rand -hex 32)"
  REDIS_PASSWORD="$(openssl rand -hex 24)"
  JWT_SECRET="$(openssl rand -base64 72 | tr -d '\n')"
  cat > .env <<EOF
API_DOMAIN=api.chainnexlink.com
ACME_EMAIL=
DB_NAME=yicai_trade
DB_USERNAME=yicai_app
DB_PASSWORD=${DB_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_SECRET=${JWT_SECRET}
CORS_ALLOWED_ORIGINS=https://yicai-trade.vercel.app,https://chainnexlink.com,https://www.chainnexlink.com
EMAIL_ENABLED=false
SMS_ENABLED=false
WECHAT_ENABLED=false
EOF
  echo "已生成仅 root 可读的 docker/.env"
else
  echo "保留现有 docker/.env"
fi

chmod 600 .env
docker compose pull
docker compose up -d --build
docker compose ps

echo
echo "部署已启动。DNS 生效后验证：https://$(grep '^API_DOMAIN=' .env | cut -d= -f2)/healthz"
