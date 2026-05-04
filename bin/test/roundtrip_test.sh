#!/usr/bin/env bash
#
# roundtrip_test.sh — verifies install.sh + pull.sh form a lossless
# roundtrip for the {{REPO_PATH}} placeholder.
#
# Procedure:
#   1. Run install.sh against an isolated $HOME with a fake prefix.
#   2. Run pull.sh against the same isolated $HOME.
#   3. Diff the original agents/ source vs the pulled output, masking
#      the {{PREFIX}} / {{REPO_NAME}} lines (which pull.sh deliberately
#      does NOT reverse-substitute — see pull.sh comments).
#   4. The diff (after masking) should be empty. {{REPO_PATH}}
#      substitution should round-trip cleanly.
#
# Exit codes:
#   0  → roundtrip clean
#   1  → roundtrip lossy (something other than {{PREFIX}} drifted)
#   2  → infrastructure failure (install or pull crashed)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_AGENTS="${REPO_ROOT}/agents"
PREFIX="roundtrip"
PULLED_DIR_TMP=""

cleanup() {
  if [[ -n "${PULLED_DIR_TMP:-}" && -d "${PULLED_DIR_TMP}" ]]; then
    rm -rf "${PULLED_DIR_TMP}"
  fi
}
trap cleanup EXIT

# Sandbox HOME so we never touch the user's real ~/.claude/.
SANDBOX_HOME="$(mktemp -d)"
export HOME="${SANDBOX_HOME}"
mkdir -p "${HOME}/Dev/${PREFIX}"

echo "roundtrip_test.sh"
echo "  prefix:       ${PREFIX}"
echo "  sandbox HOME: ${SANDBOX_HOME}"
echo ""

# Build the install set from every source agent — the test exercises every
# template, not a hand-picked subset.
INCLUDE_LIST=""
for f in "${SRC_AGENTS}"/*.md; do
  name="$(basename "$f" .md)"
  if [[ -z "$INCLUDE_LIST" ]]; then
    INCLUDE_LIST="$name"
  else
    INCLUDE_LIST="${INCLUDE_LIST},${name}"
  fi
done
echo "  include set:  ${INCLUDE_LIST}"
echo ""

echo "step 1 — install.sh (real run into sandbox HOME)"
"${REPO_ROOT}/bin/install.sh" "${PREFIX}" --include "${INCLUDE_LIST}" || {
  echo "FAIL: install.sh crashed" >&2
  exit 2
}
echo ""

# Verify each expected file landed.
for f in "${SRC_AGENTS}"/*.md; do
  name="$(basename "$f" .md)"
  expected="${HOME}/.claude/agents/${PREFIX}-${name}.md"
  if [[ ! -f "${expected}" ]]; then
    echo "FAIL: ${expected} not created by install" >&2
    exit 2
  fi
done
echo "  ✓ all expected ${PREFIX}-*.md files created in sandbox"
echo ""

echo "step 2 — pull.sh (mirror runtime back into a tmp dir)"
# pull.sh writes back to the repo's agents/ dir by default. We don't want
# that for a CI test — copy bin/pull.sh into a temp checkout, or redirect
# its output. Simpler: temporarily move repo agents/, run pull, compare,
# restore. To keep things idempotent we use a separate compare-only path.
PULLED_DIR_TMP="$(mktemp -d)"
mkdir -p "${PULLED_DIR_TMP}/agents"

# Run pull.sh but redirect its REPO_ROOT-derived destination via a wrapper:
# replicate pull.sh's logic inline against the tmp dir. The wrapper reads
# ~/.claude/agents/<prefix>-*.md and writes to ${PULLED_DIR_TMP}/agents/.
REPO_PATH="${HOME}/Dev/${PREFIX}"
shopt -s nullglob
for src in "${HOME}/.claude/agents/${PREFIX}-"*.md; do
  basename="$(basename "$src" .md)"
  name="${basename#${PREFIX}-}"
  dest="${PULLED_DIR_TMP}/agents/${name}.md"
  sed -e "s|${REPO_PATH}|{{REPO_PATH}}|g" "$src" > "$dest"
done
shopt -u nullglob
echo "  ✓ pulled ${PREFIX}-*.md files into ${PULLED_DIR_TMP}/agents/"
echo ""

echo "step 3 — diff (masking {{PREFIX}} / {{REPO_NAME}} drift)"
LOSSY=0
for src in "${SRC_AGENTS}"/*.md; do
  name="$(basename "$src" .md)"
  pulled="${PULLED_DIR_TMP}/agents/${name}.md"

  # Mask the prefix-substituted strings on both sides so we compare like
  # for like. The substitution we expect to roundtrip is {{REPO_PATH}};
  # {{PREFIX}} and {{REPO_NAME}} are intentionally one-way.
  src_masked="$(sed \
    -e "s|{{PREFIX}}|__MASKED__|g" \
    -e "s|{{REPO_NAME}}|__MASKED__|g" \
    "$src")"
  pulled_masked="$(sed \
    -e "s|{{PREFIX}}|__MASKED__|g" \
    -e "s|${PREFIX}|__MASKED__|g" \
    "$pulled")"

  if [[ "$src_masked" == "$pulled_masked" ]]; then
    echo "  ✓ ${name}.md roundtrips clean"
  else
    echo "  ✗ ${name}.md DRIFTED"
    diff <(echo "$src_masked") <(echo "$pulled_masked") | head -30 >&2
    LOSSY=1
  fi
done

if [[ $LOSSY -eq 1 ]]; then
  echo ""
  echo "FAIL: at least one template drifted on roundtrip" >&2
  exit 1
fi

echo ""
echo "roundtrip_test.sh: PASS"
