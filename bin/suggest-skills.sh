#!/usr/bin/env bash
# suggest-skills.sh — analyse a project repo and recommend which skills to install.
#
# Usage:
#   bin/suggest-skills.sh <path/to/project>
#                         [--install] [--dry-run] [--mode update|append|override]
#                         [-h|--help]
#
# Walks the project tree for known stack markers (Gemfile, package.json,
# Cargo.toml, Dockerfile, ...) and prints a recommended --include list.
# With --install, hands the list off to install-skills.sh.
# With --install --dry-run, install-skills.sh runs in dry-run mode.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

usage() {
  sed -n '2,/^set -/p' "$0" | sed -n 's/^# \{0,1\}//p' | sed '$d'
}

TARGET=""
DO_INSTALL=0
DRY_RUN=0
MODE="update"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --install) DO_INSTALL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --mode=*) MODE="${1#*=}"; shift ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)
      if [[ -z "$TARGET" ]]; then TARGET="$1"; shift
      else echo "unexpected positional: $1" >&2; exit 2
      fi
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "missing required argument: <path/to/project>" >&2
  exit 2
fi
if [[ ! -d "$TARGET" ]]; then
  echo "not a directory: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

# -------- detection helpers --------

has_file() { [[ -e "$TARGET/$1" ]]; }
has_glob() {
  # shellcheck disable=SC2206
  local matches=( "$TARGET"/$1 )
  [[ -e "${matches[0]}" ]]
}
grep_dep() {
  local pat="$1"
  for f in Gemfile package.json Cargo.toml pyproject.toml requirements.txt; do
    if [[ -f "$TARGET/$f" ]] && grep -qE "$pat" "$TARGET/$f"; then
      return 0
    fi
  done
  return 1
}

# -------- detection rules --------

declare -A REASONS=()
add() { REASONS["$1"]="${REASONS[$1]:-}${REASONS[$1]:+; }$2"; }

# Always-recommended
add architect    "every project benefits from a feature-spec lane"
add docs         "every project benefits from doc conventions"
add reviewer     "every project benefits from a review pass"
add security     "every project benefits from a security pass"
add simplifier   "every project benefits from a simplifier pass"
add git          "git history hygiene applies anywhere"
add shell        "scripts pop up in every repo"

# .github / GitHub
has_file ".github"   && add github     ".github/ directory present"

# Ruby / Rails
if has_file "Gemfile"; then
  if grep -qE '^[[:space:]]*gem ["'"'"']rails["'"'"']' "$TARGET/Gemfile"; then
    add rails "Gemfile lists rails"
  else
    add rails "Gemfile present (Ruby project)"
  fi
  grep -qE 'rspec' "$TARGET/Gemfile" && add rspec "rspec in Gemfile"
fi
has_file "spec"             && add rspec    "spec/ directory present"
has_file "config/cable.yml" && add action-cable "config/cable.yml present"
has_file "app/channels"     && add action-cable "app/channels/ present"

# Databases
if has_file "db/migrate" || has_file "db/schema.rb" || has_file "db/structure.sql"; then
  if has_file "config/database.yml"; then
    grep -qiE 'adapter:[[:space:]]*postgres'   "$TARGET/config/database.yml" \
      && add postgres "config/database.yml uses postgresql"
    grep -qiE 'adapter:[[:space:]]*mysql'      "$TARGET/config/database.yml" \
      && add mysql    "config/database.yml uses mysql"
  fi
fi
if has_file "docker-compose.yml" || has_file "compose.yml"; then
  for f in "$TARGET/docker-compose.yml" "$TARGET/compose.yml"; do
    [[ -f "$f" ]] || continue
    grep -qiE 'image:[[:space:]]*(postgres|pgvector)' "$f" \
      && add postgres "postgres image in $(basename "$f")"
    grep -qiE 'image:[[:space:]]*(mysql|mariadb)' "$f" \
      && add mysql "mysql/mariadb image in $(basename "$f")"
    grep -qiE 'image:[[:space:]]*redis' "$f" \
      && add redis "redis image in $(basename "$f")"
  done
fi

# Redis (gems / deps)
grep_dep 'redis|sidekiq|resque|good_job|solid_queue' \
  && add redis "redis-using dependency detected"

# Frontend stack
has_file "tailwind.config.js"   && add tailwind "tailwind.config.js present"
has_file "tailwind.config.ts"   && add tailwind "tailwind.config.ts present"
has_file "tailwind.config.mjs"  && add tailwind "tailwind.config.mjs present"
if [[ -f "$TARGET/package.json" ]]; then
  grep -qE '"tailwindcss"' "$TARGET/package.json" && add tailwind "tailwindcss in package.json"
  grep -qE '"@hotwired/turbo"' "$TARGET/package.json" && add turbo "@hotwired/turbo in package.json"
  grep -qE '"astro"' "$TARGET/package.json" && add astro "astro in package.json"
fi
if [[ -f "$TARGET/Gemfile" ]]; then
  grep -qE 'turbo-rails' "$TARGET/Gemfile" && add turbo "turbo-rails in Gemfile"
fi

# Astro (config file)
has_glob "astro.config.*" && add astro "astro.config.* present"

# Docker
has_file "Dockerfile"        && add docker "Dockerfile present"
has_file "docker-compose.yml" && add docker "docker-compose.yml present"
has_file "compose.yml"       && add docker "compose.yml present"

# Kamal
has_file "config/deploy.yml" && add kamal "config/deploy.yml present"
has_file ".kamal"            && add kamal ".kamal/ present"

# Cloudflare
has_file "wrangler.toml"   && add cloudflare "wrangler.toml present"
has_file "wrangler.jsonc"  && add cloudflare "wrangler.jsonc present"
has_file "wrangler.json"   && add cloudflare "wrangler.json present"

# MCP
has_file ".mcp.json" && add mcp ".mcp.json present"
grep_dep '@modelcontextprotocol/sdk|modelcontextprotocol|mcp[-_]server' \
  && add mcp "mcp sdk dependency detected"

# AI / LLMs
grep_dep 'anthropic|openai|deepseek|cohere|google-genai|ollama|@anthropic-ai/sdk' \
  && add ai "LLM provider SDK in dependencies"

# Voyage
grep_dep 'voyageai|voyage' && add voyage "voyage dependency detected"

# Omarchy (machine-level, opt-in if config dirs exist)
if [[ -d "$HOME/.config/hypr" && -d "$HOME/.config/waybar" ]] \
   && [[ "$TARGET" == "$HOME" || "$TARGET" == "$HOME/Dev"* ]]; then
  add omarchy "Hyprland + Waybar detected on this machine"
fi
has_file "omarchy.sh" && add omarchy "omarchy.sh in project"

# -------- emit --------

names=()
for n in "${!REASONS[@]}"; do names+=("$n"); done
mapfile -t sorted_names < <(printf '%s\n' "${names[@]}" | sort)

echo "Detected stack and recommendations for $TARGET:" >&2
for n in "${sorted_names[@]}"; do
  if [[ ! -f "$SKILLS_DIR/$n.md" ]]; then
    printf '  %-15s [SKIP — no skill named %s]\n' "$n" "$n" >&2
    continue
  fi
  printf '  %-15s %s\n' "$n" "${REASONS[$n]}" >&2
done

include_list=""
for n in "${sorted_names[@]}"; do
  [[ -f "$SKILLS_DIR/$n.md" ]] || continue
  include_list+="$n,"
done
include_list="${include_list%,}"

echo "" >&2
echo "Recommended:" >&2
echo "  bin/install-skills.sh $TARGET --include $include_list --mode $MODE" >&2

if [[ $DO_INSTALL -eq 1 ]]; then
  echo "" >&2
  echo "Installing..." >&2
  args=("$TARGET" --include "$include_list" --mode "$MODE")
  if [[ $DRY_RUN -eq 1 ]]; then args+=(--dry-run); fi
  exec "$SCRIPT_DIR/install-skills.sh" "${args[@]}"
fi
