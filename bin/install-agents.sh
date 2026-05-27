#!/usr/bin/env bash
# install-agents.sh — install OpenCode agent definitions into the user's
# OpenCode agent directory (default: ~/.config/opencode/agent/).
#
# Usage:
#   bin/install-agents.sh [--mode copy|link]
#                           [--include name1,name2,...]
#                           [--target <dir>]
#                           [--dry-run]
#                           [-h|--help]
#
# Modes:
#   copy  (default) — copy each agent .md into the target, overwriting any
#                     existing file with the same name.
#   link            — symlink each agent .md from the repo into the target.
#                     Edits in either location flow through immediately; no
#                     re-install needed after editing the source.
#
# Flags:
#   --include   — comma-separated agent names without .md (e.g.
#                 "plan-runner,plan-author"). Omitted = all agents in
#                 opencode/agent/.
#   --target    — override the target directory. Default:
#                 ${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agent
#   --dry-run   — print what would happen; write nothing.
#
# Scope note: unlike bin/install-skills.sh, this script writes to a
# user-level location. OpenCode loads agents only from a fixed per-user
# directory; there is no per-project install for these.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/opencode/agent"
DEFAULT_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agent"

MODE="copy"
INCLUDE=""
TARGET="$DEFAULT_TARGET"
DRY_RUN=0

usage() {
  cat <<'EOF'
install-agents.sh — install OpenCode agent definitions into the user's
OpenCode agent directory.

Usage:
  bin/install-agents.sh [--mode copy|link]
                          [--include name1,name2,...]
                          [--target <dir>]
                          [--dry-run]
                          [-h|--help]

Modes:
  copy   (default)  copy each agent .md into the target, overwriting.
  link              symlink each agent from the repo into the target.

Flags:
  --include   comma-separated agent names (without .md). Default: all.
  --target    override the target directory. Default:
              ${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agent
  --dry-run   print actions; write nothing.
EOF
}

die() { echo "error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)     MODE="${2:-}"; shift 2 ;;
    --include)  INCLUDE="${2:-}"; shift 2 ;;
    --target)   TARGET="${2:-}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)          die "unknown argument: $1 (try --help)" ;;
  esac
done

case "$MODE" in
  copy|link) ;;
  *) die "invalid --mode: $MODE (expected: copy | link)" ;;
esac

[[ -d "$SOURCE_DIR" ]] || die "source directory not found: $SOURCE_DIR"

declare -a NAMES=()
if [[ -n "$INCLUDE" ]]; then
  IFS=',' read -r -a NAMES <<< "$INCLUDE"
else
  while IFS= read -r -d '' f; do
    NAMES+=("$(basename "$f" .md)")
  done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
fi

[[ ${#NAMES[@]} -gt 0 ]] || die "no agents to install"

for n in "${NAMES[@]}"; do
  [[ -f "$SOURCE_DIR/$n.md" ]] || die "agent not found in source: $n.md"
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "would install ${#NAMES[@]} agent(s) → $TARGET (mode: $MODE)" >&2
  for n in "${NAMES[@]}"; do
    src="$SOURCE_DIR/$n.md"
    dst="$TARGET/$n.md"
    if [[ "$MODE" == "link" ]]; then
      printf '  link  %s → %s\n' "$dst" "$src" >&2
    else
      printf '  copy  %s → %s\n' "$src" "$dst" >&2
    fi
  done
  exit 0
fi

mkdir -p "$TARGET"

for n in "${NAMES[@]}"; do
  src="$SOURCE_DIR/$n.md"
  dst="$TARGET/$n.md"
  case "$MODE" in
    copy)
      cp -f "$src" "$dst"
      ;;
    link)
      rm -f "$dst"
      ln -s "$src" "$dst"
      ;;
  esac
done

echo "installed ${#NAMES[@]} agent(s) into $TARGET (mode: $MODE)" >&2
