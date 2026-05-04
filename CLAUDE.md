# claude-dotfiles

Personal Claude Code configuration repo. Source-of-truth for agent
definitions, install scripts, commands, and skills used across multiple
projects on the same machine.

## Tech stack

- Bash 5+ for the install / pull scripts.
- Markdown for agent definitions (parsed by Claude Code's agent registry).
- Plain text — no build step, no dependencies, no test framework.

## Layout

- `agents/` — generic agent templates with `{{PREFIX}}` / `{{REPO_NAME}}` /
  `{{REPO_PATH}}` placeholders. One file per agent role.
- `commands/` — slash commands. Empty for now.
- `skills/` — Claude Code skills. Empty for now.
- `bin/`
  - `install.sh` — substitutes placeholders and writes
    `~/.claude/agents/<prefix>-<agent>.md`.
  - `pull.sh` — reverse-substitutes runtime edits back into generic templates.
  - `README.md` — script documentation.
- Root configs: `LICENSE` (proprietary), `README.md` (GitHub overview),
  `.gitignore`, `CLAUDE.md` (this file).

## Workflow rules

- Commit directly to `main` with one-line meaningful messages.
- No branches, no PRs.
- Always pull with `--rebase`.
- Markdown wraps at 80 chars (`prose-wrap: always`). Use
  `prettier --write '**/*.md'` if drift creeps in.
- No Co-Authored-By, no AI authorship mentions, no multi-line commit
  bodies.
- Don't commit until the user has reviewed — agent edits affect every
  project's Claude session.

## Agent design rule — generic templates, project-specific in CLAUDE.md

The agents in `agents/` are intentionally PROJECT-AGNOSTIC. The same
`rails.md` source file produces `pito-rails.md` for one project and
`fepra-rails.md` for another at install time — only the prefix and the
absolute repo path differ.

**Project-specific conventions** (e.g. "use yes/no string booleans at
boundaries", "destructive flows route through ConfirmModalComponent",
"components are ViewComponent-based", etc.) live in the **project's** own
`CLAUDE.md` — NOT in the agent file. Each agent's first instruction is:
"read `{{REPO_PATH}}/CLAUDE.md` and follow its rules before acting."

This separation is what makes ONE set of agents work across multiple
client projects with different conventions. Don't break it by leaking
project-specific text into agent templates.

## Templating model

Three placeholders, substituted at install time by `bin/install.sh`:

| Placeholder     | Substituted with                                  |
| --------------- | ------------------------------------------------- |
| `{{PREFIX}}`    | The prefix arg passed to `install.sh`             |
| `{{REPO_NAME}}` | Same as the prefix (kept distinct for future use) |
| `{{REPO_PATH}}` | `${HOME}/Dev/<prefix>`                            |

`bin/pull.sh` reverse-substitutes ONLY `{{REPO_PATH}}` automatically — the
absolute home path is unambiguous. The `{{PREFIX}}` and `{{REPO_NAME}}`
placeholders are NOT auto-restored on pull because the project name
("pito", "fepra") often appears in branding, identifiers, and comments
that should NOT become placeholders. Hand-review the pull diff.

## Agent roles

Generic source agents in `agents/`:

| Source         | Role                                                       |
| -------------- | ---------------------------------------------------------- |
| `architect.md` | Spec writer + master-agent planner / reviewer / committer. |
| `astro.md`     | Astro landing page (Cloudflare Pages).                     |
| `auditor.md`   | Read-only state auditor — gap analysis, drift checks.      |
| `docs.md`      | Markdown / docs / playbooks / log keeper.                  |
| `mcp.md`       | MCP server tool surface (`mcp` gem).                       |
| `rails.md`     | Rails feature implementation.                              |
| `reviewer.md`  | Pipeline gates + manual playbook author.                   |
| `rust.md`      | Rust crate / CLI / library implementation.                 |
| `security.md`  | Security review pass — sensitive changes only.             |

Every agent is OPT-IN. There are no implicit defaults — `--include` must
list each one explicitly.

## Hard rules

- **Source files stay project-agnostic.** Project-specific conventions
  belong in the target project's `CLAUDE.md`, not in the agent template.
- **Don't commit `~/.claude/agents/<prefix>-*.md` files to a project
  repo.** They belong in this dotfiles repo only. (Project repos that
  must NOT receive agent files include any client work — Fepra, future
  contracts, etc.)
- **Don't push agent edits without reading the diff.** Agents drive every
  Claude session; a broken agent affects every project that uses it.
- **Re-install after agent edits.** When a template changes, run
  `bin/install.sh <prefix> --include <changed-agent>` for every project
  that uses it; otherwise installed copies drift behind the source.

## Configuration

- This repo holds NO secrets. No `.env`, no credentials, no keys.
- `bin/install.sh` reads only the prefix arg + the home path. No env vars,
  no external API calls.
- All paths are absolute; the scripts derive everything from `${HOME}` so
  they're portable across machines.

## Glossary

- **prefix** — the project namespace passed to `install.sh`, e.g. `pito` or
  `fepra`. Becomes the leading filename component in
  `~/.claude/agents/`.
- **runtime location** — `~/.claude/`. Where Claude Code reads agent /
  command / skill definitions at session start.
- **source location** — this repo (`~/Dev/claude-dotfiles/`). Where
  templates live before substitution.
- **opt-in** — every agent must be explicitly listed in `--include` on
  install. Nothing installs by default.
