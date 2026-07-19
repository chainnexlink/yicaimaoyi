#!/bin/sh
set -eu

ROOT=/opt/yicai-trade/yicai-trade-backend
INCOMING="$ROOT/deploy-finalize-20260716"
cd "$ROOT"

timestamp=$(date +%Y%m%d-%H%M%S)
cp -a docker/nginx/nginx.conf "$INCOMING/nginx-before-health-$timestamp.conf"
cp -a docker/docker-compose.yml "$INCOMING/compose-before-health-$timestamp.yml"

install -m 644 "$INCOMING/nginx.ecs.final.conf" docker/nginx/nginx.conf
sed -i 's#http://127.0.0.1:80"#http://127.0.0.1:80/nginx-health"#' \
  docker/docker-compose.yml

docker exec yicai-trade-nginx nginx -t
docker compose -p docker -f docker/docker-compose.yml --env-file docker/.env \
  up -d --no-deps --force-recreate yicai-nginx

sleep 5
docker exec yicai-trade-nginx wget -q -O- http://127.0.0.1/nginx-health
echo
echo NGINX_HEALTH_CONFIGURED
