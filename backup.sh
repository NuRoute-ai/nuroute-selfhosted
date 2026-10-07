#!/usr/bin/env bash
# Backs up NuRoute's database and settings into backups/<date-time>/: a full PostgreSQL dump
# (users, organizations, projects, provider keys encrypted, routing history) and a copy of
# .env (the keys that decrypt them; without it a backup cannot be restored). Usage analytics
# in ClickHouse are not included. NuRoute keeps running during the backup.
#
#   ./backup.sh
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

[ -f .env ] || fail "no .env here: nothing to back up"
docker compose ps --status running --format '{{.Service}}' | grep -qx postgres || fail "the database is not running (docker compose start postgres)"

dir="backups/$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$dir"
chmod 700 backups "$dir"

say "Backing up the database…"
docker compose exec -T postgres pg_dumpall -U nuroute --clean --if-exists | gzip > "$dir/postgres.sql.gz"
cp .env "$dir/env"
chmod 600 "$dir/env" "$dir/postgres.sql.gz"
echo "$(current NUROUTE_VERSION)" > "$dir/version"

gzip -t "$dir/postgres.sql.gz" || fail "the dump in $dir is damaged; nothing was replaced"
say "✓ Backup: $dir ($(du -h "$dir/postgres.sql.gz" | cut -f1)). Copy it somewhere off this server, too."
echo "$dir"
