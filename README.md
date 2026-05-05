# claude-dotfiles

Personal Claude Code configuration — agents, commands, skills, and install
scripts that source-track my Claude workflow across projects.

The agent definitions in `agents/` are generic templates with `{{PREFIX}}` /
`{{REPO_NAME}}` / `{{REPO_PATH}}` placeholders. The install script substitutes
those at install-time and writes prefixed copies to `~/.claude/agents/` so
multiple projects can coexist on the same machine without name collisions.

## Layout

```
agents/         generic agent templates (rails.md, mcp.md, reviewer.md, …)
commands/       slash commands (empty for now)
skills/         Claude Code skills (empty for now)
bin/
  install.sh    install agents into ~/.claude/ for a given project
  pull.sh       mirror ~/.claude/<prefix>-*.md back into agents/ as templates
  README.md     script details
LICENSE         proprietary, all rights reserved
```

## Quick start

Every agent is opt-in. Nothing is implied — list each one explicitly via
`--include` so installs are explicit and reviewable.

Install pito's full agent set (the most advanced project — Rails + Rust +
MCP + Astro):

```bash
bin/install.sh pito --include architect,auditor,docs,mcp,rails,reviewer,rust,security,astro
```

Install fepra's set (Rails-only client project, no Rust / MCP / Astro, with Jira workflow):

```bash
bin/install.sh fepra --include architect,auditor,docs,jira,rails,reviewer,security
```

Both runs target `~/.claude/agents/` with the prefix prepended:

- `~/.claude/agents/pito-rails.md`, `pito-mcp.md`, `pito-rust.md`, …
- `~/.claude/agents/fepra-rails.md`, `fepra-docs.md`, …

Restart Claude Code after install so the new agent registry is picked up.

## Update workflow

Edit a generic source file (e.g. `agents/rails.md`) once. Then re-install for
each project that uses it:

```bash
bin/install.sh pito --include rails
bin/install.sh fepra --include rails
```

Both projects pick up the change. Commit + push the dotfiles repo so other
machines sync.

If an agent file is edited via the Claude Code UI (which writes to
`~/.claude/agents/<prefix>-<agent>.md` directly), `bin/pull.sh` reverse-templates
that change back into the generic source.

## Agent catalog

Generic source agents — each one applies a single role across projects.
Project-specific behaviour comes from the project's own `CLAUDE.md`, NOT from
the agent file.

| Source         | Role                                                      |
| -------------- | --------------------------------------------------------- |
| `architect.md` | Spec writer + master-agent planner / reviewer / committer |
| `astro.md`     | Astro landing page (Cloudflare Pages)                     |
| `auditor.md`   | Read-only state auditor — gap analysis, drift checks      |
| `docs.md`      | Markdown / docs / playbooks / log keeper                  |
| `jira.md`      | Jira workflow — timer, transitions, worklogs, comments    |
| `mcp.md`       | MCP server tool surface                                   |
| `rails.md`     | Rails feature implementation                              |
| `reviewer.md`  | Pipeline gates + manual playbook author                   |
| `rust.md`      | Rust crate / CLI / library implementation                 |
| `security.md`  | Security review pass — sensitive changes only             |

## Project-specific rules live in the project's CLAUDE.md

The agents are intentionally project-agnostic. Conventions like "yes/no string
booleans at boundaries" or "use ConfirmModalComponent for confirmations" live
in the project's own `CLAUDE.md` (or referenced docs under `docs/`). Each
agent's first instruction is "read `{{REPO_PATH}}/CLAUDE.md` and follow its
rules before acting."

## Source of truth

- Edit agents here, then `install.sh` to propagate.
- Don't edit `~/.claude/agents/<prefix>-*.md` directly long-term — they're
  regenerated on every install. Use `pull.sh` to mirror back ad-hoc edits.
- Commit + push every meaningful change so other machines stay in sync.
