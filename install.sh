#!/usr/bin/env bash
# Installs NuRoute on this server: checks it, creates .env with generated secrets, pulls the
# images and starts everything. Safe to run again; it never overwrites a secret you already have.
#
#   ./install.sh                       # asks for the domain
#   ./install.sh --domain nuroute.acme.com
#   ./install.sh --force               # skip the minimum server size check
#   ./install.sh --no-pull             # use images already on this server (offline installs)
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN=""; FORCE=0; PULL=1
while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    --no-pull) PULL=0; shift ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (see ./install.sh --help)"; exit 1 ;;
  esac
done

# shellcheck source=lib.sh
. ./lib.sh

say "NuRoute installer"
say ""

# ── 1. The tools this needs ────────────────────────────────────────────────
command -v docker >/dev/null || fail "Docker is not installed. Install it from https://docs.docker.com/engine/install/ and run this again."
docker compose version >/dev/null 2>&1 || fail "Docker Compose is missing (the 'docker compose' command, v2 or newer). Install the Docker Compose plugin and run this again."
command -v openssl >/dev/null || fail "openssl is not installed (it generates your secrets). Install it with your package manager, e.g. 'apt-get install openssl'."
docker info >/dev/null 2>&1 || fail "Docker is installed but not running, or this user may not use it. Start Docker, or run this as a user in the 'docker' group."
say "✓ Docker and Docker Compose"

# ── 2. The server's size ───────────────────────────────────────────────────
cpus=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 0)
mem_gb=$( (awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null) || echo 0)
disk_gb=$(df -Pk . | awk 'NR==2 {printf "%d", $4/1024/1024}')
small=""
short() { small="${small:+$small,} $1"; }
[ "$cpus" -lt 4 ] && short "${cpus} CPUs (4 needed)"
[ "${mem_gb:-0}" -gt 0 ] && [ "$mem_gb" -lt 15 ] && short "${mem_gb} GB memory (16 needed)"
[ "$disk_gb" -lt 100 ] && short "${disk_gb} GB free disk (100 needed)"
if [ -n "$small" ]; then
  if [ "$FORCE" = 1 ]; then say "! Smaller than recommended:$small. Continuing because of --force."
  else fail "this server is smaller than NuRoute needs:$small. Use a larger server, or run with --force to try anyway."; fi
else
  mem_text=""; [ "${mem_gb:-0}" -gt 0 ] && mem_text="${mem_gb} GB memory, "
  say "✓ Server size: ${cpus} CPUs, ${mem_text}${disk_gb} GB free disk"
fi

# ── 3. Settings and secrets ────────────────────────────────────────────────
if [ ! -f .env ]; then cp .env.example .env; say "✓ Created .env"; else say "✓ Using your existing .env"; fi

generated=0
for name in POSTGRES_PASSWORD JWT_SECRET AUTH_ENCRYPTION_KEY PROVIDER_ENCRYPTION_KEY; do
  if [ "$(current "$name")" = "GENERATED_BY_INSTALL" ] || [ -z "$(current "$name")" ]; then
    set_value "$name" "$(openssl rand -hex 32)"; generated=$((generated + 1))
  fi
done
[ "$generated" -gt 0 ] && say "✓ Generated $generated secret(s) in .env (back this file up; it is needed to restore)"
chmod 600 .env

[ -z "$DOMAIN" ] && DOMAIN="$(current NUROUTE_DOMAIN)"
if [ -z "$DOMAIN" ]; then
  [ -t 0 ] || fail "set the domain: ./install.sh --domain nuroute.yourcompany.com"
  printf 'Domain your team will use (e.g. nuroute.acme.com): '; read -r DOMAIN
fi
DOMAIN="${DOMAIN#https://}"; DOMAIN="${DOMAIN#http://}"; DOMAIN="${DOMAIN%%/*}"
[ -n "$DOMAIN" ] || fail "a domain is required"
set_value NUROUTE_DOMAIN "$DOMAIN"
say "✓ Domain: $DOMAIN"

# ── 4. Start ───────────────────────────────────────────────────────────────
say ""
if [ "$PULL" = 1 ]; then
  say "Downloading NuRoute $(current NUROUTE_VERSION) (several GB the first time)…"
  docker compose pull --quiet
fi
say "Starting…"
docker compose up -d --remove-orphans

wait_ready || fail "NuRoute did not start. Nothing is lost: fix the cause and run ./install.sh again."

say ""
say "NuRoute is running."
say ""
say "Next: open https://$DOMAIN/app/setup"
say "  - activate it with the licence key from your contract, or start a 14-day trial"
say "  - then create the first admin account"
say ""
say "Useful: docker compose ps (status) · docker compose logs -f (logs) · ./upgrade.sh (new release)"
