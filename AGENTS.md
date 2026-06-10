# agents

Source-of-truth for the AGENTS.md instruction set used across projects.
Each `skills/<name>.md` is a self-contained, project-agnostic skill
definition that both Claude Code and OpenCode can read.

`CLAUDE.md` contains the plan-author and plan-runner instructions for
this repo's own Claude Code sessions.

Project-specific conventions for THIS repo live in `docs/EXTRA.md`.
The skills defer to it.

## Layout

```
skills/                  24 source skills — project-agnostic instructions
CLAUDE.md                plan-author + plan-runner instructions
docs/EXTRA.md            this repo's own project-specific overrides
.github/workflows/ci.yml prettier markdown check
```

## Skill file shape

Every `skills/*.md` follows the same template:

```markdown
---
name: <skill-name>
description: <one-liner>
triggers: [<patterns>]
---

# <Title>

## Project context

Read `docs/EXTRA.md` first. ...

## Conventions

- ...

## Anti-patterns

- ...

## Commands / verification

- ...
```

The "Project context" section is the contract that keeps generic skills useful
across projects: anything declared in `docs/EXTRA.md` wins over defaults stated
in the skill body.

## Conventions for editing this repo

- One skill per file under `skills/`. Filename = name in frontmatter.
- All four required sections must be present.
- Markdown wraps at ~80 cols for prose (prettier enforced in CI).
- Source skill files are project-agnostic. Anything project-specific belongs
  in the target project's `docs/EXTRA.md`, NOT in the skill source.

## Hard rules

1. Source files stay project-agnostic. Project-specific conventions belong in
   the target project's `docs/EXTRA.md`, not in `skills/`.
2. Don't push skill edits without re-reading the diff. A broken skill
   propagates to every project that uses it.

## Glossary

- **skill** — one `.md` file under `skills/`, describing a coherent topic or
  role.
- **target project** — any repo where you want skills installed.
- **EXTRA** — `docs/EXTRA.md` in a target project; holds the project-specific
  overrides the generic skills defer to.
