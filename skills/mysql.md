---
name: mysql
description: MySQL / MariaDB schema design, migrations, queries, indexing, performance.
triggers:
  [
    "db/migrate/ with MySQL-specific types",
    "config/database.yml adapter: mysql2",
    "mysql in docker-compose",
  ]
---

# MySQL

## Project context

Read `docs/EXTRA.md` first. It declares the project's MySQL / MariaDB
version, the engine (InnoDB unless stated), default charset and
collation (`utf8mb4` / `utf8mb4_0900_ai_ci` recommended), migration
tool, replica topology, and any sharding or partitioning in use.
Anything declared there overrides the defaults below.

## Conventions

### Schema

- Engine: InnoDB. Never MyISAM for new tables.
- Charset: `utf8mb4`. Collation: `utf8mb4_0900_ai_ci` (MySQL 8) or
  `utf8mb4_unicode_ci` (MariaDB / older MySQL). The legacy `utf8`
  charset is 3-byte and will mangle emoji and 4-byte CJK.
- Primary keys: `bigint unsigned auto_increment`. Avoid UUID v4
  primary keys — random insertion order trashes InnoDB clustered-
  index locality.
- `created_at` / `updated_at` `datetime(6) NOT NULL` on every table
  (the `(6)` gives microsecond precision; Rails uses it by default).
- `NOT NULL` is the default. Nullable columns only when "absent" is
  semantically distinct from "empty".
- Foreign keys explicit with `ON DELETE` action chosen deliberately.
- Indexes on every foreign key, every column used in `WHERE`, every
  prefix of any `ORDER BY`. Composite indexes match the query's
  filter order.
- `enum(...)` only when the value set is closed; adding a value is a
  DDL change. Prefer a small lookup table when the set might evolve.
- `decimal(p, s)` for money. Never `float` / `double`.
- For free-form text, `text` columns (or `mediumtext`, `longtext`).
  Use `varchar(n)` only when the cap matters and is small.

### Migrations

- One migration per concept. Split schema change + backfill + cleanup
  across separate files.
- For tables > 10M rows, use online DDL (`ALTER TABLE ..., ALGORITHM=INPLACE,
LOCK=NONE`) or `gh-ost` / `pt-online-schema-change`.
- Avoid `ADD COLUMN ... AFTER other_col` on hot tables; reorders
  rebuild the whole table.
- Backfills run in batches with a sleep / throttle. Don't run a
  giant `UPDATE` that locks rows for minutes.
- Always test rollback: `bin/rails db:rollback` (Rails) or the
  equivalent in your migration tool.

### Queries

- `EXPLAIN <query>` for anything touching > 10k rows. Read the
  `type` column: `ALL` = full scan, `range` / `ref` / `eq_ref` = OK.
- `EXPLAIN ANALYZE` (MySQL 8.0.18+) for actual runtime.
- Use `STRAIGHT_JOIN` only when the optimizer is provably wrong;
  most "fixes" with it become tech debt as data grows.
- `LIMIT N OFFSET M` paginates badly past a few thousand rows. Use
  keyset pagination (`WHERE id > last_seen_id ORDER BY id LIMIT N`).
- `COUNT(*)` over large InnoDB tables is slow. Cache when possible.

## Anti-patterns

- Don't use the deprecated `utf8` (3-byte) charset.
- Don't use `TIMESTAMP` for arbitrary timestamps — it has a 2038
  problem and surprising auto-update behavior. Use `datetime(6)`.
- Don't store JSON when columns will do. MySQL's `json` type works
  but generates implicit casts and is harder to index than Postgres'
  `jsonb`.
- Don't use `LIKE '%foo%'` on large tables — full table scan.
- Don't grant `ALL PRIVILEGES` on the app user. Grant `SELECT,
INSERT, UPDATE, DELETE` only; run migrations as a separate user.
- Don't ignore `sql_mode`. Set it to `STRICT_TRANS_TABLES,NO_ZERO_DATE,
NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO` minimum.

## Commands / verification

- `mysql -e 'SHOW CREATE TABLE <t>\G'` — full DDL with engine /
  charset.
- `mysql -e 'SHOW INDEX FROM <t>'` — index list with cardinality.
- `mysql -e 'EXPLAIN <query>\G'` — query plan.
- `pt-query-digest` against the slow log to find the worst queries.
- For Rails: `bin/rails db:migrate && bin/rails db:rollback` —
  reversibility check.
- Backup the table before any destructive DDL on production:
  `CREATE TABLE foo_bak LIKE foo; INSERT INTO foo_bak SELECT * FROM foo;`
  (or `mysqldump`).
