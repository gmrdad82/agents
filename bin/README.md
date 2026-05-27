# bin

Scripts for managing the AGENTS.md skill install pipeline, plus a
sidecar installer for OpenCode TUI agent definitions. The skill
pipeline writes only inside the target project; `install-agents.sh`
is the exception and writes to a user-level OpenCode directory
(OpenCode loads agents from a fixed path, not per-project).

## Skill pipeline scripts

### `install-skills.sh <path/to/project>`

Concatenate selected skills from `../skills/` into
`<path/to/project>/AGENTS.md`.

```
bin/install-skills.sh <path/to/project>
                      [--include name1,name2,...]
                      [--mode update|append|override]
                      [--dry-run]
                      [--with-extra-stub]
```

Modes:

- **update** (default) — replace existing skill blocks with current
  source, add any new skills from `--include`, regenerate banner +
  TOC. Leaves any non-marker content (custom preamble) untouched.
- **append** — only add skills not already present in
  `<project>/AGENTS.md`. Never overwrites an existing skill block.
- **override** — rebuild `<project>/AGENTS.md` from scratch.
  Destructive.

Flags:

- `--include` — comma-separated skill names. Omitted = install every
  skill in `skills/`.
- `--dry-run` — print the diff (override) or the plan
  (update/append); write nothing.
- `--with-extra-stub` — also scaffold a starter `docs/EXTRA.md` if
  the project doesn't have one.

### `check-skills.sh <path/to/project>`

List skills currently installed in `<project>/AGENTS.md`, one per
line, in install order. Exits 1 if `AGENTS.md` is missing.

### `diff-skills.sh <path/to/project>`

Report drift between `<project>/AGENTS.md` and the master skill set:

- **missing** — in `skills/` but not in `<project>/AGENTS.md`.
- **stale** — in both, but the marker's `sha=` doesn't match the
  current source.
- **orphans** — in `<project>/AGENTS.md` but not in `skills/`.

Exit code 0 if in sync; non-zero otherwise (CI-friendly).

### `suggest-skills.sh <path/to/project>`

Walk the project for known stack markers (Gemfile, package.json,
Cargo.toml, Dockerfile, etc.) and print a recommended `--include`
list. With `--install`, hands the list to `install-skills.sh`. With
`--install --dry-run`, runs install-skills.sh in dry-run mode.

## OpenCode agent installer

### `install-agents.sh`

Install OpenCode TUI agent definitions from `../opencode/agent/` into
the user's OpenCode agent directory (default:
`${XDG_CONFIG_HOME:-~/.config}/opencode/agent`).

```
bin/install-agents.sh [--mode copy|link]
                      [--include name1,name2,...]
                      [--target <dir>]
                      [--dry-run]
```

Modes:

- **copy** (default) — snapshot each agent into the target,
  overwriting any existing file with the same name.
- **link** — symlink each agent from the repo into the target.
  Edits in either location flow through immediately.

Flags:

- `--include` — comma-separated agent names without `.md`. Default:
  all agents in `opencode/agent/`.
- `--target` — override the target directory.
- `--dry-run` — print actions; write nothing.

Scope: unlike the other scripts here, this one writes to a
user-level path. OpenCode loads agents from a fixed directory; there
is no per-project install for these.

## Tests

`bin/test/markers_test.sh` — every `skills/*.md` has the expected
shape (frontmatter, H1, four required sections, name matches
filename).

`bin/test/install_smoke_test.sh` — end-to-end exercise of
install-skills, check-skills, diff-skills, append, update, stale
detection, hand-written refusal, and `--with-extra-stub`. Uses a
throwaway temp dir.

## Conventions

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- shellcheck-clean. Warnings disabled inline only with a comment
  justifying why.
- Each script accepts `-h`/`--help` and prints the header block as
  usage.
- Long flag names (`--include`, `--mode`) over short. Less chance of
  typo-driven breakage.
- Skill scripts write only inside the target project's directory.
  `install-agents.sh` is the one user-level exception.
