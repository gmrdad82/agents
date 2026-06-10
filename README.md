# agents

[![CI](https://github.com/gmrdad82/agents/actions/workflows/ci.yml/badge.svg)](https://github.com/gmrdad82/agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A library of `AGENTS.md`-style **skill** files for Claude Code and OpenCode.
Each skill is a self-contained Markdown file describing the conventions,
anti-patterns, and verification steps for one topic (Rails, PostgreSQL,
Tailwind, Kamal, security, etc.).

`CLAUDE.md` at the repo root contains the **plan-author** and **plan-runner**
instructions — two collaborative modes for drafting, auditing, and executing
atomic-task plan files.

## Project status

This is my personal setup. Public so anyone can read it, fork it, or take ideas
from it. I do not promise support. Issues may sit unanswered. PRs land at my
pace and only if they fit how I work. No SLAs, no commitments. Use freely under
the MIT license; expect nothing in return.

Not affiliated with Anthropic, OpenCode, or any of the named tools.

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

## Project conventions

- One skill per file under `skills/`. Filename = name in frontmatter.
- Markdown wraps at ~80 cols (CI enforces via prettier).
- See `AGENTS.md` for this repo's own conventions; `docs/EXTRA.md` for
  project-specific overrides.

## CI

`.github/workflows/ci.yml`:

- prettier `--check '**/*.md'`

## License

See `LICENSE`.
