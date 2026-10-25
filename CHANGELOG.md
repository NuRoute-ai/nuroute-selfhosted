# Changelog

Every NuRoute self-hosted release, newest first. Upgrade with `./upgrade.sh <version>`: it backs
up first and rolls back by itself if the new release does not start.

NuRoute's routing model and model catalog are not tied to releases: your install receives them
with its licence check-in.

## 1.0.1

Security update. Upgrade with `./upgrade.sh 1.0.1`; nothing else changes.

- Node.js 22.23.4 in every NuRoute image. It fixes CVE-2026-111497, a flaw in Node.js's Brotli decompression that
  can let a crafted compressed response run code, and several TLS and DNS checks (CVE-2026-106069,
  CVE-2026-105482, CVE-2026-106072). In NuRoute it could be reached through a provider endpoint (base URL) that one
  of your admins configured, so only an admin could point NuRoute at a malicious server.
- The images now refuse to build on an older Node.js.
- certifi 2026.10.23 in the routing model's image: it removes root certificates (emSign) that were compromised.

## 1.0.0

First release.

- Everything NuRoute Cloud does except billing: OpenAI-compatible API with routing across your
  providers, projects and API keys, members and roles, policies and PII redaction, prompt
  compression, request logs and usage.
- One-command install with automatic HTTPS, backups, restore, upgrades with automatic rollback,
  and a support bundle with secrets removed.
- Single sign-on with your identity provider over OpenID Connect (Microsoft Entra ID, Okta,
  Google Workspace, Keycloak, Auth0 and others), with an optional "single sign-on only" mode.
- Password reset without a mail server: `./reset-password.sh <email>` prints a one-hour link.
- 14-day trial from the setup screen, or a licence key from your NuRoute contract.
