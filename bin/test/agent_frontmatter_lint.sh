#!/usr/bin/env bash
#
# agent_frontmatter_lint.sh — verifies every agents/*.md has YAML
# frontmatter with `name: {{PREFIX}}-<basename>` matching the file's
# basename. Catches refactor drift where an agent gets renamed without
# updating its self-reference.
#
# Frontmatter shape required:
#   ---
#   name: {{PREFIX}}-<basename>
#   description: ...
#   ...
#   ---
#
# Exit codes:
#   0 → all files pass
#   1 → at least one file failed validation

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_AGENTS="${REPO_ROOT}/agents"

echo "agent_frontmatter_lint.sh"
echo "  scanning: ${SRC_AGENTS}"
echo ""

FAILED=0

for f in "${SRC_AGENTS}"/*.md; do
  basename="$(basename "$f" .md)"
  expected_name="{{PREFIX}}-${basename}"

  # Frontmatter must start with `---` on the first line.
  first_line="$(head -n 1 "$f")"
  if [[ "$first_line" != "---" ]]; then
    echo "  ✗ ${basename}.md — missing YAML frontmatter (first line is not '---')"
    FAILED=1
    continue
  fi

  # Pull the `name:` field from the frontmatter block (between the first
  # two `---` lines).
  actual_name="$(awk '
    BEGIN { in_fm = 0; count = 0 }
    /^---$/ {
      count++
      if (count == 1) { in_fm = 1; next }
      if (count == 2) { exit }
    }
    in_fm && /^name:[[:space:]]/ {
      sub(/^name:[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      print
      exit
    }
  ' "$f")"

  if [[ -z "$actual_name" ]]; then
    echo "  ✗ ${basename}.md — frontmatter missing 'name:' field"
    FAILED=1
    continue
  fi

  if [[ "$actual_name" != "$expected_name" ]]; then
    echo "  ✗ ${basename}.md — name is '${actual_name}', expected '${expected_name}'"
    FAILED=1
    continue
  fi

  echo "  ✓ ${basename}.md — name: ${actual_name}"
done

echo ""
if [[ $FAILED -eq 1 ]]; then
  echo "agent_frontmatter_lint.sh: FAIL"
  exit 1
fi
echo "agent_frontmatter_lint.sh: PASS"
