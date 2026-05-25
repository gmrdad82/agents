# agents

Personal CodeWhale skill templates. Source-of-truth for skill definitions,
install scripts, and project-specific extensions used across multiple
projects on the same machine.

## Architecture

A master CodeWhale session orchestrates work by dispatching focused sub-agents
via `agent_open`. Each sub-agent receives a bounded task, executes independently
(often in parallel with siblings), and returns results. This repo provides the
template bodies for those sub-agents — reusable, role-specific instruction sets
that the master adapts per project and dispatches on demand.

The master agent decides which model (deepseek-v4-flash, deepseek-v4-pro, etc.)
to use per sub-agent based on task complexity. No skill template enforces a
specific model.

## Tech stack

- Bash 5+ for the install / pull / suggest scripts.
- Markdown for skill templates with `{{PREFIX}}` / `{{REPO_NAME}}` /
  `{{REPO_PATH}}` placeholders. One file per skill.
- Plain text — no build step, no dependencies, no test framework.

## Layout

- `skills/` — generic skill templates with `{{PREFIX}}` / `{{REPO_NAME}}` /
  `{{REPO_PATH}}` placeholders. One file per role.
- `bin/`
  - `install.sh` — substitutes placeholders and writes each skill as
    `~/.codewhale/skills/<prefix>-<name>/SKILL.md`.
  - `pull.sh` — reverse-substitutes runtime edits back into generic
    `skills/<name>.md` templates.
  - `suggest.sh` — analyses a project repo and recommends which skills
    suit it.
  - `README.md` — script documentation.
- `docs/skills/` — project-specific extension stubs for each skill.
- Root configs: `AGENTS.md` (this file), `README.md` (GitHub overview),
  `.gitignore`, `LICENSE`.

## Workflow rules

- Commit directly to `main` with one-line meaningful messages.
- No branches, no PRs.
- Always pull with `--rebase`.
- Markdown wraps at 80 chars (`prose-wrap: always`). Use
  `prettier --write '**/*.md'` if drift creeps in.
- No Co-Authored-By, no AI authorship mentions, no multi-line commit
  bodies.
- Don't commit until the user has reviewed — skill edits affect every
  project session that uses these templates.

## Skill design rule — generic templates, project-specific in AGENTS.md

The skills in `skills/` are intentionally PROJECT-AGNOSTIC. The same
`rails.md` source file produces `pito-rails` for one project and
`fepra2-rails` for another at install time — only the prefix and the
absolute repo path differ.

**Project-specific conventions** (e.g. "use yes/no string booleans at
boundaries", "destructive flows route through ConfirmModalComponent",
"components are ViewComponent-based", etc.) live in the **project's** own
`AGENTS.md` — NOT in the skill file. Each skill's first instruction is:
"read `{{REPO_PATH}}/AGENTS.md` and follow its rules before acting."

This separation is what makes one set of skills work across multiple
client projects with different conventions. Don't break it by leaking
project-specific text into skill templates.

## Templating model

Three placeholders, substituted at install time by `bin/install.sh`:

| Placeholder     | Substituted with                                  |
| --------------- | ------------------------------------------------- |
| `{{PREFIX}}`    | The prefix arg passed to `install.sh`             |
| `{{REPO_NAME}}` | Same as the prefix (kept distinct for future use) |
| `{{REPO_PATH}}` | `${HOME}/Dev/<prefix>`                            |

`bin/pull.sh` reverse-substitutes only `{{REPO_PATH}}` automatically — the
absolute home path is unambiguous. `{{PREFIX}}` and `{{REPO_NAME}}` are
not auto-restored on pull because the project name ("pito", "fepra2")
often appears inside identifiers, comments, or branding that should not
become placeholders. Hand-review the pull diff.

## Skill roles

| Skill                    | Role                                                           |
| ------------------------ | -------------------------------------------------------------- |
| `ai.md`                  | DeepSeek platform expert — API, SDK, model selection, cost     |
| `architect.md`           | Spec writer — feature specs before implementation              |
| `astro.md`               | Astro landing page (Cloudflare Pages)                          |
| `auditor.md`             | Read-only state auditor — gap analysis, drift checks           |
| `docs.md`                | Documentation keeper — keeps docs in sync with reality         |
| `docker.md`              | Docker — containers, compose, multi-stage builds, CI/CD        |
| `git-precommit-guard.md` | Pre-commit checks — lint, secrets, commit message validation   |
| `mcp.md`                 | MCP server tool surface                                        |
| `meilisearch.md`         | Meilisearch search engine — indexing, queries, configuration   |
| `mysql.md`               | MySQL / MariaDB — schema, migrations, queries, optimisation    |
| `node.md`                | Node.js / TypeScript feature implementation                    |
| `omarchy.md`             | Omarchy Linux system management — Arch, Hyprland, config       |
| `postgres.md`            | Database agent — schema, migrations, queries, optimisation     |
| `rails.md`               | Rails feature implementation (backend / web)                   |
| `redis.md`               | Redis — caching, queues, pub/sub, rate limiting, session store |
| `reviewer.md`            | Code reviewer — pipeline gates + manual test playbooks         |
| `rust.md`                | Rust crate / CLI / library implementation                      |
| `security.md`            | Security analyst — threat review, vulnerability assessment     |
| `voyage.md`              | Voyage AI embeddings — vector search, RAG pipelines            |

Every skill is OPT-IN. There are no implicit defaults — `--include` must
list each one explicitly. `bin/suggest.sh` helps determine which skills
suit a given project based on its tech stack.

## Hard rules

- **Source files stay project-agnostic.** Project-specific conventions
  belong in the target project's `AGENTS.md`, not in the skill template.
- **Don't commit runtime skill files to a project repo.** They belong
  in this dotfiles repo only.
- **Don't push skill edits without reading the diff.** A broken skill
  affects every project that uses it.
- **Re-install after skill edits.** When a template changes, run
  `bin/install.sh <prefix> --include <changed-skill>` for every project
  that uses it; otherwise installed copies drift behind the source.
- **No model enforcement.** The master agent chooses the model per task.
  Skill templates describe what to do, not which model to do it on.

## Configuration

- This repo holds no secrets. No `.env`, no credentials, no keys.
- `bin/install.sh` reads only the prefix arg + the home path. No env
  vars, no external API calls.
- All paths are absolute; the scripts derive everything from `${HOME}`
  so they're portable across machines.

## Glossary

- **prefix** — the project namespace passed to `install.sh`, e.g.
  `pito` or `fepra2`. Becomes the leading directory name in
  `~/.codewhale/skills/`.
- **runtime location** — `~/.codewhale/skills/`. Where CodeWhale
  discovers skills and loads them via `load_skill`.
- **source location** — this repo (`~/Dev/agents/`). Where templates
  live before substitution.
- **opt-in** — every skill must be explicitly listed in `--include` on
  install. Nothing installs by default.
