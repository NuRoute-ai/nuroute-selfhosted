# NuRoute self-hosted

Run NuRoute, the decision layer that picks the right AI model for every request, on your own
server. Your prompts, responses and provider keys stay on your infrastructure.

This repository is the **install kit**: the files and scripts that set NuRoute up. The NuRoute
software itself comes as ready-built container images, licensed under your NuRoute Enterprise
agreement or a 14-day trial.

Full guide: [docs.nuroute.ai/self-hosting](https://docs.nuroute.ai/self-hosting)

## What you need

- A Linux server (x86-64 or ARM) with **4 CPUs, 16 GB memory and 100 GB free disk** at least.
  8 CPUs and 32 GB are recommended.
- **Docker** with the Docker Compose plugin ([install guide](https://docs.docker.com/engine/install/)).
- A **domain name** for NuRoute (for example `nuroute.acme.com`) whose DNS points at the server,
  and ports **80 and 443** open to your users. HTTPS certificates are obtained automatically.
- Outbound HTTPS to `license.nuroute.ai` (licence check-in) and `ghcr.io` (images).
- A **licence key** from your NuRoute contract, or a work email address to start a trial.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/NuRoute-ai/nuroute-selfhosted/main/get.sh | bash -s -- --domain nuroute.acme.com
```

This downloads the latest release of this kit into `./nuroute` and runs its installer.

With an AI coding agent on the server (Claude Code, GitHub Copilot CLI or OpenAI Codex), one
command does it all, including the DNS and server checks; see
[Install with an AI agent](https://docs.nuroute.ai/self-hosting/install-with-ai):

```bash
claude "Install NuRoute self-hosted on this server for the domain nuroute.acme.com. Follow https://raw.githubusercontent.com/NuRoute-ai/nuroute-selfhosted/main/AGENTS.md step by step."
```

Or do it by hand:

```bash
git clone https://github.com/NuRoute-ai/nuroute-selfhosted.git
cd nuroute-selfhosted
./install.sh --domain nuroute.acme.com
```

The installer checks the server, creates `.env` with generated secrets, downloads the images and
starts everything. When it prints "NuRoute is running", open `https://nuroute.acme.com/app/setup`:

1. Paste your licence key, or start a 14-day trial with your work email.
2. Create the first admin account. It owns this install's organization.
3. Invite your team from **Members** (or connect your identity provider for single sign-on under
   **Settings → Single sign-on**), connect your provider keys, and create API keys.

Call the API at `https://nuroute.acme.com/v1/chat/completions` (OpenAI-compatible).

**Back up `.env`.** It holds the keys that encrypt the provider keys in your database; without it a
backup cannot be restored.

## Email

NuRoute does not send email through us. Until you connect your own mail server:

- **Invitations** still work: **Members** shows the invitation link for you to send yourself.
- **Password resets** cannot be emailed: on the server, `./reset-password.sh <email>` prints a
  one-hour reset link to send yourself. Connect your mail server under **Settings → Email
  (SMTP)** so resets and invitations are emailed.

## Backups and upgrades

| Task | Command |
| --- | --- |
| Back up the database and `.env` into `backups/` | `./backup.sh` |
| Restore a backup (everything written since is lost) | `./restore.sh backups/<date-time>` |
| Upgrade to a release (backs up first, rolls back by itself if the release does not start) | `./upgrade.sh 1.1.0` |
| Upgrade a server without internet access (after `docker load` of the release's images) | `./upgrade.sh 1.1.0 --no-pull` |
| Collect status and logs for support (secrets and message content removed) | `./support-bundle.sh` |

Backups hold the PostgreSQL database (users, keys, projects, policies, routing history) and
`.env`. Usage charts and request logs (ClickHouse) are not included. Copy backups off the server.

## What NuRoute sends to us

One check-in every 12 hours to `license.nuroute.ai`: your licence key, a random install ID,
NuRoute's version numbers, the number of requests since the last check-in, and whether its
services are up. **Never** prompts, responses, API keys, user names, emails or costs. Your admins
can see the exact last check-in on **Licence & system**. If the check-in fails, NuRoute keeps
working for 5 days.

The answer brings NuRoute's latest **routing model** and **model catalog** (models, prices and
quality tiers), signed by us. Each NuRoute service checks the signature before using either, and
keeps what it has if anything is wrong. Until the first check-in after activation, NuRoute routes
on a simple length rule.

## Everyday commands

| Task | Command |
| --- | --- |
| See what is running | `docker compose ps` |
| Follow the logs | `docker compose logs -f` |
| Stop / start | `docker compose stop` / `docker compose start` |

## Help

Email support@nuroute.ai. Security reports: security@nuroute.ai (see SECURITY.md, which also
shows how to check that the images you run are the ones we signed).

The files in this repository are MIT-licensed (see LICENSE). The NuRoute software in the images
is proprietary.
