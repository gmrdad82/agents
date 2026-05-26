#!/usr/bin/env bash
# markers_test.sh — validate every agents/*.md has the expected shape.
#
# Asserts:
#   - YAML frontmatter present with `name:` and `description:`
#   - `name:` matches the filename (basename minus .md)
#   - First H1 line exists after the frontmatter
#   - Required sections present (## Project context, ## Conventions,
#     ## Anti-patterns, ## Commands)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENTS_DIR="$REPO_ROOT/agents"

fail() {
  echo "FAIL: $1" >&2
  failed=$((failed + 1))
}

failed=0
count=0

shopt -s nullglob
for f in "$AGENTS_DIR"/*.md; do
  count=$((count + 1))
  base="$(basename "$f" .md)"

  # Frontmatter
  if [[ "$(head -1 "$f")" != "---" ]]; then
    fail "$base: missing YAML frontmatter (no leading ---)"
    continue
  fi

  # End of frontmatter
  end_line=$(awk 'NR>1 && $0=="---" { print NR; exit }' "$f")
  if [[ -z "$end_line" ]]; then
    fail "$base: frontmatter not terminated"
    continue
  fi

  fm=$(sed -n "1,${end_line}p" "$f")

  name=$(echo "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)
  desc=$(echo "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)

  if [[ -z "$name" ]]; then
    fail "$base: missing 'name:' in frontmatter"
  elif [[ "$name" != "$base" ]]; then
    fail "$base: name '$name' doesn't match filename '$base'"
  fi

  if [[ -z "$desc" ]]; then
    fail "$base: missing 'description:' in frontmatter"
  fi

  # H1
  if ! sed -n "${end_line},\$p" "$f" | grep -qE '^# '; then
    fail "$base: no H1 heading found after frontmatter"
  fi

  # Required sections
  for section in '## Project context' '## Conventions' '## Anti-patterns'; do
    if ! grep -qF "$section" "$f"; then
      fail "$base: missing required section '$section'"
    fi
  done
  # Commands section may be named "Commands" or "Commands / verification"
  if ! grep -qE '^## Commands' "$f"; then
    fail "$base: missing required section '## Commands ...'"
  fi
done
shopt -u nullglob

if [[ $count -eq 0 ]]; then
  echo "no agent files found in $AGENTS_DIR" >&2
  exit 1
fi

if [[ $failed -eq 0 ]]; then
  echo "OK: $count agent files passed structure checks"
  exit 0
else
  echo "FAILED: $failed problem(s) across $count files" >&2
  exit 1
fi
