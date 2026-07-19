#!/usr/bin/env bash
set -Eeuo pipefail

docker stop yicai-trade-backend >/dev/null 2>&1 || true
docker exec yicai-trade-mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS yicai_trade; CREATE DATABASE yicai_trade CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON yicai_trade.* TO '\''yicai_app'\''@'\''%'\''; GRANT SELECT ON performance_schema.user_variables_by_thread TO '\''yicai_app'\''@'\''%'\''; FLUSH PRIVILEGES;"'
docker start yicai-trade-backend >/dev/null
echo clean_database_created_and_backend_started
