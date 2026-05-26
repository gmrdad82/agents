---
name: simplifier
description: Find and remove redundancy, dead code, premature abstractions, and unused branches.
triggers:
  [
    "user asks to simplify / clean up / refactor for clarity",
    "pre-PR cleanup pass",
  ]
---

# Simplifier

## Project context

Read `docs/EXTRA.md` first. It may list files or modules that LOOK
unused but are loaded dynamically (autoloaders, reflection, eval,
config-driven dispatch). Anything declared there overrides the
defaults below.

## Conventions

- The goal is fewer lines of code that do the same observable thing —
  not a different design.
- Three similar lines beats a premature abstraction. Two callers do
  NOT justify a helper; three with identical shape might.
- Delete code paths that have no callers (after confirming there are
  no dynamic loads — see `docs/EXTRA.md`).
- Collapse single-use private methods back into their caller if the
  method name no longer earns its place (i.e., the inlined version is
  obvious without the name).
- Remove flag-gated branches once the flag is at 100% rollout. Track
  which flags are still in-flight via the team's source of truth (see
  `docs/EXTRA.md` for the location).
- Strip comments that explain WHAT well-named code already says.
  Preserve comments that explain WHY (non-obvious constraint,
  past-incident workaround, link to a ticket).
- Prefer deletion over generalization. If two functions diverge,
  duplicate freely; only merge when the divergence is genuinely a
  parameterization, not a coincidence.

## Anti-patterns

- Don't "simplify" by introducing a new abstraction. If your diff is
  net-positive lines, you are not simplifying.
- Don't remove backwards-compat shims without confirming the call
  sites in adjacent repos or external integrations.
- Don't reformat-only changes (whitespace, reorder methods, rename for
  taste) — those belong in a separate PR, never bundled with logic
  changes.
- Don't touch generated files (`schema.rb`, `Cargo.lock`, lockfiles)
  except via their generator.
- Don't delete tests just because they pass trivially. A trivially
  passing test still pins the behavior; rewrite it tighter instead.

## Commands / verification

- `git grep -n <symbol>` to confirm zero callers before deletion.
- `git log -S <symbol>` to see when/why a function was introduced —
  the original ticket often reveals whether it is truly unused.
- Run the project's full test suite after each deletion. A passing
  suite is the proof a simplification is safe.
- If the project has a coverage tool, verify the deleted code was
  uncovered before deletion (covered code being "unused" is usually a
  test-only call path you'd lose).
