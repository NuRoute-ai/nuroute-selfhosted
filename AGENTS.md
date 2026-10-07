# NuRoute self-hosted: instructions for AI coding agents

You are helping a person install or run NuRoute, a self-hosted AI gateway, on the Linux server you
are working on. Follow these steps in order. The person's docs are https://docs.nuroute.ai/self-hosting/install;
error messages and fixes are at https://docs.nuroute.ai/self-hosting/troubleshooting.

## Rules

- Ask the person before installing software, changing the firewall, or using `sudo`. Show the command first.
- Never print, copy, upload or summarise `.env` or anything under `backups/`: they hold the encryption keys and database passwords.
- Never ask for, type or store a NuRoute licence key, provider API key or password. The person enters those in the browser.
- Never run `docker compose down -v`, `docker volume rm`, `docker system prune` or delete `backups/`: that deletes customer data.
- Never edit `docker-compose.yml` or `Caddyfile`, and never change `POSTGRES_PASSWORD`, `JWT_SECRET`, `AUTH_ENCRYPTION_KEY` or `PROVIDER_ENCRYPTION_KEY` in `.env` after the first start.
- Use `--force` (skip the server size check) only if the person agrees after you have told them which check failed.
- If a step fails, quote the exact error line, look it up on the troubleshooting page, and tell the person what you found. Do not guess a workaround.

## Install

### 1. The domain

You need the domain the team will open, without `https://`, for example `nuroute.acme.com`. If the
person's request does not name it, ask. Then check it points at this server:

```bash
dig +short A <domain>
curl -4 -s https://api.ipify.org; echo
```

Both must print the same IPv4 address. If they do not, stop: the person must create a DNS `A`
record for the domain pointing at that address, and wait until `dig` shows it. HTTPS
certificates are issued automatically only once DNS is right.

### 2. The server

```bash
uname -m; nproc; free -g | awk '/Mem/ {print $2 " GB memory"}'; df -h ~ | tail -1
sudo ss -ltnp | grep -E ':(80|443)\b' || echo "ports 80 and 443 are free"
```

- Architecture `x86_64` or `aarch64`. At least 4 CPUs, 16 GB memory, 100 GB free disk.
- Ports 80 and 443 must be free and reachable from the internet (open them in the cloud
  provider's firewall or security group if needed; ask the person).

### 3. Docker

```bash
docker --version && docker compose version && docker info >/dev/null && echo "docker ok"
```

If Docker is missing, ask the person, then install it and let this user run it:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
```

After `usermod`, the group applies to new logins only: run the following commands with
`sg docker -c '<command>'`, or ask the person to log out and in again.

### 4. Install NuRoute

Run this in the person's home folder. It downloads the latest release into `./nuroute`, creates
`.env` with generated secrets, pulls the images (several GB) and starts everything. It takes 5 to
15 minutes: run it with a timeout of at least 20 minutes, or in the background and follow its output.

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/NuRoute-ai/nuroute-selfhosted/main/get.sh | bash -s -- --domain <domain>
```

With `--domain` the installer asks nothing. It ends with `NuRoute is running.` A line starting
with `Error:` means it stopped: see the rules above.

To run it again later (it is safe to repeat and never overwrites a secret): `cd ~/nuroute && ./install.sh --domain <domain>`.

### 5. Check it

```bash
cd ~/nuroute && docker compose ps
curl -fsS https://<domain>/health; echo
```

Every service shows `running` (or `healthy`); the `migrate` service has exited with code 0;
`/health` answers `{"status":"ok"}`. If the HTTPS request fails at first, wait a minute: the
certificate is being issued.

### 6. Hand over to the person

Tell the person:

1. Open `https://<domain>/app/setup` in a browser.
2. Activate with the licence key from their NuRoute contract, or start a 14-day trial with a work email.
3. Create the first admin account, then connect a provider under **Providers**.
4. Back up `~/nuroute/.env` somewhere safe outside this server: without it, no backup can be restored.
5. Make a first backup with `cd ~/nuroute && ./backup.sh`.

## Running NuRoute later

Work in `~/nuroute` (the folder with this file).

| Task | Command |
|---|---|
| Status | `docker compose ps` |
| Logs of one service | `docker compose logs --tail 200 <service>` |
| Back up | `./backup.sh` (writes `backups/<date-time>/`) |
| Restore a backup (data written since is lost; ask first) | `./restore.sh backups/<date-time>` |
| Upgrade to a release (backs up first, rolls back by itself if it fails) | `./upgrade.sh <version>`, for example `./upgrade.sh 1.1.0` |
| Password reset link when no mail server is set | `./reset-password.sh <email>` |
| File for NuRoute support (secrets and message content removed; the person reviews and sends it) | `./support-bundle.sh` |

Releases and their notes: https://github.com/NuRoute-ai/nuroute-selfhosted/releases. Read the
notes of every release between the running one (`NUROUTE_VERSION` in `.env`) and the target
before upgrading, and tell the person about anything they must do.
