#!/usr/bin/env bash
# One-line install of NuRoute self-hosted:
#
#   curl -fsSL https://raw.githubusercontent.com/NuRoute-ai/nuroute-selfhosted/main/get.sh | bash -s -- --domain nuroute.acme.com
#
# Downloads the latest release of this install kit (or NUROUTE_KIT_VERSION=1.2.0) into ./nuroute
# (or NUROUTE_DIR), then runs its install.sh with the options you passed. Run it again later
# from that folder with ./install.sh; upgrade with ./upgrade.sh.
set -euo pipefail

REPO="${NUROUTE_KIT_REPO:-NuRoute-ai/nuroute-selfhosted}"
DIR="${NUROUTE_DIR:-nuroute}"

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
command -v curl >/dev/null || fail "curl is not installed"
command -v tar >/dev/null || fail "tar is not installed"

version="${NUROUTE_KIT_VERSION:-}"
if [ -z "$version" ]; then
  # The latest release's tag, from the redirect GitHub answers with (no API token needed).
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") \
    || fail "could not reach github.com to find the latest NuRoute release"
  version="${url##*/v}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "could not tell the latest NuRoute release from $url"
fi

[ -e "$DIR/docker-compose.yml" ] && fail "$DIR already has NuRoute in it: cd $DIR and run ./install.sh (or ./upgrade.sh $version)"
echo "Downloading the NuRoute $version install kit into ./$DIR …"
mkdir -p "$DIR"
curl -fsSL "https://github.com/$REPO/archive/refs/tags/v$version.tar.gz" | tar -xz -C "$DIR" --strip-components=1 \
  || fail "could not download release $version of $REPO"

cd "$DIR"
# The installer reads the terminal for anything it must ask; keep it attached under curl | bash.
if [ -t 1 ] && [ -r /dev/tty ]; then exec ./install.sh "$@" < /dev/tty; fi
exec ./install.sh "$@"
