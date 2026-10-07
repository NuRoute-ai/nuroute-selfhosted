#!/usr/bin/env bash
# Restores a backup made by backup.sh: the database as it was, and the version that made it.
# Everything written since that backup is lost. NuRoute is stopped while it restores.
#
#   ./restore.sh backups/20261005-101500
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

dir="${1:-}"
[ -n "$dir" ] && [ -f "$dir/postgres.sql.gz" ] || fail "usage: ./restore.sh backups/<date-time>  (a folder made by ./backup.sh)"

if [ -t 0 ] && [ "${NUROUTE_RESTORE_YES:-}" != 1 ]; then
  printf 'Restore %s? Everything written since then will be lost. Type "restore" to continue: ' "$dir"
  read -r answer; [ "$answer" = restore ] || fail "cancelled"
fi

# The encryption keys must be the ones the backup was made with.
for name in AUTH_ENCRYPTION_KEY PROVIDER_ENCRYPTION_KEY; do
  backed=$({ grep -E "^$name=" "$dir/env" || true; } | cut -d= -f2-)
  [ "$backed" = "$(current "$name")" ] || { cp "$dir/env" .env; chmod 600 .env; say "! Restored .env from the backup (its encryption keys differ from the current ones)"; break; }
done
[ -f "$dir/version" ] && set_value NUROUTE_VERSION "$(cat "$dir/version")"

say "Stopping NuRoute…"
docker compose stop
docker compose up -d postgres
for _ in $(seq 1 30); do docker compose exec -T postgres pg_isready -U nuroute >/dev/null 2>&1 && break; sleep 2; done

say "Restoring the database…"
# The dump drops and recreates the nuroute login, which this connection is using; skip those two.
gunzip -c "$dir/postgres.sql.gz" | grep -vE '^(DROP ROLE IF EXISTS|CREATE ROLE) nuroute;$' | docker compose exec -T postgres psql -U nuroute -d postgres -q -v ON_ERROR_STOP=0 >/dev/null

say "Starting NuRoute $(current NUROUTE_VERSION)…"
docker compose up -d
wait_ready || fail "NuRoute did not start after the restore. See: docker compose logs"
say "✓ Restored $dir"
