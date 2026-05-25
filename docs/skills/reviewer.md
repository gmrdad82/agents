# reviewer — project-specific extensions

Project-scoped overrides for the reviewer skill in this repo.
Base template: `~/Dev/agents/skills/reviewer.md` (same repo the skill
reviews — meta).

## agents repo specifics

- Repo holds generic CodeWhale skill templates with `{{PREFIX}}`,
  `{{REPO_NAME}}`, `{{REPO_PATH}}` substitutions plus install / pull
  scripts that materialize them into `~/.codewhale/skills/`.
- Review pipeline:
  - `bash -n bin/*.sh` and `shellcheck` on all scripts.
  - `prettier --check '**/*.md'` — wraps at 80 cols; angle-bracket
    placeholders backtick-quoted so prettier doesn't HTML-nest them.
  - `bin/test/agent_frontmatter_lint.sh` — every `skills/*.md` has a
    valid YAML frontmatter (`name:`, `description:` minimum).
  - `bin/test/roundtrip_test.sh` — install + pull round-trips with no
    diff (placeholder substitution invariants hold).
  - Verify `--dry-run` on both scripts is a no-op.
- Template invariants to spot-check on every change:
  - Every skill template ends with the `## Project-specific extensions`
    section pointing at `{{REPO_PATH}}/AGENTS.md` and
    `{{REPO_PATH}}/docs/skills/<short-name>.md`.
  - No hard-coded paths or names that should be templated.
  - No skill depends on a template variable that isn't in the supported
    set (`{{PREFIX}}`, `{{REPO_NAME}}`, `{{REPO_PATH}}`).
- Output: `docs/orchestration/playbooks/<YYYY-MM-DD>-<slug>.md` (create
  the directory on first run).

## Out of scope

- Editing `~/.codewhale/skills/` files directly — those are install
  artifacts. Review the source under `skills/` instead.
- Committing or pushing — user owns commits.
