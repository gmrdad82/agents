#!/usr/bin/env bash
# check.sh — list agents currently installed in <project>/AGENTS.md.
#
# Usage:
#   bin/check.sh <path/to/project>
#
# Prints one agent name per line, in the order they appear in AGENTS.md.
# Exit code 0 if AGENTS.md is present (even if empty); 1 if missing.

set -euo pipefail

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

grep -oE '<!-- agents:begin name=[a-z0-9-]+' "$AGENTS_MD" \
  | sed 's/.*name=//' \
  || true
