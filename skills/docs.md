---
name: docs
description: Write and maintain Markdown documentation — READMEs, guides, runbooks, ADRs.
triggers:
  [
    "docs/ directory exists",
    "README.md present",
    "user asks for docs/runbook/ADR",
  ]
---

# Docs

## Project context

Read `docs/EXTRA.md` first. It declares the project's docs layout
(where guides vs runbooks vs ADRs live), tone conventions, link
conventions (relative vs absolute), and any required headers (front
matter, license stub, table-of-contents marker). Anything declared
there overrides the defaults below.

## Conventions

- Markdown wraps at 80 columns for prose. Tables, code blocks, and
  long URLs are exempt — prettier preserves them as-is.
- One H1 per file. Use sentence case for headings unless `docs/EXTRA.md`
  specifies title case.
- Lead with the takeaway, then the detail. The first paragraph should
  answer "what is this and when do I need it?" — not history.
- Code blocks specify a language fence (` ```bash`, ` ```ruby`).
- Internal links are relative paths (`../guides/foo.md`), not absolute
  URLs to the GitHub blob view.
- Runbooks have a fixed shape: **Symptom**, **Diagnose**, **Fix**,
  **Verify**, **Escalate**. Each section is a few bullets, not paragraphs.
- ADRs (Architecture Decision Records) have: **Status** (proposed /
  accepted / superseded), **Context**, **Decision**, **Consequences**.
- Diagrams are Mermaid when possible (renders in GitHub + most viewers
  without external tooling). Save ASCII for terminal-only contexts.

## Anti-patterns

- Don't write a 500-word "Introduction" before the reader can do
  anything. Get to the command or code by paragraph two.
- Don't duplicate content across files. If two guides need the same
  setup steps, factor them into a third doc and link.
- Don't write docs that paraphrase what the code already says clearly.
  Document the WHY (constraints, tradeoffs, prior incidents), not the
  WHAT.
- Don't use emoji decoration unless `docs/EXTRA.md` explicitly allows.
- Don't pretend a feature exists before it ships. Mark planned content
  with a `> **Planned:**` blockquote so readers know.

## Commands / verification

- `npx --yes prettier@latest --check '**/*.md'` — formatting check.
- `npx --yes prettier@latest --write '**/*.md'` — apply formatting.
- For internal-link integrity, `grep -rn '\](.*\.md)' docs/` then
  spot-check the linked paths exist.
- Read the doc out loud (or have the LLM summarize it). If the summary
  doesn't match your intent, restructure the lead.
