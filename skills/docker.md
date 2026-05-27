---
name: docker
description: Dockerfile, compose, multi-stage builds, image hardening, registry / CI integration.
triggers:
  [
    "Dockerfile present",
    "docker-compose.yml / compose.yml present",
    ".dockerignore present",
  ]
---

# Docker

## Project context

Read `docs/EXTRA.md` first. It declares the project's base image
strategy (distroless, Alpine, Debian-slim, official Ruby/Node),
multi-arch requirements (amd64-only vs arm64 too), the registry
(Docker Hub, GHCR, ECR), the secret-injection mechanism (BuildKit
secrets, build args, none), and any compliance requirements
(non-root, no shell, SBOM attestation). Anything declared there
overrides the defaults below.

## Conventions

### Dockerfile

- Pin base image by digest, not tag (`FROM ruby:3.3.5-slim@sha256:...`).
  Tags are mutable; digests are not.
- Multi-stage builds: a heavy `builder` stage with build deps, a
  lean `runtime` stage with only the runtime artifacts. Keeps the
  final image small and free of compilers.
- Order layers cheapest-to-change first: base image, system packages,
  language runtime, dependency manifests (Gemfile.lock,
  package-lock.json), then `bundle install` / `npm ci`, then app
  code. Maximizes cache hits.
- Use `--mount=type=cache` for package managers
  (`--mount=type=cache,id=bundle,target=/usr/local/bundle/cache`)
  to keep download caches across rebuilds.
- Run as non-root. `RUN useradd -m -u 1000 app && chown -R app /app`
  → `USER app`.
- `EXPOSE` declares the port; doesn't open it. Document, don't rely.
- `HEALTHCHECK` for long-running services. Match the orchestrator's
  expectations (compose, Kubernetes probe, Kamal `healthcheck.path`).
- `ENTRYPOINT` is the binary; `CMD` is the default args. Use them in
  exec form (`["bin/rails", "server"]`), not shell form
  (`bin/rails server`) — shell form spawns a `/bin/sh` you don't want
  signals routed through.

### .dockerignore

- Mirror `.gitignore` plus dev-only files (`tmp/`, `log/`, `node_modules/`,
  `.git/`, `coverage/`, `*.sqlite3`, `*.env*`). A leaky build context
  is slow AND leaks secrets.
- Verify: `docker build --no-cache --progress=plain . 2>&1 | head -50`
  shows what got sent.

### Compose

- One `compose.yml` for local dev. Use `compose.override.yml` for
  local-only tweaks (mounted source, debugger ports). Use
  `compose.prod.yml` only if it mirrors a real prod target — most
  projects deploy prod some other way.
- Named volumes for stateful services (`db_data:`). Bind mounts for
  source code (live edit) only in dev.
- Health checks on services that have dependents:
  `depends_on: { db: { condition: service_healthy } }`.
- `restart: unless-stopped` for services you want to survive host
  reboots; `restart: no` for one-shot tasks.

### Secrets

- BuildKit secrets at build time: `RUN --mount=type=secret,id=npmrc
cat /run/secrets/npmrc`. Never `COPY` a secret into a layer.
- Runtime secrets via env vars (`environment:` or `env_file:`) in
  compose, via `--env-file` for `docker run`, via the orchestrator's
  secret store in prod (Kamal `.kamal/secrets`, K8s Secrets).
- Never `--build-arg PASSWORD=...` for secrets. ARGs end up in
  `docker history`.

### Images

- Aim for < 200MB final images for app services. Above that, audit:
  build deps left in runtime, unminified frontend assets, cache
  directories.
- Tag with the git SHA AND a moving tag (`latest`, `staging`,
  `production`). Deploy by SHA; promote moving tags after deploy
  succeeds.
- Push to a registry the deploy target can pull from — pre-deploy
  pulls fail more often than builds do.

## Anti-patterns

- Don't run `apt-get update` without `apt-get install -y --no-install-recommends`
  in the same `RUN`, with `&& rm -rf /var/lib/apt/lists/*` at the
  end. Otherwise the cache bloats the image.
- Don't `ADD` when `COPY` suffices. `ADD` does URL fetches and tar
  extraction, both rarely what you want.
- Don't `chmod 777` to "fix" permissions. Set the right UID
  ownership in the COPY (`COPY --chown=app:app`).
- Don't ignore the build-context size. A 500MB context (because
  `.dockerignore` is missing `node_modules/`) means every build
  uploads 500MB.
- Don't run `docker system prune -af --volumes` reflexively — it
  nukes named volumes (data).

## Commands / verification

- `docker build --progress=plain -t myapp:dev .` — verbose build
  log; spot the slow layer.
- `docker image ls myapp` — final image size.
- `docker history myapp:dev` — per-layer size and command. Find the
  bloated layer.
- `docker scout cves myapp:dev` (or `trivy image myapp:dev`) — CVE
  scan. Critical / high warrant action.
- `docker compose config` — render the effective compose with all
  overrides applied; sanity check.
- `dive myapp:dev` (third-party) — interactive layer-by-layer image
  explorer. Worth the install for build optimization.
