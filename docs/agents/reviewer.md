# claude-reviewer — project-specific extensions

Project-scoped overrides for the reviewer agent in claude-dotfiles.
Base template: `~/Dev/claude-dotfiles/agents/reviewer.md` (same repo
the agent reviews — meta).

## claude-dotfiles specifics

- Repo holds generic Claude Code agent templates with `{{PREFIX}}`,
  `{{REPO_NAME}}`, `{{REPO_PATH}}` substitutions plus install / pull
  scripts that materialize them into `~/.claude/agents/<prefix>-*.md`.
- Review pipeline:
  - `bin/test/agent_frontmatter_lint.sh` — every `agents/*.md` has a
    valid YAML frontmatter (`name:`, `description:`, `tools:` minimum).
  - `bin/test/roundtrip_test.sh` — install + pull round-trips with no
    diff (placeholder substitution invariants hold).
  - `bash -n bin/install.sh bin/pull.sh` and `shellcheck` on the same.
  - `prettier --check '**/*.md'` — wraps at 80 cols; angle-bracket
    placeholders backtick-quoted so prettier doesn't HTML-nest them.
  - Verify `--dry-run` on both scripts is a no-op.
- Template invariants to spot-check on every change:
  - Every agent template ends with the `## Project-specific extensions`
    section pointing at `{{REPO_PATH}}/CLAUDE.md` and
    `{{REPO_PATH}}/docs/agents/<short-name>.md`.
  - No hard-coded paths or names that should be templated.
  - No agent depends on a template variable that isn't in the supported
    set (`{{PREFIX}}`, `{{REPO_NAME}}`, `{{REPO_PATH}}`).
- Output: `docs/orchestration/playbooks/<YYYY-MM-DD>-<slug>.md` (create
  the directory on first run).

## Out of scope

- Editing `~/.claude/agents/` files directly — those are install
  artifacts. Review the source under `agents/` instead.
- Committing or pushing — user owns commits.
