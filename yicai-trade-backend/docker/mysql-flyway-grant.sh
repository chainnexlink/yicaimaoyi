#!/usr/bin/env bash
set -Eeuo pipefail

docker exec yicai-trade-mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT SELECT ON performance_schema.user_variables_by_thread TO '\''yicai_app'\''@'\''%'\''; FLUSH PRIVILEGES;"'
docker restart yicai-trade-backend >/dev/null
echo grant_applied_and_backend_restarted
