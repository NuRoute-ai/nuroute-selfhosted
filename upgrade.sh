#!/usr/bin/env bash
# Upgrades NuRoute to another release. Backs up first; if the new release does not start, puts
# the backup and the previous release back automatically.
#
#   ./upgrade.sh 1.1.0
#   ./upgrade.sh 1.1.0 --no-pull   # images already loaded on this server (offline installs)
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

target=""; PULL=1
for arg in "$@"; do
  case "$arg" in
    --no-pull) PULL=0 ;;
    *) target="$arg" ;;
  esac
done
[[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "usage: ./upgrade.sh <version>, for example ./upgrade.sh 1.1.0 (see the release notes for the latest)"
from="$(current NUROUTE_VERSION)"
[ "$target" != "$from" ] || { say "Already on $target."; exit 0; }

say "Upgrading NuRoute $from → $target"
say "Release notes: https://github.com/NuRoute-ai/nuroute-selfhosted/releases/tag/v$target"
say ""

if [ "$PULL" = 1 ]; then
  say "1/4 Downloading $target…"
  NUROUTE_VERSION="$target" docker compose pull --quiet || fail "could not download $target (check the version and this server's internet access). Nothing was changed."
else
  say "1/4 Checking the $target images are on this server…"
  for image in $(NUROUTE_VERSION="$target" docker compose config --images); do
    docker image inspect "$image" >/dev/null 2>&1 || fail "$image is not on this server (load it with docker load first). Nothing was changed."
  done
fi

say "2/4 Backing up…"
backup="$(./backup.sh | tail -1)"

say "3/4 Starting $target (applies database changes)…"
set_value NUROUTE_VERSION "$target"
docker compose up -d --remove-orphans

say "4/4 Checking it works…"
if wait_ready; then
  say ""
  say "✓ NuRoute $target is running. The backup from before the upgrade is in $backup."
  exit 0
fi

say ""
say "! $target did not start. Putting $from and the backup back…"
docker compose logs --tail 50 > "upgrade-failure-$target.log" 2>&1 || true
NUROUTE_RESTORE_YES=1 ./restore.sh "$backup" </dev/null
fail "the upgrade to $target was rolled back; you are on $from again. Send upgrade-failure-$target.log to support@nuroute.ai."
