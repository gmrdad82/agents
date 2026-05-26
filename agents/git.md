---
name: git
description: Git workflow conventions — branching, committing, rebasing, hooks, pre-commit checks.
triggers: ["always recommended for any project tracked in git"]
---

# Git

## Project context

Read `docs/EXTRA.md` first. It declares the project's branch model
(trunk-based vs feature branches), commit message style, whether PRs
are required, the main branch name, and any hooks the project ships.
Anything declared there overrides the defaults below.

## Conventions

- Default branch is `main` unless `docs/EXTRA.md` says otherwise.
- Commit subject ≤ 72 chars, imperative ("Add X", "Fix Y"). Body
  optional; when present, wraps at 72 cols and explains WHY.
- One logical change per commit. If you can't summarize the commit in
  one subject line, split it.
- Pull with `--rebase` by default. Set globally:
  `git config --global pull.rebase true`.
- Never force-push to `main` (or whatever the project's protected
  branch is named).
- Feature branches: `<initials>/<short-slug>` unless project specifies.
- Don't commit generated artifacts (build outputs, `.env*`, `node_modules`,
  `*.log`, IDE folders). Add them to `.gitignore` once, repo-wide.
- Don't co-author with AI tools unless `docs/EXTRA.md` opts in. Many
  projects strip those trailers in CI.

## Pre-commit checklist (what to verify before `git commit`)

Run through this before every commit. The cost is seconds; the cost
of a broken main is hours.

1. **`git status`** — confirm exactly the files you intended are
   staged. No surprise `.env`, no editor swap files, no debug logs.
2. **`git diff --staged`** — read the diff. Watch for:
   - Stray `binding.pry`, `byebug`, `debugger`, `console.log`,
     `dbg!`, `puts` debug statements.
   - Hardcoded secrets, tokens, passwords, internal hostnames.
   - TODOs without a ticket reference.
   - Commented-out code blocks (delete them; git history is the
     archive).
3. **Project test suite** — the suite specified in `docs/EXTRA.md`
   (e.g., `bin/rspec`, `npm test`, `cargo test`). Don't commit red.
4. **Linter** — whichever the project declares (rubocop, eslint,
   clippy, prettier).
5. **No secrets** — `git diff --staged | grep -iE 'password|api_key|token|secret'`
   (false positives are fine; spend the seconds).
6. **Right branch** — `git rev-parse --abbrev-ref HEAD`. Easy to
   forget which branch you're on after switching tasks.

If the project ships a real pre-commit hook (`.git/hooks/pre-commit`
or via `pre-commit`/`lefthook`/`husky`), let it run. Don't skip with
`--no-verify` unless you understand exactly what is being skipped and
the user has authorized it.

## Anti-patterns

- Don't `git add .` — list files explicitly. The wildcard catches
  unintended files (especially `.env`).
- Don't amend pushed commits.
- Don't rebase shared branches; only rebase your own.
- Don't use `git reset --hard` to "clean up" without confirming you
  have no uncommitted work you care about.
- Don't run `git checkout .` or `git restore .` to undo edits without
  reading what you're about to lose.

## Commands / verification

- `git log --oneline -20` — quick history check.
- `git log --stat -1` — what files were touched in the last commit.
- `git diff main...HEAD` — what your branch adds vs main.
- `git fsck --full` — sanity-check repo integrity if something feels
  off.
