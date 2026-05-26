# agents

[![CI](https://github.com/gmrdad82/agents/actions/workflows/ci.yml/badge.svg)](https://github.com/gmrdad82/agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A library of `AGENTS.md`-style instruction files for Claude Code and
OpenCode. Each agent is a self-contained Markdown file describing the
conventions, anti-patterns, and verification steps for one topic
(Rails, PostgreSQL, Tailwind, Kamal, security, etc.). `bin/install.sh`
concatenates the agents you want into a single `AGENTS.md` at the root
of your target project, which the tool reads as its prompt for that
repo.

Project-specific overrides live alongside the generated file at
`<project>/docs/EXTRA.md`. The agents defer to it.

## Project status

This is my personal setup. Public so anyone can read it, fork it, or
take ideas from it. I do not promise support. Issues may sit
unanswered. PRs land at my pace and only if they fit how I work. No
SLAs, no commitments. Use freely under the MIT license; expect
nothing in return.

Not affiliated with Anthropic, OpenCode, or any of the named tools.

## Quick start

```bash
# Detect a project's stack and see what's recommended
bin/suggest.sh ~/Dev/my-rails-app

# Install a focused set with an EXTRA.md scaffold
bin/install.sh ~/Dev/my-rails-app \
  --include architect,rails,postgres,redis,reviewer,security,git,github \
  --with-extra-stub

# What's installed in a project?
bin/check.sh ~/Dev/my-rails-app

# Did the source drift since install?
bin/diff.sh ~/Dev/my-rails-app

# Re-sync after editing an agent here
bin/install.sh ~/Dev/my-rails-app --mode update
```

Nothing ever writes outside the target project directory. The library
has no global install step.

## Available agents (24)

| Topic                 | File                     |
| --------------------- | ------------------------ |
| Architect             | `agents/architect.md`    |
| Astro                 | `agents/astro.md`        |
| AI / LLM / embeddings | `agents/ai.md`           |
| ActionCable           | `agents/action-cable.md` |
| Cloudflare            | `agents/cloudflare.md`   |
| Docker                | `agents/docker.md`       |
| Docs (Markdown)       | `agents/docs.md`         |
| Git                   | `agents/git.md`          |
| GitHub                | `agents/github.md`       |
| Kamal (+ deploy)      | `agents/kamal.md`        |
| MCP                   | `agents/mcp.md`          |
| MySQL                 | `agents/mysql.md`        |
| Omarchy               | `agents/omarchy.md`      |
| PostgreSQL            | `agents/postgres.md`     |
| Rails (Ruby + Rails)  | `agents/rails.md`        |
| Redis                 | `agents/redis.md`        |
| Reviewer              | `agents/reviewer.md`     |
| RSpec                 | `agents/rspec.md`        |
| Security              | `agents/security.md`     |
| Shell                 | `agents/shell.md`        |
| Simplifier            | `agents/simplifier.md`   |
| Tailwind              | `agents/tailwind.md`     |
| Turbo                 | `agents/turbo.md`        |
| Voyage AI             | `agents/voyage.md`       |

## Install modes

- **update** (default) — replace existing agent blocks with current
  source, add any new agents from `--include`, regenerate banner + TOC.
  Preserves any hand-written preamble outside the markers.
- **append** — only add agents not already present. Existing blocks
  untouched.
- **override** — rebuild `<project>/AGENTS.md` from scratch.
  Destructive.

## How it works

Each agent file is plain Markdown with a small YAML frontmatter. When
installed, `install.sh` strips the frontmatter, demotes the H1 to an
H2, and wraps the body in invisible marker comments:

```
<!-- agents:begin name=rails sha=<sha256-of-source> -->
## Rails
...
<!-- agents:end name=rails -->
```

Markers let `bin/diff.sh` detect drift between an installed agent and
its source (the `sha=` attribute matches the source file's hash at
install time).

## Project conventions (this repo)

- Edit `agents/<name>.md` once; re-run `bin/install.sh` against every
  project that uses it.
- Markdown wraps at ~80 cols (CI enforces via prettier).
- Bash scripts: `set -euo pipefail`, shellcheck-clean.
- See `AGENTS.md` for the full pipeline + rules; `docs/EXTRA.md` for
  this repo's own overrides.

## CI

`.github/workflows/ci.yml`:

- prettier `--check '**/*.md'`
- shellcheck `bin/**/*.sh`
- `bash -n` on every shell script
- `bin/test/markers_test.sh` — every agent file has the expected shape
- `bin/test/install_smoke_test.sh` — install → diff → update cycle

## License

See `LICENSE`.
