#!/usr/bin/env bash
# diff-skills.sh — compare skills in <project>/AGENTS.md against the master source.
#
# Usage:
#   bin/diff-skills.sh <path/to/project>
#
# Reports:
#   missing  — skills in skills/ but not in <project>/AGENTS.md
#   stale    — skills present in both but whose marker sha doesn't match
#              the current source file
#   orphans  — skills in <project>/AGENTS.md but not in skills/
#
# Exit code 0 if everything is in sync; non-zero otherwise (CI-friendly).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  sed -n '2,/^set -/p' "$0" | sed -n 's/^# \{0,1\}//p' | sed '$d'
  exit 0
fi

TARGET="$1"
if [[ ! -d "$TARGET" ]]; then
  echo "not a directory: $TARGET" >&2
  exit 2
fi
AGENTS_MD="$(cd "$TARGET" && pwd)/AGENTS.md"
if [[ ! -f "$AGENTS_MD" ]]; then
  echo "no AGENTS.md at $AGENTS_MD" >&2
  exit 1
fi

sha_of() {
  sha256sum "$1" | awk '{print $1}'
}

master_names() {
  find "$SKILLS_DIR" -maxdepth 1 -name '*.md' -printf '%f\n' \
    | sed 's/\.md$//' \
    | sort
}

installed_names() {
  grep -oE '<!-- agents:begin name=[a-z0-9-]+' "$AGENTS_MD" \
    | sed 's/.*name=//' \
    | sort -u
}

installed_sha_of() {
  local name="$1"
  grep -oE "<!-- agents:begin name=$name sha=[a-f0-9]+" "$AGENTS_MD" \
    | head -1 \
    | sed 's/.*sha=//'
}

master_list=$(master_names)
installed_list=$(installed_names)

missing=$(comm -23 <(printf '%s\n' "$master_list") <(printf '%s\n' "$installed_list"))
orphans=$(comm -13 <(printf '%s\n' "$master_list") <(printf '%s\n' "$installed_list"))
both=$(comm -12 <(printf '%s\n' "$master_list") <(printf '%s\n' "$installed_list"))

stale=""
while IFS= read -r n; do
  [[ -n "$n" ]] || continue
  old="$(installed_sha_of "$n")"
  new="$(sha_of "$SKILLS_DIR/$n.md")"
  if [[ "$old" != "$new" ]]; then
    stale+="$n"$'\n'
  fi
done <<<"$both"
stale="${stale%$'\n'}"

status=0

if [[ -n "$missing" ]]; then
  echo "missing (in master but not in $AGENTS_MD):"
  while IFS= read -r n; do
    [[ -n "$n" ]] && printf '  %s\n' "$n"
  done <<<"$missing"
  status=1
fi

if [[ -n "$stale" ]]; then
  echo "stale (sha mismatch — source changed since install):"
  while IFS= read -r n; do
    [[ -n "$n" ]] && printf '  %s\n' "$n"
  done <<<"$stale"
  status=1
fi

if [[ -n "$orphans" ]]; then
  echo "orphans (in $AGENTS_MD but not in master):"
  while IFS= read -r n; do
    [[ -n "$n" ]] && printf '  %s\n' "$n"
  done <<<"$orphans"
  status=1
fi

if [[ $status -eq 0 ]]; then
  echo "in sync (${both//$'\n'/ })"
fi

exit $status
