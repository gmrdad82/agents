#!/usr/bin/env bash
#
# install.sh — install templated skills from this repo into
# ~/.codewhale/skills/ under a project prefix.
#
# Usage:
#   install.sh <prefix> --include <name1>,<name2>,...
#   install.sh <prefix> --include <names> --dry-run
#   install.sh <prefix> --include <names> --force
#   install.sh <prefix> --include <names> --prune
#
# Every skill is opt-in. The --include flag is REQUIRED; nothing installs
# by default. The script substitutes {{PREFIX}}, {{REPO_NAME}}, {{REPO_PATH}}
# placeholders in each source file and writes a skill subdirectory with
# SKILL.md.
#
# Safety:
#   - Refuses to overwrite a ~/.codewhale/ file newer than the source unless
#     --force is passed.
#   - --prune deletes ~/.codewhale/skills/<prefix>-* directories that aren't
#     in the current --include set. Scoped to THIS prefix only — never touches
#     other projects.
#   - --dry-run previews everything without writing or deleting.
#   - Idempotent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_SKILLS="${REPO_ROOT}/skills"
DEST_ROOT="${HOME}/.codewhale/skills"

ALLOWED_SKILLS=(ai architect astro auditor docker docs git-precommit-guard mcp meilisearch mysql node omarchy postgres rails redis reviewer rust security voyage)

PREFIX=""
INCLUDE=""
DRY_RUN=0
FORCE=0
PRUNE=0

usage() {
  sed -n '2,25p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include)  INCLUDE="${2:-}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --force)    FORCE=1;   shift ;;
    --prune)    PRUNE=1;   shift ;;
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

[[ -n "$PREFIX" ]]  || { echo "error: prefix required" >&2; usage 2; }
[[ -n "$INCLUDE" ]] || { echo "error: --include required (nothing installs by default)" >&2; usage 2; }

REPO_PATH="${HOME}/Dev/${PREFIX}"
REPO_NAME="${PREFIX}"

IFS=',' read -ra REQUESTED <<< "$INCLUDE"

# Validate every requested name against the allowlist
for name in "${REQUESTED[@]}"; do
  found=0
  for allowed in "${ALLOWED_SKILLS[@]}"; do
    [[ "$name" == "$allowed" ]] && { found=1; break; }
  done
  if [[ $found -eq 0 ]]; then
    echo "error: unknown skill '$name'" >&2
    echo "       allowed: ${ALLOWED_SKILLS[*]}" >&2
    exit 2
  fi
done

mkdir -p "$DEST_ROOT"

echo "install.sh"
echo "  prefix:    $PREFIX"
echo "  include:   ${REQUESTED[*]}"
echo "  src:       $SRC_SKILLS"
echo "  dest:      $DEST_ROOT"
echo "  repo_path: $REPO_PATH"
[[ $DRY_RUN -eq 1 ]] && echo "  mode:      --dry-run"
[[ $FORCE   -eq 1 ]] && echo "  mode:      --force"
[[ $PRUNE   -eq 1 ]] && echo "  mode:      --prune"
echo ""

# Track what we install for the prune phase
declare -a INSTALLED_PATHS=()

for name in "${REQUESTED[@]}"; do
  src="${SRC_SKILLS}/${name}.md"
  dest_dir="${DEST_ROOT}/${PREFIX}-${name}"
  dest="${dest_dir}/SKILL.md"
  rel_dest="${dest_dir#"${HOME}/"}"

  if [[ ! -f "$src" ]]; then
    echo "  SKIP    $rel_dest — source $src missing"
    continue
  fi

  # mtime safety
  if [[ -f "$dest" && $FORCE -eq 0 ]]; then
    src_mtime=$(stat -c %Y "$src")
    dest_mtime=$(stat -c %Y "$dest")
    if [[ "$dest_mtime" -gt "$src_mtime" ]]; then
      echo "  SKIP    $rel_dest — destination newer (use --force)"
      INSTALLED_PATHS+=("$dest")
      continue
    fi
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ -f "$dest" ]]; then
      echo "  WOULD UPDATE  $rel_dest"
    else
      echo "  WOULD CREATE  $rel_dest"
    fi
    INSTALLED_PATHS+=("$dest")
    continue
  fi

  mkdir -p "$dest_dir"
  sed \
    -e "s|{{PREFIX}}|${PREFIX}|g" \
    -e "s|{{REPO_NAME}}|${REPO_NAME}|g" \
    -e "s|{{REPO_PATH}}|${REPO_PATH}|g" \
    "$src" > "$dest"
  if [[ -f "$dest" ]]; then
    echo "  WRITE   $rel_dest/SKILL.md"
  fi
  INSTALLED_PATHS+=("$dest")
done

# Prune phase: delete ~/.codewhale/skills/<prefix>-* dirs not in INSTALLED_PATHS
if [[ $PRUNE -eq 1 ]]; then
  echo ""
  echo "prune (scoped to ${PREFIX}-*):"
  shopt -s nullglob
  for existing_dir in "${DEST_ROOT}/${PREFIX}-"*; do
    [[ -d "$existing_dir" ]] || continue
    existing_skill="${existing_dir}/SKILL.md"
    keep=0
    for installed in "${INSTALLED_PATHS[@]:-}"; do
      [[ "$existing_skill" == "$installed" ]] && { keep=1; break; }
    done
    if [[ $keep -eq 0 ]]; then
      rel="${existing_dir#"${HOME}/"}"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "  WOULD DELETE  $rel/"
      else
        rm -rf "$existing_dir"
        echo "  DELETE  $rel/"
      fi
    fi
  done
  shopt -u nullglob
fi

echo ""
echo "install.sh: done."
