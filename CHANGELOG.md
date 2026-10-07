# Changelog

Every NuRoute self-hosted release, newest first. Upgrade with `./upgrade.sh <version>`: it backs
up first and rolls back by itself if the new release does not start.

NuRoute's routing model and model catalog are not tied to releases: your install receives them
with its licence check-in.

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
