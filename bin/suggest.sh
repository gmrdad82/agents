#!/usr/bin/env bash
#
# suggest.sh — analyse a project repo and recommend which skills from this
# repo's catalog suit it, based on the tech stack detected.
#
# Usage:
#   bin/suggest.sh <repo-path>
#   bin/suggest.sh <repo-path> --install
#   bin/suggest.sh <repo-path> --dry-run
#
# Detection heuristics (file existence):
#
#   File / Pattern        → Skill         → Likely stack
#   ───────────────────────────────────────────────────────
#   Gemfile               → rails         → Ruby / Rails
#   Cargo.toml            → rust          → Rust
#   package.json          → node          → Node.js / TypeScript
#   next.config.*         → node          → Next.js
#   astro.config.*        → astro         → Astro
#   meilisearch/          → meilisearch   → Meilisearch
#   voyage.*              → voyage        → Voyage AI
#   omarchy.*             → omarchy       → Omarchy Linux
#   db/migrate/           → postgres      → PostgreSQL
#   app/ or src/ + .ts    → ai            → DeepSeek AI
#   docs/                 → docs          → Documentation
#   spec/ or test/        → auditor       → Audit state
#   .github/workflows/    → reviewer      → Code review
#   {is root of this repo → archtec       → Feature specs
#
# Every suggestion is a recommendation. The user confirms before installing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_SKILLS="${REPO_ROOT}/skills"

ALL_SKILLS=(ai architect astro auditor docker docs git-precommit-guard mcp meilisearch mysql node omarchy postgres rails redis reviewer rust security voyage)

usage() {
  echo "Usage: $0 <repo-path> [--install] [--dry-run]" >&2
  exit "${1:-0}"
}

TARGET=""
DRY_RUN=0
DO_INSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)  DO_INSTALL=1; shift ;;
    --dry-run)  DRY_RUN=1;   shift ;;
    -h|--help)  usage 0 ;;
    -*)
      echo "error: unknown flag '$1'" >&2
      usage 2 ;;
    *)
      TARGET="$1"; shift ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "error: repo path required" >&2; usage 2; }
[[ -d "$TARGET" ]] || { echo "error: '$TARGET' is not a directory" >&2; exit 2; }

# Normalise: resolve symlinks, trailing slash
TARGET="$(cd "$TARGET" && pwd)"
PREFIX="$(basename "$TARGET")"

echo "suggest.sh"
echo "  target: $TARGET"
echo "  prefix: $PREFIX"
echo ""

# Detection rules — ordered by specificity (most specific first)
declare -A DETECTED

# Rails
[[ -f "${TARGET}/Gemfile" ]] && DETECTED[rails]="Gemfile found"
grep -q '^gem .*rails' "${TARGET}/Gemfile" 2>/dev/null && DETECTED[rails]="Rails in Gemfile"

# Rust
[[ -f "${TARGET}/Cargo.toml" ]] && DETECTED[rust]="Cargo.toml found"

# Node / TypeScript
if [[ -f "${TARGET}/package.json" ]]; then
  DETECTED[node]="package.json found"
  grep -q '"astro"' "${TARGET}/package.json" 2>/dev/null && DETECTED[astro]="Astro in package.json"
  grep -q '"next"' "${TARGET}/package.json" 2>/dev/null && DETECTED[node]="Next.js in package.json"
fi
[[ -f "${TARGET}/next.config.js" || -f "${TARGET}/next.config.ts" || -f "${TARGET}/next.config.mjs" ]] && DETECTED[node]="next.config found"
[[ -f "${TARGET}/astro.config.js" || -f "${TARGET}/astro.config.mjs" ]] && DETECTED[astro]="astro.config found"

# Meilisearch
[[ -d "${TARGET}/meilisearch" ]] && DETECTED[meilisearch]="meilisearch/ directory found"
grep -rq 'meilisearch' "${TARGET}" --include='Gemfile' --include='package.json' --include='Cargo.toml' 2>/dev/null && DETECTED[meilisearch]="meilisearch dependency found"

# Voyage AI
grep -rq 'voyage' "${TARGET}" --include='Gemfile' --include='package.json' --include='Cargo.toml' 2>/dev/null && DETECTED[voyage]="voyage dependency found"

# Docker
[[ -f "${TARGET}/Dockerfile" ]] && DETECTED[docker]="Dockerfile found"
[[ -f "${TARGET}/docker-compose.yml" || -f "${TARGET}/compose.yml" ]] && DETECTED[docker]="docker-compose found"

# Redis
grep -rq 'redis\|sidekiq\|rescue' "${TARGET}" --include='Gemfile' --include='package.json' --include='Cargo.toml' 2>/dev/null && DETECTED[redis]="Redis dependency found"

# MySQL
[[ -f "${TARGET}/db/migrate" ]] && DETECTED[mysql]="db/migrate/ found (MySQL)"
[[ -f "${TARGET}/db/schema.rb" ]] && DETECTED[mysql]="db/schema found (MySQL)"

# Postgres
[[ -d "${TARGET}/db/migrate" ]] && DETECTED[postgres]="db/migrate/ found"
[[ -f "${TARGET}/db/schema.rb" || -f "${TARGET}/db/structure.sql" ]] && DETECTED[postgres]="db/schema found"

# Architect / specs (any project should have a spec writer)
DETECTED[architect]="recommended for all projects"

# Documentation
[[ -d "${TARGET}/docs" ]] && DETECTED[docs]="docs/ directory found"

# Auditor
DETECTED[auditor]="recommended for all projects"

# Reviewer
[[ -d "${TARGET}/.github/workflows" ]] && DETECTED[reviewer]="GitHub CI detected"

# Security
DETECTED[security]="recommended for auth/sensitive projects"

# Git pre-commit guard
DETECTED[git-precommit-guard]="recommended for all projects"

# AI
grep -rq 'deepseek\|openai\|anthropic\|ai\b' "${TARGET}" --include='Gemfile' --include='package.json' --include='Cargo.toml' 2>/dev/null && DETECTED[ai]="AI dependency found"

# Omarchy — detect by Hyprland/Wayland config dirs or omarchy.sh
[[ -f "${TARGET}/omarchy.sh" ]] && DETECTED[omarchy]="omarchy.sh found"
[[ -d "${TARGET}/hypr" && -d "${TARGET}/waybar" ]] && DETECTED[omarchy]="Hyprland config found (waybar, hypr/)"

echo "Detected stack:"
echo ""
for skill in "${ALL_SKILLS[@]}"; do
  if [[ -n "${DETECTED[$skill]:-}" ]]; then
    echo "  ✓ $skill — ${DETECTED[$skill]}"
  fi
done

# Build include list
INCLUDE=""
for skill in "${ALL_SKILLS[@]}"; do
  if [[ -n "${DETECTED[$skill]:-}" ]]; then
    if [[ -z "$INCLUDE" ]]; then
      INCLUDE="$skill"
    else
      INCLUDE="${INCLUDE},${skill}"
    fi
  fi
done

echo ""
echo "Recommended --include:"
echo "  --include ${INCLUDE}"
echo ""

if [[ $DO_INSTALL -eq 1 ]]; then
  echo "Installing suggested skills for prefix '${PREFIX}'..."
  echo ""
  if [[ $DRY_RUN -eq 1 ]]; then
    "${REPO_ROOT}/bin/install.sh" "${PREFIX}" --include "${INCLUDE}" --dry-run
  else
    "${REPO_ROOT}/bin/install.sh" "${PREFIX}" --include "${INCLUDE}"
  fi
fi

echo ""
echo "suggest.sh: done."
