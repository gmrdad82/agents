---
name: kamal
description: Deploy with Kamal — config, deploy / rollback commands, accessories, secrets, zero-downtime principles.
triggers:
  ["config/deploy.yml present", ".kamal/ directory exists", "Kamal in Gemfile"]
---

# Kamal

## Project context

Read `docs/EXTRA.md` first. It declares the project's Kamal version
(1.x vs 2.x — config schema differs), the registry (Docker Hub,
GHCR, ECR), the hosts and roles, the secret backend (env file,
1Password CLI, Doppler), the accessory list (Postgres, Redis,
Traefik, log shipper), and the project's pre-deploy checklist.
Anything declared there overrides the defaults below.

## Conventions

### General deployment principles

These apply to any deploy tool; Kamal happens to be ours.

- **Immutable artifacts.** Build once, tag with the git SHA, deploy
  that tag. Don't rebuild during deploy.
- **Twelve-factor config.** All env vars set at deploy time, never
  baked into the image.
- **Zero-downtime by default.** Health-check the new container
  before flipping the proxy. Drain in-flight requests on the old
  container.
- **Rollback is one command.** If you can't `kamal rollback <sha>`
  with confidence, the deploy isn't ready.
- **Idempotent.** Re-running deploy with the same config is a no-op.
- **Migrations are separate from app deploy.** Run them as a one-off
  task (`kamal app exec 'bin/rails db:migrate'`) before the new
  release goes live. Two-deploy pattern for backwards-incompatible
  schema changes.

### Kamal config (`config/deploy.yml`)

- `service` and `image` match a single app. One config file per
  app (multi-app deploys: separate config files per service).
- `servers:` grouped by role (`web`, `worker`, `cron`). Each role
  pins its Docker run options.
- `env:` split into `clear:` (non-secret) and `secret:` (loaded from
  the secret backend). Never put secret values in the YAML.
- `accessories:` for stateful services Kamal manages (db, redis).
  In production, accessories are usually managed elsewhere — use
  `accessories:` only for predictable, contained stateful needs
  (e.g., a dev / staging Postgres).
- `proxy:` (Kamal 2) or `traefik:` (Kamal 1) — health-check path
  and timeout must match the app's actual readiness endpoint.
- `builder:` `multiarch: false` if all hosts are the same arch (faster
  builds). `cache:` `type: registry` for CI builds.

### Secrets

- `.kamal/secrets` is the project's secret loader (a shell script
  that emits `KEY=value` lines). Don't commit it with real values.
- Pull from 1Password / Doppler / Vault in the secrets script; the
  script runs locally on the deploying machine and emits env to
  Kamal.
- Rotate secrets without redeploying app code: update the secret
  store, run `kamal env push`, restart with `kamal app restart`.

### Health checks

- `proxy.healthcheck.path` should hit an endpoint that verifies the
  app can reach its dependencies (DB ping, Redis ping). Pure
  `/up` returning 200 won't catch a failed DB connection.
- Timeout > worst-case warmup. A Rails app on first boot can take
  20–40s.

## Anti-patterns

- Don't `kamal deploy` when CI is red. Push the fix first.
- Don't commit Docker images built locally — let CI build for
  reproducibility.
- Don't put secrets in `env: clear:`. They end up in `kamal env`
  output and in `docker inspect`.
- Don't run migrations inside the container's entry point. Migrations
  block boot; the proxy will mark the container unhealthy and roll
  it back.
- Don't deploy on Fridays unless your rollback story is bulletproof.

## Commands / verification

- `kamal setup` — first-time host bootstrap (Docker, network).
- `kamal deploy` — build, push, deploy, health-check, flip proxy.
- `kamal deploy --skip-push` — re-deploy a tag already in the
  registry (rollback to a specific SHA).
- `kamal rollback <sha>` — revert to a prior release.
- `kamal app logs -f` — tail logs across all role hosts.
- `kamal app exec --reuse 'bin/rails console'` — interactive console
  inside a running container.
- `kamal app exec 'bin/rails db:migrate'` — one-off task, no
  container churn.
- `kamal lock status` — check for a stuck deploy lock.
- `kamal lock release` — clear a stuck lock (only after confirming
  no other deploy is in flight).
- Post-deploy: hit the health endpoint from outside; tail logs for
  the first request; verify the version banner / `/up` returns
  the deployed SHA.
