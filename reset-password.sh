#!/usr/bin/env bash
# Prints a password reset link for a NuRoute account, valid for one hour. For installs without
# a mail server (Settings → Email), where the dashboard cannot email it. Send the link to the
# person yourself; it works once.
#
#   ./reset-password.sh someone@yourcompany.com
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

email="${1:-}"
[ -n "$email" ] || fail "usage: ./reset-password.sh <email of the account>"
domain="$(current NUROUTE_DOMAIN)"
[ -n "$domain" ] || fail "NUROUTE_DOMAIN is not set in .env"
docker compose ps --status running --format '{{.Service}}' | grep -qx auth-service || fail "NuRoute is not running (docker compose up -d)"

link=$(docker compose exec -T auth-service node services/auth-service/dist/reset-password-cli.js "$email" "https://$domain/app/reset-password") \
  || fail "no reset link was made (see the message above)"
say "Reset link for $email, valid for one hour and usable once:"
say ""
say "  $link"
say ""
say "Send it to them directly (not in a shared channel): anyone with the link can set the password."
