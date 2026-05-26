---
name: postgres
description: PostgreSQL schema design, migrations, queries, indexing, performance.
triggers:
  [
    "db/migrate/ with PG-specific types",
    "config/database.yml adapter: postgresql",
    "postgres in docker-compose",
  ]
---

# PostgreSQL

## Project context

Read `docs/EXTRA.md` first. It declares the project's Postgres
version, the migration tool (Rails, sqitch, raw `psql`, Atlas),
extensions in use (uuid-ossp, pgcrypto, pg_trgm, pgvector), the
backup/restore tooling, and the read-replica or primary/standby
layout if any. Anything declared there overrides the defaults below.

## Conventions

### Schema

- Primary keys: `bigint` (Rails default) or UUID v7 if `docs/EXTRA.md`
  specifies. Avoid UUID v4 as a primary key — random insertion order
  fragments B-trees.
- `created_at` / `updated_at` `timestamptz NOT NULL` on every table
  unless there's a reason not to.
- `NOT NULL` is the default. Columns nullable only when "absent" is
  semantically distinct from "empty".
- Foreign keys are explicit (`REFERENCES other(id) ON DELETE ...`).
  Pick the `ON DELETE` action deliberately — `CASCADE`, `RESTRICT`,
  `SET NULL` are all valid; default behavior is rarely right.
- Indexes on every foreign key, every column used in `WHERE`, every
  prefix of any `ORDER BY`. Use partial indexes
  (`WHERE deleted_at IS NULL`) for filtered hot paths.
- `enum` types when the value set is closed and stable. String
  columns with a `CHECK` constraint when the set might evolve.
- Use `text` not `varchar(n)` unless there's a real length cap.
  Postgres treats them identically performance-wise; `text` is more
  flexible.
- `numeric(p, s)` for money. Never `float` / `double precision`.

### Migrations

- One migration per concept. Don't bundle "add table + backfill +
  drop old column" into one file — split for safer review and
  rollback.
- Backfills run separately from schema changes — `add_column NULL`,
  deploy, backfill in a job, then `change_column_null` to `NOT NULL`.
- For tables > 10M rows, build indexes `CONCURRENTLY`
  (`add_index ..., algorithm: :concurrently` in Rails;
  `disable_ddl_transaction!`).
- Lock-sensitive operations (`ALTER TABLE`, `CREATE INDEX`) outside
  business hours when the table is large.
- Never `DROP COLUMN` in the same release that ships the code
  removing its last reader. Two-deploy migration: stop reading, then
  drop next release.

### Queries

- `EXPLAIN (ANALYZE, BUFFERS)` for any query touching > 10k rows.
- Read the plan: Seq Scan on a 50M row table is rarely OK; an Index
  Scan with high "Rows Removed by Filter" suggests a wrong index.
- Use `RETURNING` to avoid a follow-up SELECT after INSERT / UPDATE.
- Prefer set-based operations (`UPDATE ... WHERE`) over row-by-row
  loops.
- `COUNT(*)` over large tables is slow even with indexes. Cache the
  count or use `pg_class.reltuples` for an estimate.

## Anti-patterns

- Don't use `serial` or `bigserial` for new columns — use
  `GENERATED ALWAYS AS IDENTITY` instead (modern, sane defaults).
- Don't store JSON when columns will do. Use `jsonb` only for
  genuinely schema-free data, and index the paths you query.
- Don't loop SQL queries from app code when one query would do.
- Don't `LIKE '%foo%'` without `pg_trgm` + GIN index — full table
  scans every time.
- Don't grant `ALL PRIVILEGES` on the app role. Grant `SELECT,
INSERT, UPDATE, DELETE` and let migrations run as a separate role
  with DDL privileges.

## Commands / verification

- `psql -d <db> -c '\d+ <table>'` — inspect schema, indexes, sizes.
- `psql -d <db> -c '\di+'` — list indexes with bloat info.
- `EXPLAIN (ANALYZE, BUFFERS) <query>;` — runtime stats.
- `pg_dump --schema-only` — diff schema across environments.
- For Rails: `bin/rails db:migrate && bin/rails db:rollback` —
  confirm reversibility before commit.
- Production-like check: run new migrations against a staging copy
  of prod-size data; time them. A migration that takes 30s on dev
  may take 30min on prod.
