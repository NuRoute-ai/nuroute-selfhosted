# Security

## Reporting a vulnerability

Email **security@nuroute.ai**. Please do not open a public issue. We answer within 2 business
days and tell you what we will do about it. Fixes for critical vulnerabilities ship as patch
releases within days, for every release still supported (the last two minor versions, or 12
months).

## Checking the images you run

Every NuRoute image is scanned before release (no critical vulnerability with a fix available,
no secrets) and signed with [cosign](https://docs.sigstore.dev/), keyless: the signature names
the release pipeline that built the image and is recorded in the public Sigstore transparency
log. To check an image yourself:

```bash
cosign verify ghcr.io/nuroute-ai/api-gateway:1.0.0 \
  --certificate-oidc-issuer https://gitlab.com \
  --certificate-identity-regexp '^https://gitlab\.com/amitgupta2108/aiinferencecontrolplane//\.gitlab-ci\.yml@refs/tags/selfhosted-v[0-9]+\.[0-9]+\.[0-9]+$'
```

Each image also carries a signed SBOM (SPDX) per platform, listing every package in it:

```bash
cosign verify-attestation --type spdxjson ghcr.io/nuroute-ai/api-gateway:1.0.0 \
  --certificate-oidc-issuer https://gitlab.com \
  --certificate-identity-regexp '^https://gitlab\.com/amitgupta2108/aiinferencecontrolplane//\.gitlab-ci\.yml@refs/tags/selfhosted-v[0-9]+\.[0-9]+\.[0-9]+$'
```

The SBOM files are also attached to each release on GitHub.

## What leaves your server

Only the licence check-in described in README.md. The routing model and catalog it brings back
are signed with a separate NuRoute key, and every NuRoute service checks that signature before
using them.
