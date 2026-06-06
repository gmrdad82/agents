# agents

[![CI](https://github.com/gmrdad82/agents/actions/workflows/ci.yml/badge.svg)](https://github.com/gmrdad82/agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Two things in one repo:

1. A library of `AGENTS.md`-style **skill** files for Claude Code and
   OpenCode. Each skill is a self-contained Markdown file describing the
   conventions, anti-patterns, and verification steps for one topic
   (Rails, PostgreSQL, Tailwind, Kamal, security, etc.).
   `bin/install-skills.sh` concatenates the skills you want into a single
   `AGENTS.md` at the root of your target project, which the tool reads
   as its prompt for that repo.
2. A small set of **OpenCode TUI agent definitions** under
   `opencode/agent/`. These are interactive agents (mode/color/tools
   frontmatter) you cycle through with TAB inside OpenCode.
   `bin/install-agents.sh` deploys them into your user-level OpenCode
   agent directory.

The two are distinct concepts:

- **skill** = topic-specific instruction fragment. Source under `skills/`.
  Concatenated into per-project `AGENTS.md` by `bin/install-skills.sh`.
- **agent** = OpenCode TUI agent definition. Source under
  `opencode/agent/`. Installed user-level by `bin/install-agents.sh`.

Project-specific overrides for the skill pipeline live alongside the
generated file at `<project>/docs/EXTRA.md`. The skills defer to it.

## Project status

This is my personal setup. Public so anyone can read it, fork it, or
take ideas from it. I do not promise support. Issues may sit
unanswered. PRs land at my pace and only if they fit how I work. No
SLAs, no commitments. Use freely under the MIT license; expect
nothing in return.

Not affiliated with Anthropic, OpenCode, or any of the named tools.

## Quick start — skills (per-project)

```bash
# Detect a project's stack and see what's recommended
bin/suggest-skills.sh ~/Dev/my-rails-app

# Install a focused set with an EXTRA.md scaffold
bin/install-skills.sh ~/Dev/my-rails-app \
  --include architect,rails,postgres,redis,reviewer,security,git,github \
  --with-extra-stub

# What's installed in a project?
bin/check-skills.sh ~/Dev/my-rails-app

# Did the source drift since install?
bin/diff-skills.sh ~/Dev/my-rails-app

# Re-sync after editing a skill here
bin/install-skills.sh ~/Dev/my-rails-app --mode update
```

The skill pipeline writes only inside the target project directory.

## Quick start — OpenCode agents (user-level)

```bash
# See what would be installed and where
bin/install-agents.sh --dry-run

# Snapshot copy (default)
bin/install-agents.sh

# Symlink instead — edits in either location flow through
bin/install-agents.sh --mode link
```

This script writes to `${XDG_CONFIG_HOME:-~/.config}/opencode/agent/` —
the one user-level installer in this repo. OpenCode loads agents from a
fixed per-user path, so there is no per-project install for these.

## Available skills (24)

| Topic                 | File                     |
| --------------------- | ------------------------ |
| Architect             | `skills/architect.md`    |
| Astro                 | `skills/astro.md`        |
| AI / LLM / embeddings | `skills/ai.md`           |
| ActionCable           | `skills/action-cable.md` |
| Cloudflare            | `skills/cloudflare.md`   |
| Docker                | `skills/docker.md`       |
| Docs (Markdown)       | `skills/docs.md`         |
| Git                   | `skills/git.md`          |
| GitHub                | `skills/github.md`       |
| Kamal (+ deploy)      | `skills/kamal.md`        |
| MCP                   | `skills/mcp.md`          |
| MySQL                 | `skills/mysql.md`        |
| Omarchy               | `skills/omarchy.md`      |
| PostgreSQL            | `skills/postgres.md`     |
| Rails (Ruby + Rails)  | `skills/rails.md`        |
| Redis                 | `skills/redis.md`        |
| Reviewer              | `skills/reviewer.md`     |
| RSpec                 | `skills/rspec.md`        |
| Security              | `skills/security.md`     |
| Shell                 | `skills/shell.md`        |
| Simplifier            | `skills/simplifier.md`   |
| Tailwind              | `skills/tailwind.md`     |
| Turbo                 | `skills/turbo.md`        |
| Voyage AI             | `skills/voyage.md`       |

## Available OpenCode agents (2)

| Agent       | File                            |
| ----------- | ------------------------------- |
| plan-author | `opencode/agent/plan-author.md` |
| plan-runner | `opencode/agent/plan-runner.md` |

A coordinated two-agent set for working with atomic-task plan files:
plan-author drafts, audits, and updates plans (gating the sign-off line),
and plan-runner executes them (gated on that sign-off).

## Skill install modes

- **update** (default) — replace existing skill blocks with current
  source, add any new skills from `--include`, regenerate banner + TOC.
  Preserves any hand-written preamble outside the markers.
- **append** — only add skills not already present. Existing blocks
  untouched.
- **override** — rebuild `<project>/AGENTS.md` from scratch.
  Destructive.

## How the skill pipeline works

Each skill file is plain Markdown with a small YAML frontmatter. When
installed, `install-skills.sh` strips the frontmatter, demotes the H1
to an H2, and wraps the body in invisible marker comments:

```
<!-- agents:begin name=rails sha=<sha256-of-source> -->
## Rails
...
<!-- agents:end name=rails -->
```

Markers let `bin/diff-skills.sh` detect drift between an installed
skill and its source (the `sha=` attribute matches the source file's
hash at install time). The marker namespace stays `agents:` (not
`skills:`) because the output file is named `AGENTS.md` and existing
target projects keep working without re-installation.

## Project conventions (this repo)

- Edit `skills/<name>.md` once; re-run `bin/install-skills.sh` against
  every project that uses it.
- Markdown wraps at ~80 cols (CI enforces via prettier).
- Bash scripts: `set -euo pipefail`, shellcheck-clean.
- See `AGENTS.md` for the full pipeline + rules; `docs/EXTRA.md` for
  this repo's own overrides.

## CI

`.github/workflows/ci.yml`:

- prettier `--check '**/*.md'`
- shellcheck `bin/**/*.sh`
- `bash -n` on every shell script
- `bin/test/markers_test.sh` — every skill file has the expected shape
- `bin/test/install_smoke_test.sh` — install → diff → update cycle

## License

See `LICENSE`.
