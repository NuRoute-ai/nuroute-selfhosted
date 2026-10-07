#!/usr/bin/env bash
# Collects what NuRoute support needs to help you into one file, for you to review and send.
# It contains: versions, what is running, your settings with every secret removed, and the last
# 500 log lines per service with message content removed. Nothing is sent automatically.
#
#   ./support-bundle.sh
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

out="support-bundle-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$out/logs"

{ echo "NuRoute $(current NUROUTE_VERSION)"; docker version --format 'Docker {{.Server.Version}}' 2>/dev/null; docker compose version; uname -srm; } > "$out/versions.txt"
docker compose ps -a > "$out/status.txt" 2>&1 || true
docker compose images > "$out/images.txt" 2>&1 || true
if healthy; then echo "API: healthy" > "$out/health.txt"; else echo "API: not answering" > "$out/health.txt"; fi

# Settings: names kept, secret values replaced.
sed -E 's/^((POSTGRES_PASSWORD|JWT_SECRET|AUTH_ENCRYPTION_KEY|PROVIDER_ENCRYPTION_KEY|LICENSE_PUBLIC_KEY)=).*/\1(removed)/' .env > "$out/settings.txt"

# Logs: message content and anything that looks like a key removed.
for svc in $(docker compose config --services); do
  docker compose logs --no-color --tail 500 "$svc" 2>&1 \
    | sed -E 's/"(content|messages|prompt|completion|input|output|text)":("([^"\\]|\\.)*"|\[[^]]*\]|\{[^}]*\})/"\1":"(removed)"/g' \
    | sed -E 's/(sk-[A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1…(removed)/g; s/(nrl_[A-Za-z0-9_-]{4})[A-Za-z0-9_-]+/\1…(removed)/g; s/(Bearer )[A-Za-z0-9._-]+/\1(removed)/g' \
    > "$out/logs/$svc.log" || true
done

tar -czf "$out.tar.gz" "$out" && rm -rf "$out"
say "✓ Created $out.tar.gz"
say "Look through it before sending (tar -tzf $out.tar.gz lists the files), then email it to support@nuroute.ai."
