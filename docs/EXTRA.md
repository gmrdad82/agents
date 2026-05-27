# EXTRA.md (this repo)

Project-specific overrides for the skills source repo itself. The
generic skills under `skills/` describe what to do; this file holds
the rules that are specific to maintaining THIS repo.

## Stack

- Bash 5+ scripts under `bin/`.
- Plain Markdown skill files under `skills/`.
- OpenCode TUI agent definitions under `opencode/agent/`.
- No package manager, no build step, no runtime — the repo is its own
  source of truth.

## Conventions

- **Source-of-truth purity.** Skill files in `skills/` are
  project-agnostic. If a rule would only apply to one downstream
  project, it doesn't go here; it goes in that project's own
  `docs/EXTRA.md`.
- **Edit once, propagate.** When you edit `skills/<name>.md`, re-run
  `bin/install-skills.sh <project> --mode update` against each project
  that uses the skill. There is no automatic fan-out.
- **No commits without local tests.** Run
  `bin/test/markers_test.sh` and `bin/test/install_smoke_test.sh`
  before pushing. A broken skill propagates to every project that
  installs from this repo.
- **80-col prose wrap.** Prettier enforces. Code blocks, tables, and
  long URLs are exempt.
- **No Co-Authored-By trailers** on commits unless asked.

## Per-skill overrides

- **reviewer** — when reviewing a change in THIS repo, the quality
  gates are:
  - `npx --yes prettier@latest --check '**/*.md'`
  - `shellcheck bin/**/*.sh`
  - `bash -n` on every shell script
  - `bin/test/markers_test.sh`
  - `bin/test/install_smoke_test.sh`
- **git** — direct commits to `main`. No PR workflow. Pull with
  `--rebase`. Commit subjects under 72 chars, imperative.
- **shell** — every script in `bin/` accepts `-h`/`--help` by echoing
  its header block. Keep that pattern for new scripts.

## Pointers

- `AGENTS.md` — pipeline overview, marker spec, script contracts.
- `bin/README.md` — script reference.
- `.github/workflows/ci.yml` — the canonical list of CI checks.
