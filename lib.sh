# Shared by install.sh, upgrade.sh, backup.sh, restore.sh and support-bundle.sh. Not run directly.

say()  { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# The value of NAME in .env (empty when missing).
current() { { grep -E "^$1=" .env || true; } | head -1 | cut -d= -f2-; }

# Sets NAME=VALUE in .env, replacing the existing line.
set_value() {
  local tmp; tmp=$(mktemp)
  awk -v k="$1" -v v="$2" 'BEGIN{FS=OFS="="} $1==k {$0=k"="v} {print}' .env > "$tmp" && mv "$tmp" .env
  chmod 600 .env
}

healthy() { docker compose exec -T api-gateway wget -qO- http://127.0.0.1:3000/health >/dev/null 2>&1; }

# Waits up to ~7 minutes for NuRoute to answer. Returns 1 if the migrate step failed or time ran out.
wait_ready() {
  printf 'Waiting for NuRoute to be ready'
  for _ in $(seq 1 90); do
    if healthy; then printf ' ready.\n'; return 0; fi
    case "$(docker compose ps -a --format '{{.State}} {{.ExitCode}}' migrate 2>/dev/null || true)" in
      exited\ 0|"") ;;
      exited*) printf '\nThe database setup step failed. See: docker compose logs migrate\n'; return 1 ;;
    esac
    printf '.'; sleep 5
  done
  printf '\nNuRoute did not become ready in time. See: docker compose ps   and   docker compose logs\n'
  return 1
}

[ -f docker-compose.yml ] || fail "run this from the NuRoute install folder (the one with docker-compose.yml)"
