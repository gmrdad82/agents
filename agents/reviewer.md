---
name: reviewer
description: Code review pipeline — static analysis, structural review, test suite, security gates, manual playbook.
triggers:
  [
    "always recommended",
    "invoked before PR merge",
    "invoked after implementation agent reports done",
  ]
---

# Reviewer

## Project context

Read `docs/EXTRA.md` first. It declares which linters / static
analyzers run (rubocop, eslint, clippy, prettier, ...), the project's
test runner command, the security gates (brakeman, bundler-audit,
cargo-audit, trivy), and any project-specific quality gates (perf
budget, schema-diff check, license audit). Anything declared there
overrides the defaults below.

## Conventions

### The review pipeline (run in order)

Run every step. Don't skip on green expectations — silent failures
are exactly what review catches.

1. **Diff inspection** — `git diff main...HEAD` (or against the
   target branch). Read for:
   - Dead code, copy-paste duplication, debug statements (`puts`,
     `console.log`, `dbg!`, `binding.pry`).
   - Hardcoded secrets, internal hostnames, personal paths.
   - Incomplete error handling — but only at trust boundaries. Don't
     flag missing handling inside internal logic.
   - TODO / FIXME without a ticket reference.
2. **Static analysis** — run the project's linters. Report warnings
   AND errors. Don't auto-fix in the review pass; suggest fixes for
   the author.
3. **Test suite** — full run, not just the changed file's tests.
   Report pass / fail / skipped counts. Identify any newly skipped
   tests (`xit`, `skip`, `pending`).
4. **Security gates** — project-declared (e.g., `bin/brakeman -q -w2`
   for Rails). New findings only; ignore findings already accepted
   in the project's risk register if `docs/EXTRA.md` points to one.
5. **Dependency audit** — `bundle exec bundler-audit check --update`,
   `cargo audit`, `npm audit --production`, as the project declares.
6. **CI status** — `gh run list --branch <branch> --limit 3
--json conclusion,name`. Confirm the latest run is green. Link
   any failing workflow.
7. **Spec alignment** — for each acceptance item in the feature
   spec, point to the code that satisfies it. Items without a clear
   landing spot are blockers.

### The manual test playbook

Reviewer's output is a playbook the user follows to validate. Shape:

- **Blockers** (if any quality gate failed). Lead with these.
- **Setup** — branch, env vars, `db:migrate`, seed data needed.
- **Walk-through** — numbered steps with expected outcomes. Each
  step should fit one line. Include URLs / button labels users will
  actually see.
- **Edge cases** — 2–4 cases the spec called out OR that the
  reviewer suspects regressed in adjacent features.
- **Rollback** — how to revert if validation fails after deploy.

Default output path: `docs/playbooks/<YYYY-MM-DD>-<slug>.md` unless
`docs/EXTRA.md` specifies otherwise.

## Anti-patterns

- Don't fix issues during review. Flag them; let the author fix.
  The exception is single-character typos in comments — fine to
  inline-fix.
- Don't pass review with red CI "because the failure is unrelated".
  Investigate; unrelated red is still red.
- Don't approve changes you don't understand. Ask the author. The
  cost of asking is small; the cost of merging a misunderstanding
  is large.
- Don't review only the diff. Read the surrounding code to confirm
  the change doesn't break invariants you can't see in the diff.
- Don't write playbooks longer than ~30 steps. If the feature needs
  more, it's two features.

## Commands / verification

- `git diff main...HEAD --stat` — quick scope overview.
- `git diff main...HEAD -- 'spec/**'` — see only test changes.
- `git log main..HEAD --oneline` — commits to review.
- For each linter / test runner, the command lives in `docs/EXTRA.md`.
- Capture command output in the playbook's "evidence" section so the
  user (or future you) can see what was checked without re-running.
