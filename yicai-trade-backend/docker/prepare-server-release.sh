#!/bin/sh
set -eu

ROOT=/opt/yicai-trade/yicai-trade-backend
INCOMING="$ROOT/deploy-finalize-20260716"
cd "$ROOT"

timestamp=$(date +%Y%m%d-%H%M%S)
backup="$INCOMING/backup-$timestamp"
install -d -m 700 "$backup"

cp -a target/yicai-trade-platform-1.0.0.jar "$backup/app.jar"
cp -a docker/docker-compose.production.yml "$backup/docker-compose.production.yml"
cp -a docker/nginx/nginx.conf "$backup/nginx.conf"

install -m 644 "$INCOMING/yicai-trade-platform-1.0.0.jar" \
  target/yicai-trade-platform-1.0.0.jar

if ! grep -q 'MANAGEMENT_HEALTH_MAIL_ENABLED' docker/docker-compose.production.yml; then
  sed -i '/EMAIL_ENABLED:/a\      MANAGEMENT_HEALTH_MAIL_ENABLED: "false"' \
    docker/docker-compose.production.yml
fi

mysql_user=$(docker exec yicai-trade-mysql printenv MYSQL_USER)
if [ "$mysql_user" != 'yicai_app' ]; then
  echo "Unexpected MySQL application user: $mysql_user" >&2
  exit 1
fi

docker exec -i yicai-trade-mysql sh -c \
  'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  < "$INCOMING/mysql-flyway-grant.sql"

echo "BACKUP=$backup"
sha256sum target/yicai-trade-platform-1.0.0.jar
grep -n 'EMAIL_ENABLED\|MANAGEMENT_HEALTH_MAIL_ENABLED' \
  docker/docker-compose.production.yml
echo PREPARED_OK
