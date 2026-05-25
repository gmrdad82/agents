# agents

Personal CodeWhale skill templates — reusable, role-specific instruction sets
for the CodeWhale sub-agent dispatch pattern.

A master CodeWhale session orchestrates by dispatching focused sub-agents
via `agent_open`. Each sub-agent receives a bounded task (the skill body),
executes independently (often in parallel with siblings), and returns results.
The master chooses the model per task — skill templates never enforce one.

## Layout

```
skills/         generic skill templates (rails.md, rust.md, reviewer.md, …)
bin/
  install.sh    install skills into ~/.codewhale/skills/ for a given prefix
  pull.sh       mirror ~/.codewhale/skills/ back into skills/ as templates
  suggest.sh    analyse a repo and recommend suitable skills
  README.md     script details
docs/skills/    project-specific overrides for each skill
LICENSE         proprietary, all rights reserved
```

## Quick start

Every skill is opt-in. Nothing is implied — list each one explicitly via
`--include` so installs are explicit and reviewable.

Install pito's full skill set:

```bash
bin/install.sh pito --include architect,astro,auditor,docs,mcp,rails,reviewer,rust,security,node,omarchy,postgres,ai
```

Install a Rails project with search:

```bash
bin/install.sh fepra2 --include architect,auditor,docs,postgres,rails,reviewer,security,meilisearch
```

Skills are then discoverable by CodeWhale and loadable via `load_skill`.

## Update workflow

Edit a generic source file (e.g. `skills/rails.md`) once. Then re-install for
each project that uses it:

```bash
bin/install.sh pito --include rails
bin/install.sh fepra2 --include rails
```

Both projects pick up the change. Commit + push so other machines sync.

If a skill file is edited via runtime (which writes to
`~/.codewhale/skills/<prefix>-<name>/SKILL.md` directly), `bin/pull.sh`
reverse-templates that change back into the generic source.

## Skill catalog

Generic source skills — each one applies a single role across projects.
Project-specific behaviour comes from the project's own `AGENTS.md`, NOT from
the skill file.

| Skill                     | Role                                                             |
| ------------------------- | ---------------------------------------------------------------- |
| `ai.md`                   | DeepSeek platform expert — API, SDK, model selection, cost       |
| `architect.md`            | Spec writer — feature specs before implementation                |
| `astro.md`                | Astro landing page (Cloudflare Pages)                            |
| `auditor.md`              | Read-only state auditor — gap analysis, drift checks             |
| `docs.md`                 | Documentation keeper — keeps docs in sync with reality           |
| `docker.md`               | Docker — containers, compose, multi-stage builds, CI/CD          |
| `git-precommit-guard.md`  | Pre-commit checks — lint, secrets, commit message validation     |
| `mcp.md`                  | MCP server tool surface                                          |
| `meilisearch.md`          | Meilisearch search engine — indexing, queries, configuration     |
| `mysql.md`                | MySQL / MariaDB — schema, migrations, queries, optimisation      |
| `node.md`                 | Node.js / TypeScript feature implementation                      |
| `omarchy.md`              | Omarchy Linux system management — Arch, Hyprland, config         |
| `postgres.md`             | Database agent — schema, migrations, queries, optimisation       |
| `rails.md`                | Rails feature implementation (backend / web)                     |
| `redis.md`                | Redis — caching, queues, pub/sub, rate limiting, session store   |
| `reviewer.md`             | Code reviewer — pipeline gates + manual test playbooks           |
| `rust.md`                 | Rust crate / CLI / library implementation                        |
| `security.md`             | Security analyst — threat review, vulnerability assessment       |
| `voyage.md`               | Voyage AI embeddings — vector search, RAG pipelines              |

## Project-specific rules live in the project's AGENTS.md

The skills are intentionally project-agnostic. Conventions like "use yes/no
string booleans at boundaries" or "destructive flows route through
ConfirmModalComponent" live in the project's own `AGENTS.md` (or referenced
docs under `docs/skills/`). Each skill's first instruction is "read
`{{REPO_PATH}}/AGENTS.md` and follow its rules before acting."

## Source of truth

- Edit skills here, then `install.sh` to propagate.
- Don't edit `~/.codewhale/skills/` directly long-term — they're regenerated
  on every install. Use `pull.sh` to mirror back ad-hoc edits.
- Commit + push every meaningful change so other machines stay in sync.
