---
name: redis
description: Redis as cache, queue, pubsub, rate limiter, session store. Keys, TTLs, persistence.
triggers:
  [
    "REDIS_URL set",
    "redis in docker-compose",
    "sidekiq / resque / good_job dependencies",
    "rails cache_store: redis",
  ]
---

# Redis

## Project context

Read `docs/EXTRA.md` first. It declares the project's Redis version,
deployment shape (single instance vs cluster vs Sentinel), persistence
mode (RDB / AOF / none), eviction policy (`allkeys-lru` for caches,
`noeviction` for data stores), the key namespace prefix, and which
libraries use Redis (Sidekiq, Solid Queue, Rails cache, custom).
Anything declared there overrides the defaults below.

## Conventions

### Keys

- Prefix all keys: `<app>:<scope>:<id>` (e.g., `myapp:session:abc123`,
  `myapp:cache:user:42:profile`). Makes `KEYS` / `SCAN` greppable
  and avoids collisions with other apps sharing the instance.
- Use colons (`:`) as the separator; tooling (RedisInsight, etc.)
  treats them as a hierarchy.
- Keep keys short. `u:42:p` is fine in hot paths if the meaning is
  documented; Redis memory cost is real at scale.
- Every key gets a TTL unless it's authoritative state. Use `EXPIRE`
  / `SETEX` / `SET ... EX`. Untracked permanent keys leak.

### Data types

- **String** — counters (`INCR`), small blobs, simple cache values.
- **Hash** — small structured records (user profile fields). Cheaper
  than N strings if accessed together.
- **List** — queues (`LPUSH` / `BRPOP`), recent-N feeds with `LTRIM`.
- **Set** — unique-membership tests, tag indexes.
- **Sorted set** — leaderboards, time-windowed rate limiters,
  delayed-job schedulers.
- **Stream** — append-only log with consumer groups (durable pub-sub
  alternative).

### Caching

- Read-through with explicit invalidation, not write-through, when
  the source of truth is the DB.
- TTL is your safety net for the inevitable stale-cache bug. Set it.
- For "compute once, share with everyone" patterns, use `SETNX` or
  Redlock to prevent thundering herds.

### Queues

- Sidekiq / equivalent: queue names match priority, not feature
  ("critical", "default", "low"). Wire your worker concurrency
  to the priority you want.
- Idempotent jobs. Network glitches will re-deliver.
- Don't store giant payloads in the job args. Store an ID, fetch in
  the worker.

### Pub/Sub

- Pub/Sub is fire-and-forget. If you need durability or replay, use
  Streams instead.
- Subscriber processes must reconnect on disconnect — connections
  drop silently.

## Anti-patterns

- Don't run `KEYS *` against a production Redis. It blocks the
  server while scanning. Use `SCAN` with a cursor.
- Don't store data you can't afford to lose without RDB or AOF
  persistence configured (and tested — restore from a backup at
  least once).
- Don't use Redis as a long-term database. It's RAM-bound; eviction
  will happen.
- Don't share one Redis instance across cache, queue, and rate-
  limiter without thinking about eviction policy. Caches want
  `allkeys-lru`; queues want `noeviction`.
- Don't store secrets unencrypted in Redis. It's frequently exposed
  to internal-network attackers.

## Commands / verification

- `redis-cli ping` — liveness.
- `redis-cli info memory` — used memory, peak, eviction stats.
- `redis-cli --bigkeys` — find the largest keys (memory hogs).
- `redis-cli --scan --pattern 'myapp:cache:*' | wc -l` — count keys
  matching a pattern without blocking.
- `redis-cli monitor` — tail commands in real time (dev only —
  it slows the server).
- `redis-cli ttl <key>` — sanity-check TTLs in production. Many
  "weird cache bug" reports trace back to a missing TTL.
- `redis-cli config get maxmemory-policy` — confirm the eviction
  policy matches the use case.
