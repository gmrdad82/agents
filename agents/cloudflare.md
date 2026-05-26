---
name: cloudflare
description: Cloudflare — DNS, Workers, Pages, R2, Tunnel, page rules, caching.
triggers:
  [
    "wrangler.toml / wrangler.jsonc present",
    "cloudflared in use",
    "DNS zone managed in Cloudflare",
  ]
---

# Cloudflare

## Project context

Read `docs/EXTRA.md` first. It declares the zone(s), the project's
Workers / Pages projects, the R2 buckets, any Cloudflare Tunnels in
use, the DNS provider (Cloudflare-only vs Cloudflare-in-front-of-
other), the SSL/TLS mode (Full strict, recommended), and any custom
firewall / WAF rules. Anything declared there overrides the defaults
below.

## Conventions

### DNS

- Proxied (orange cloud) for any record serving HTTP/S to end users
  — gets you DDoS protection, caching, TLS termination.
- Unproxied (grey cloud) for service records (MX, SRV), origin-
  access records that must point at the real IP, and anything that
  doesn't speak HTTP.
- TTL: 1 (Auto) for proxied records; 5 minutes for unproxied unless
  the record is genuinely static.
- One DNS source of truth. If using Terraform / OpenTofu / Pulumi,
  no manual dashboard edits — the next `apply` reverts them.

### Workers

- One Worker per concern. Don't pack unrelated routes into one
  Worker — deploy blast radius widens with each addition.
- Bindings (KV, R2, D1, Durable Objects, Secrets) declared in
  `wrangler.toml`. Don't fetch URLs by hand when you can bind.
- Secrets via `wrangler secret put`, never in `wrangler.toml`. The
  TOML is committed; secrets are not.
- Routes vs custom domains:
  - Routes for path-pattern dispatch on an existing zone.
  - Custom domains for clean root/subdomain mapping. Custom domain
    Workers get a full TLS cert and don't need a separate DNS
    record.
- Local dev: `wrangler dev --local --persist` for KV / R2 / D1
  state that survives restarts.
- CI deploy: `wrangler deploy --env <env>` from a workflow with a
  scoped API token (Workers Scripts: Edit, Account: Read).
- Tail logs: `wrangler tail` in production to see real requests.
  Don't leave it running — it impacts performance modestly at high
  RPS.

### Pages

- Build command and output dir declared in dashboard or
  `wrangler.toml` (Pages Functions). Keep them in sync with the
  framework's defaults.
- Preview deployments per PR are on by default; use them as the
  staging surface.
- Functions in `functions/` directory get auto-routed by file path
  (`functions/api/[id].ts` → `/api/:id`). Don't fight the routing
  convention.

### R2

- Bucket per environment (`myapp-prod-uploads`, `myapp-staging-uploads`).
- Public access via custom domain or via Worker — never enable
  public-bucket without an auth layer if the content isn't truly
  public.
- Versioning OFF unless explicitly needed; storage cost adds up.
- Lifecycle rules to expire temp uploads; orphaned blobs accumulate
  forever otherwise.

### Tunnel (cloudflared)

- One named tunnel per host. The cred file (`~/.cloudflared/<uuid>.json`)
  is a credential — treat like a private key.
- Configure routes in `~/.cloudflared/config.yml` and bind them in
  the dashboard (or `cloudflared tunnel route dns <tunnel> <host>`).
- Run as a system service (systemd, launchd), not in a tmux session
  you'll forget about.

### Caching

- Static assets: long `Cache-Control` (1y), versioned filenames
  (`app.<hash>.js`).
- HTML: short cache (5 min), or `no-store` if the page is per-user.
- Use Cache Rules (zone level) over Page Rules (legacy). Tier 1
  cache hit ratio is the metric to watch.

## Anti-patterns

- Don't trust the `cf-connecting-ip` header server-side without
  also restricting your origin to Cloudflare's IP ranges. Otherwise
  attackers can spoof it by going direct.
- Don't use Cloudflare's "Always Online" feature for transactional
  apps — it serves stale cache; users will submit forms against
  outdated CSRF tokens.
- Don't `wrangler deploy` without `--env`. The default environment
  is rarely what you want.
- Don't store user-uploaded HTML in R2 served from the same origin
  as your app — XSS via direct R2 URLs.
- Don't enable the WAF's "Bot Fight Mode" without testing — it
  blocks legitimate API consumers and webhook senders.

## Commands / verification

- `wrangler whoami` — confirm the account / token in use.
- `wrangler dev --remote` — run against real Cloudflare bindings
  (KV reads/writes hit production data — careful).
- `wrangler tail --format pretty` — live request logs.
- `wrangler deployments list` — recent deploys with versions.
- `wrangler rollback <id>` — revert to a prior deployment.
- `dig +short <host>` — confirm DNS resolution.
- `curl -I https://<host>` — confirm `cf-ray` header (proves
  proxied) and `cf-cache-status` (HIT/MISS/EXPIRED).
- `cloudflared tunnel info <name>` — connections + ingress rules.
- Cloudflare dashboard → Analytics → Security: review WAF blocks
  weekly; whitelist false positives.
