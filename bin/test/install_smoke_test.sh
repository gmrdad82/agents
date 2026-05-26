#!/usr/bin/env bash
# install_smoke_test.sh — end-to-end install + diff + update cycle.
#
# Creates a throwaway fake project dir, exercises install.sh / diff.sh /
# check.sh through their main code paths, and asserts the expected
# outcomes. Safe — never touches HOME or any real project.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL="$REPO_ROOT/bin/install.sh"
DIFF="$REPO_ROOT/bin/diff.sh"
CHECK="$REPO_ROOT/bin/check.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

step() { echo "→ $*"; }
die()  { echo "FAIL: $*" >&2; exit 1; }

# ---- 1: dry-run override on empty dir writes nothing ----
step "dry-run override on empty dir"
"$INSTALL" "$tmp" --include architect,rails,reviewer --mode override --dry-run \
  >"$tmp/.dryrun.out" 2>/dev/null
[[ ! -f "$tmp/AGENTS.md" ]] || die "dry-run wrote AGENTS.md"

# ---- 2: real override creates AGENTS.md with markers ----
step "override creates AGENTS.md"
"$INSTALL" "$tmp" --include architect,rails,reviewer --mode override 2>/dev/null
[[ -f "$tmp/AGENTS.md" ]] || die "AGENTS.md not created"
grep -q '<!-- agents:begin name=architect ' "$tmp/AGENTS.md" \
  || die "architect marker missing"
grep -q '<!-- agents:begin name=rails ' "$tmp/AGENTS.md" \
  || die "rails marker missing"
grep -q '<!-- agents:begin name=reviewer ' "$tmp/AGENTS.md" \
  || die "reviewer marker missing"
grep -q '<!-- agents:banner:begin -->' "$tmp/AGENTS.md" \
  || die "banner marker missing"
grep -q '<!-- agents:toc:begin -->' "$tmp/AGENTS.md" \
  || die "toc marker missing"

# ---- 3: check.sh enumerates correctly ----
step "check.sh enumerates"
got="$("$CHECK" "$tmp" | tr '\n' ',' | sed 's/,$//')"
[[ "$got" == "architect,rails,reviewer" ]] \
  || die "check.sh returned '$got' (expected architect,rails,reviewer)"

# ---- 4: diff.sh reports missing for the rest ----
step "diff.sh reports missing"
if "$DIFF" "$tmp" >/dev/null 2>&1; then
  die "diff.sh exited 0 but agents are missing"
fi

# ---- 5: append adds one more agent without touching others ----
step "append adds postgres"
before_rails="$(sed -n '/<!-- agents:begin name=rails /,/<!-- agents:end name=rails -->/p' "$tmp/AGENTS.md" | sha256sum | awk '{print $1}')"
"$INSTALL" "$tmp" --include postgres --mode append 2>/dev/null
grep -q '<!-- agents:begin name=postgres ' "$tmp/AGENTS.md" \
  || die "postgres not appended"
after_rails="$(sed -n '/<!-- agents:begin name=rails /,/<!-- agents:end name=rails -->/p' "$tmp/AGENTS.md" | sha256sum | awk '{print $1}')"
[[ "$before_rails" == "$after_rails" ]] \
  || die "append modified the rails block"

# ---- 6: install all agents so diff.sh has a fair starting point ----
step "install all agents (override) so we can test stale detection"
"$INSTALL" "$tmp" --mode override 2>/dev/null
"$DIFF" "$tmp" >/dev/null 2>&1 \
  || die "diff.sh not in-sync after fresh full override"

# ---- 7: a body mutation alone does NOT trigger stale (sha tracks source) ----
step "body mutation is invisible to diff.sh (sha tracks source file)"
sed -i 's|## Conventions|## Conventions (MUTATED)|' "$tmp/AGENTS.md"
"$DIFF" "$tmp" >/dev/null 2>&1 \
  || die "diff.sh wrongly reports drift after body-only mutation"

# ---- 8: rewriting a marker sha DOES trigger stale ----
step "fake sha on rails marker triggers stale"
sed -i 's|<!-- agents:begin name=rails sha=[a-f0-9]*|<!-- agents:begin name=rails sha=deadbeef|' "$tmp/AGENTS.md"
if "$DIFF" "$tmp" >/dev/null 2>&1; then
  die "diff.sh missed stale rails (fake sha)"
fi

# ---- 9: update re-syncs the stale block ----
step "update re-syncs stale rails"
"$INSTALL" "$tmp" --include rails --mode update 2>/dev/null
"$DIFF" "$tmp" >/dev/null 2>&1 \
  || die "diff.sh still reports drift after update"

# ---- 10: --with-extra-stub creates docs/EXTRA.md ----
step "--with-extra-stub creates docs/EXTRA.md"
[[ ! -f "$tmp/docs/EXTRA.md" ]] || die "docs/EXTRA.md already existed"
"$INSTALL" "$tmp" --include architect --mode update --with-extra-stub \
  >/dev/null 2>&1
[[ -f "$tmp/docs/EXTRA.md" ]] || die "docs/EXTRA.md not created by --with-extra-stub"

# ---- 11: refuses to update a hand-written AGENTS.md (no markers) ----
step "refuses update on hand-written AGENTS.md"
tmp2="$(mktemp -d)"
echo "# AGENTS.md hand-written" >"$tmp2/AGENTS.md"
if "$INSTALL" "$tmp2" --include architect --mode update 2>/dev/null; then
  rm -rf "$tmp2"
  die "update mode accepted a marker-less AGENTS.md"
fi
rm -rf "$tmp2"

echo "OK"
