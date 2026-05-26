# bin

Scripts for managing the AGENTS.md install pipeline. All scripts write
only inside their target project; none touch user-level paths.

## Scripts

### `install.sh <path/to/project>`

Concatenate selected agents from `../agents/` into
`<path/to/project>/AGENTS.md`.

```
bin/install.sh <path/to/project>
               [--include name1,name2,...]
               [--mode update|append|override]
               [--dry-run]
               [--with-extra-stub]
```

Modes:

- **update** (default) — replace existing agent blocks with current
  source, add any new agents from `--include`, regenerate banner +
  TOC. Leaves any non-marker content (custom preamble) untouched.
- **append** — only add agents not already present in
  `<project>/AGENTS.md`. Never overwrites an existing agent block.
- **override** — rebuild `<project>/AGENTS.md` from scratch.
  Destructive.

Flags:

- `--include` — comma-separated agent names. Omitted = install every
  agent in `agents/`.
- `--dry-run` — print the diff (override) or the plan
  (update/append); write nothing.
- `--with-extra-stub` — also scaffold a starter `docs/EXTRA.md` if
  the project doesn't have one.

### `check.sh <path/to/project>`

List agents currently installed in `<project>/AGENTS.md`, one per
line, in install order. Exits 1 if `AGENTS.md` is missing.

### `diff.sh <path/to/project>`

Report drift between `<project>/AGENTS.md` and the master agent set:

- **missing** — in `agents/` but not in `<project>/AGENTS.md`.
- **stale** — in both, but the marker's `sha=` doesn't match the
  current source.
- **orphans** — in `<project>/AGENTS.md` but not in `agents/`.

Exit code 0 if in sync; non-zero otherwise (CI-friendly).

### `suggest.sh <path/to/project>`

Walk the project for known stack markers (Gemfile, package.json,
Cargo.toml, Dockerfile, etc.) and print a recommended `--include`
list. With `--install`, hands the list to `install.sh`. With
`--install --dry-run`, runs install.sh in dry-run mode.

## Tests

`bin/test/markers_test.sh` — every `agents/*.md` has the expected
shape (frontmatter, H1, four required sections, name matches
filename).

`bin/test/install_smoke_test.sh` — end-to-end exercise of install,
check, diff, append, update, stale detection, hand-written refusal,
and `--with-extra-stub`. Uses a throwaway temp dir.

## Conventions

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- shellcheck-clean. Warnings disabled inline only with a comment
  justifying why.
- Each script accepts `-h`/`--help` and prints the header block as
  usage.
- Long flag names (`--include`, `--mode`) over short. Less chance of
  typo-driven breakage.
- Never write outside the target project's directory.
