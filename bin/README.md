# bin

Sync scripts for installing agents from this repo into Claude Code's runtime
location (`~/.claude/`) and mirroring runtime edits back.

## install.sh

Installs templated agents into `~/.claude/agents/<prefix>-<name>.md`.

```bash
bin/install.sh <prefix> --include <name1>,<name2>,...
```

`--include` is REQUIRED. Nothing installs by default. Every agent must be
listed explicitly so installs are reviewable.

### Flags

| Flag        | Effect                                                                                                                           |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `--include` | Comma-separated agent names to install. Required.                                                                                |
| `--dry-run` | Print what would happen without writing.                                                                                         |
| `--force`   | Overwrite even when `~/.claude/` copy is newer than the source. Default refuses (mtime-safe).                                    |
| `--prune`   | Delete `~/.claude/agents/<prefix>-*.md` files that aren't in the current `--include` set. Scoped — never touches other prefixes. |

### Examples

Install pito's full agent set:

```bash
bin/install.sh pito --include architect,astro,auditor,docs,mcp,rails,reviewer,rust,security
```

Install fepra's Rails-only set:

```bash
bin/install.sh fepra --include architect,auditor,docs,rails,reviewer,security
```

Preview without writing:

```bash
bin/install.sh pito --include rails --dry-run
```

Prune orphans (e.g., after dropping an agent from your --include set):

```bash
bin/install.sh pito --include rails,reviewer --prune
# → deletes pito-architect.md, pito-mcp.md, etc., keeps pito-rails.md +
#   pito-reviewer.md.
```

### Substitutions

Each source `agents/<name>.md` may contain placeholders:

| Placeholder     | Replacement                                           |
| --------------- | ----------------------------------------------------- |
| `{{PREFIX}}`    | The prefix arg, e.g. `pito`                           |
| `{{REPO_NAME}}` | Same as the prefix (kept distinct for future use)     |
| `{{REPO_PATH}}` | `${HOME}/Dev/<prefix>`, e.g. `/home/catalin/Dev/pito` |

The replacement happens via `sed` on the way out — the source file stays
generic; only the installed copy is project-specific.

## pull.sh

Mirrors edits made under `~/.claude/agents/<prefix>-*.md` back into
`agents/<name>.md` as generic templates.

```bash
bin/pull.sh <prefix>
bin/pull.sh <prefix> --dry-run
```

### What it does

For every `~/.claude/agents/<prefix>-<name>.md` whose `<name>` is in the
allowlist:

1. Reads the file.
2. Reverse-substitutes `${HOME}/Dev/<prefix>` → `{{REPO_PATH}}`.
3. Writes to `agents/<name>.md`.

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
- `pull.sh` only touches files whose name matches `<prefix>-<allowed-name>.md`
  — unrelated files in `~/.claude/agents/` (e.g., other projects', or
  user-installed agents from other sources) are left alone.

## Workflow

Edit a generic source (e.g. `agents/rails.md`):

```bash
$EDITOR agents/rails.md
bin/install.sh pito --include rails
bin/install.sh fepra --include rails
git add agents/rails.md
git commit -m "Tighten rails agent's RSpec discipline"
git push
```

Edit a per-project copy via the Claude Code UI (writes to `~/.claude/`):

```bash
bin/pull.sh pito --dry-run     # preview
bin/pull.sh pito               # write back
git diff agents/                # hand-review
git commit -m "Update from pito's runtime edit"
git push
```
