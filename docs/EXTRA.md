# EXTRA.md (this repo)

Project-specific overrides for the skills source repo itself. The generic
skills under `skills/` describe what to do; this file holds the rules that are
specific to maintaining THIS repo.

## Stack

- Plain Markdown skill files under `skills/`.
- No package manager, no build step, no runtime — the repo is its own source
  of truth.

## Conventions

- **Source-of-truth purity.** Skill files in `skills/` are project-agnostic.
  If a rule would only apply to one downstream project, it doesn't go here; it
  goes in that project's own `docs/EXTRA.md`.
- **80-col prose wrap.** Prettier enforces. Code blocks, tables, and long URLs
  are exempt.
- **No Co-Authored-By trailers** on commits unless asked.

## Per-skill overrides

- **reviewer** — when reviewing a change in THIS repo, the quality gate is:
  - `npx --yes prettier@latest --check '**/*.md'`
- **git** — direct commits to `main`. No PR workflow. Pull with `--rebase`.
  Commit subjects under 72 chars, imperative.

## Pointers

- `AGENTS.md` — repo overview and skill conventions.
- `CLAUDE.md` — plan-author and plan-runner instructions.
- `.github/workflows/ci.yml` — the canonical list of CI checks.
