---
name: github
description: GitHub workflows via the gh CLI — PRs, issues, Actions, releases, gh api calls.
triggers:
  [
    ".github/ directory exists",
    "remote is github.com",
    "user asks about PRs / issues / Actions",
  ]
---

# GitHub

## Project context

Read `docs/EXTRA.md` first. It declares the project's PR template
sections, required labels, the base branch, review-required policy,
release-naming convention, and any custom Actions the project depends
on. Anything declared there overrides the defaults below.

## Conventions

- Use `gh` CLI rather than the web UI for any scriptable operation.
  It's faster and leaves a trail.
- PR titles: imperative mood, ≤ 70 chars. Detail goes in the body,
  not the title.
- PR body sections (default unless `docs/EXTRA.md` says otherwise):
  - **Summary** — 1-3 bullets.
  - **Test plan** — a checklist the reviewer can walk through.
  - **Screenshots / output** — when UI or CLI behavior changed.
- Link related issues with `Closes #123` / `Fixes #123` in the PR
  body so they auto-close on merge.
- For multi-commit PRs, ensure each commit on its own would build and
  test green — easier for reviewers using "Review changes per commit".
- Releases: tag from `main` after CI is green. Use semantic versions
  unless `docs/EXTRA.md` specifies otherwise.

## Common gh commands

- `gh pr create --title "X" --body "$(cat <<'EOF' ... EOF)"` — create
  PR with multiline body.
- `gh pr view --json title,body,state,reviews` — inspect a PR.
- `gh pr checks` — list CI checks on the current PR.
- `gh pr diff` — view the diff for the current PR.
- `gh pr merge --squash --delete-branch` — squash-merge and clean up.
- `gh run list --branch main --limit 5 --json conclusion,name,headBranch`
  — recent CI runs on a branch.
- `gh run view <run-id> --log-failed` — fetch only failed-step logs.
- `gh issue list --label bug --state open` — filter issues.
- `gh api repos/:owner/:repo/...` — raw REST when no subcommand fits.
- `gh release create v1.2.3 --notes "..."` — cut a release.

## Anti-patterns

- Don't push directly to `main` if branch protection requires PRs.
- Don't merge with red CI without explicit user authorization.
- Don't dismiss reviewer comments by force-pushing over them —
  address them in a follow-up commit so the conversation thread
  stays intact.
- Don't run destructive `gh api` calls (DELETE on PRs, branches,
  releases) without dry-running the request URL first.
- Don't store PATs or tokens in repo files. Use `gh auth login` or
  `GH_TOKEN` env var, scoped minimally.

## Commands / verification

- `gh auth status` — confirm you're logged in and which scopes you
  hold.
- `gh repo view --json defaultBranchRef,visibility,isPrivate` — sanity
  check before destructive operations.
- Before merging: `gh pr checks` (all green) + `gh pr view --json
reviews` (approvals satisfied).
- After merging: confirm the branch was deleted (`gh pr view --json
state,mergeCommit`).
