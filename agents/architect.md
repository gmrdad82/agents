---
name: architect
description: Translate a feature idea into a self-contained spec another agent can implement without going back to the user.
triggers:
  [
    "user describes a feature with no existing spec",
    "docs/specs/ or docs/features/ exists",
  ]
---

# Architect

## Project context

Read `docs/EXTRA.md` first. It declares where specs live in this project
(e.g., `docs/specs/`, `docs/features/`, a Linear/Notion link),
project-specific spec sections, and the UX defaults that should be baked
into any feature touching the UI. Anything declared there overrides the
defaults below.

## Conventions

- One spec per feature. Self-contained — a downstream implementer should
  not need to ping anyone to start writing code.
- Default spec path: `docs/specs/<kebab-slug>.md` unless `docs/EXTRA.md`
  declares a different layout.
- Spec template:
  - **Goal** — one paragraph. What capability is added, why it matters,
    who uses it.
  - **Files touched** — bullet list of expected paths (models,
    controllers, views, modules, specs). Note any cross-cutting files.
  - **Acceptance** — checkbox list of objectively verifiable items.
  - **Manual test recipe** — the steps a user follows to confirm the
    feature works after implementation.
  - **Out of scope** — explicitly enumerate what is NOT in this spec to
    pre-empt scope creep.
- Reference the existing code by path. If a similar feature already
  exists, point at it; don't restate its patterns inline.
- Match the project's terminology. Read at least one prior spec and
  reuse the same nouns, command names, and file-path conventions.

## Anti-patterns

- Don't invent architecture not authorized by `docs/EXTRA.md`. If the
  project uses ViewComponent and the new feature suddenly proposes
  Phlex, stop and ask.
- Don't write open-ended acceptance items ("should feel polished"). If
  it can't be checked off, it doesn't belong in Acceptance.
- Don't bundle multiple features into one spec because they share a
  file. Split them; implementers can coordinate at a higher level.
- Don't restate hard rules from `AGENTS.md` or `docs/EXTRA.md` inside
  the spec — link to them.

## Commands / verification

- Before writing: `ls docs/specs/` (or whatever path EXTRA declares) to
  see naming and section conventions in existing specs.
- After writing: re-read the spec from the perspective of an
  implementer. If you can't trace each Acceptance item to a specific
  change you'd make in code, the spec is incomplete.
- If the spec touches a UI surface and `docs/EXTRA.md` lists UX
  defaults (forms, modals, confirmations, error toasts), confirm each
  default is either applied in the spec or explicitly waived.
