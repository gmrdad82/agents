#!/usr/bin/env bash
#
# pull.sh — mirror ~/.claude/agents/<prefix>-*.md back into agents/ as
# generic templates with the {{REPO_PATH}} placeholder restored.
#
# Usage:
#   pull.sh <prefix>
#   pull.sh <prefix> --dry-run
#
# Behaviour:
#   - Reads every ~/.claude/agents/<prefix>-<name>.md whose <name> is in
#     the allowlist (architect, astro, auditor, docs, mcp, rails, reviewer,
#     rust, security).
#   - Reverse-substitutes the absolute repo path (~/Dev/<prefix>) with
#     {{REPO_PATH}}, then writes to agents/<name>.md (overwriting).
#
# IMPORTANT — substitution scope:
#   - Only {{REPO_PATH}} is substituted automatically. The home-prefixed
#     absolute path is unambiguous; reversing it back is safe.
#   - {{PREFIX}} and {{REPO_NAME}} are NOT auto-substituted because the
#     project name (e.g. "pito") often appears inside identifiers,
#     branding, comments, etc. that should NOT become placeholders.
#   - After pulling, hand-review the diff. If you want a literal "pito"
#     string in the source to become {{PREFIX}}, edit the source file
#     directly — pull.sh won't do it for you.
#
# Caveat:
#   - This script is lossy if the file content drifted from the generic
#     shape (e.g., a new project-specific paragraph was added in the
#     installed copy). The diff makes the drift visible — review it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_AGENTS="${HOME}/.claude/agents"
DEST_AGENTS="${REPO_ROOT}/agents"

ALLOWED_AGENTS=(architect astro auditor docs mcp rails reviewer rust security)

PREFIX=""
DRY_RUN=0

usage() {
  sed -n '2,32p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage 0 ;;
    -*)
      echo "error: unknown flag '$1'" >&2
      usage 2 ;;
    *)
      if [[ -z "$PREFIX" ]]; then
        PREFIX="$1"
      else
        echo "error: unexpected positional arg '$1'" >&2
        usage 2
      fi
      shift ;;
  esac
done

[[ -n "$PREFIX" ]] || { echo "error: prefix required" >&2; usage 2; }

REPO_PATH="${HOME}/Dev/${PREFIX}"

mkdir -p "$DEST_AGENTS"

echo "pull.sh"
echo "  prefix:    $PREFIX"
echo "  src glob:  $SRC_AGENTS/${PREFIX}-*.md"
echo "  dest:      $DEST_AGENTS"
echo "  repo_path: $REPO_PATH (will be reverse-substituted with {{REPO_PATH}})"
[[ $DRY_RUN -eq 1 ]] && echo "  mode:      --dry-run"
echo ""

shopt -s nullglob
matched=0
for src in "${SRC_AGENTS}"/${PREFIX}-*.md; do
  matched=1
  basename="$(basename "$src" .md)"
  name="${basename#${PREFIX}-}"

  found=0
  for allowed in "${ALLOWED_AGENTS[@]}"; do
    [[ "$name" == "$allowed" ]] && { found=1; break; }
  done
  if [[ $found -eq 0 ]]; then
    echo "  SKIP    ${basename}.md — '${name}' not in allowlist"
    continue
  fi

  dest="${DEST_AGENTS}/${name}.md"
  rel_dest="${dest#${HOME}/}"

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ -f "$dest" ]]; then
      echo "  WOULD UPDATE  $rel_dest"
    else
      echo "  WOULD CREATE  $rel_dest"
    fi
    continue
  fi

  sed -e "s|${REPO_PATH}|{{REPO_PATH}}|g" "$src" > "$dest"
  echo "  WRITE   $rel_dest"
done
shopt -u nullglob

if [[ $matched -eq 0 ]]; then
  echo "  (no files matched ${PREFIX}-*.md in $SRC_AGENTS)"
fi

echo ""
echo "pull.sh: done."
