#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/opt/yicai-trade/yicai-trade-backend
DOCKER_DIR="$ROOT/docker"
OUT="$ROOT/deploy-incoming"

dump_columns() {
  docker exec yicai-trade-mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -B -e "SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COALESCE(COLUMN_DEFAULT, '\''<NULL>'\''), EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='\''yicai_trade'\'' ORDER BY TABLE_NAME, ORDINAL_POSITION"' | sort
}

docker stop yicai-trade-backend >/dev/null 2>&1 || true
dump_columns > "$OUT/schema-before.tsv"

cd "$DOCKER_DIR"
timeout 150 docker compose -f docker-compose.production.yml --project-name docker run --rm \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
  yicai-backend > "$OUT/schema-update.log" 2>&1 || true

dump_columns > "$OUT/schema-after.tsv"
comm -13 "$OUT/schema-before.tsv" "$OUT/schema-after.tsv" > "$OUT/schema-added.tsv"

docker start yicai-trade-backend >/dev/null
echo '--- ADDED OR CHANGED COLUMNS ---'
cat "$OUT/schema-added.tsv"
echo '--- UPDATE RUN RESULT ---'
grep -E 'Started YiCai|ERROR|SchemaManagementException' "$OUT/schema-update.log" | tail -30 || true
