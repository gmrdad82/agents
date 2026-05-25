# bin

Sync scripts for installing skills from this repo into CodeWhale's runtime
location (`~/.codewhale/skills/`) and mirroring runtime edits back.

## install.sh

Installs templated skills into `~/.codewhale/skills/<prefix>-<name>/SKILL.md`.

```bash
bin/install.sh <prefix> --include <name1>,<name2>,...
```

`--include` is REQUIRED. Nothing installs by default. Every skill must be
listed explicitly so installs are reviewable.

### Flags

| Flag        | Effect                                                                                                 |
| ----------- | ------------------------------------------------------------------------------------------------------ |
| `--include` | Comma-separated skill names to install. Required.                                                      |
| `--dry-run` | Print what would happen without writing.                                                               |
| `--force`   | Overwrite even when `~/.codewhale/` copy is newer than the source. Default refuses (mtime-safe).       |
| `--prune`   | Delete `~/.codewhale/skills/<prefix>-*` directories not in the current `--include` set. Scoped — never touches other prefixes. |

### Examples

Install pito's full skill set:

```bash
bin/install.sh pito --include architect,astro,auditor,docs,mcp,rails,reviewer,rust,security,node,omarchy,postgres,ai
```

Install a Rails project with search:

```bash
bin/install.sh fepra2 --include architect,auditor,docs,postgres,rails,reviewer,security,meilisearch
```

Preview without writing:

```bash
bin/install.sh pito --include rails --dry-run
```

Prune orphans (e.g., after dropping a skill from your --include set):

```bash
bin/install.sh pito --include rails,reviewer --prune
# → deletes pito-architect, pito-rust, etc., keeps pito-rails + pito-reviewer.
```

### Substitutions

Each source `skills/<name>.md` may contain placeholders:

| Placeholder     | Replacement                                           |
| --------------- | ----------------------------------------------------- |
| `{{PREFIX}}`    | The prefix arg, e.g. `pito`                           |
| `{{REPO_NAME}}` | Same as the prefix (kept distinct for future use)     |
| `{{REPO_PATH}}` | `${HOME}/Dev/<prefix>`, e.g. `/home/catalin/Dev/pito` |

The replacement happens via `sed` on the way out — the source file stays
generic; only the installed copy is project-specific.

## pull.sh

Mirrors edits made under `~/.codewhale/skills/<prefix>-*/SKILL.md` back into
`skills/<name>.md` as generic templates.

```bash
bin/pull.sh <prefix>
bin/pull.sh <prefix> --dry-run
```

### What it does

For every `~/.codewhale/skills/<prefix>-<name>/SKILL.md` whose `<name>` is in
the allowlist:

1. Reads the file.
2. Reverse-substitutes `${HOME}/Dev/<prefix>` → `{{REPO_PATH}}`.
3. Writes to `skills/<name>.md`.

### What it does NOT do

- It does NOT auto-substitute `<prefix>` or `<name>` back into `{{PREFIX}}` /
  `{{REPO_NAME}}`. The project name often appears inside branding,
  identifiers, or comments that shouldn't become placeholders. If you want
  the literal string to become a placeholder, edit the source by hand.

- It does NOT merge — it overwrites. Hand-review the diff after pulling so
  any drift specific to one project doesn't silently leak back into the
  generic source.

## Safety properties

- Both scripts are idempotent. Re-running with the same args is a no-op
  (modulo mtime updates).
- `install.sh` never deletes unless `--prune` is explicitly passed, and the
  prune is scoped to the requested prefix only.
- `pull.sh` only touches files whose name matches `<prefix>-<allowed-name>`
  — unrelated files in `~/.codewhale/skills/` (e.g., other projects') are
  left alone.

## Workflow

Edit a generic source (e.g. `skills/rails.md`):

```bash
$EDITOR skills/rails.md
bin/install.sh pito --include rails
bin/install.sh fepra2 --include rails
git add skills/rails.md
git commit -m "Tighten rails skill's RSpec discipline"
git push
```

Edit a per-project copy via runtime edits (writes to `~/.codewhale/skills/`):

```bash
bin/pull.sh pito --dry-run     # preview
bin/pull.sh pito               # write back
git diff skills/                # hand-review
git commit -m "Update from pito's runtime edit"
git push
```
