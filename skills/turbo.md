---
name: turbo
description: Hotwire Turbo — Drive, Frames, Streams, broadcasts. Progressive enhancement over plain HTML.
triggers:
  [
    'Gemfile contains "turbo-rails"',
    "@hotwired/turbo in package.json",
    "turbo-frame / turbo-stream tags in views",
  ]
---

# Turbo

## Project context

Read `docs/EXTRA.md` first. It declares whether the project uses
Turbo Drive (the default — full-page nav over fetch), how Turbo
Streams are delivered (HTTP responses vs ActionCable broadcasts vs
both), the morphing strategy (idiomorph / replace), and any
custom Turbo events the project listens for. Anything declared
there overrides the defaults below.

## Conventions

### Drive

- Drive is on by default. Disable per-link with `data-turbo="false"`
  only when an external redirect or a third-party form submission
  needs full-page navigation.
- Use `data-turbo-method="delete"` for destructive links — Turbo
  generates a hidden form so non-GET works without writing one.
- Preserve scroll with `data-turbo-action="advance"` (default) or
  `replace` when navigating within the same conceptual page.
- Permanent elements (player, banner) get `data-turbo-permanent`
  - a stable `id`; Turbo preserves them across navigations.

### Frames

- A `<turbo-frame id="x">` is a self-contained piece. Any link or
  form inside it whose response also contains a `<turbo-frame id="x">`
  swaps that frame's contents.
- Lazy frames (`<turbo-frame src="/path">`) defer loading until
  visible. Use them for sidebar panels, secondary data.
- Frame IDs are stable contracts. Renaming a frame breaks all
  responses that target it.
- For breaking out of a frame on a specific action (e.g., login
  redirect from a modal frame), respond with `Turbo.visit` via a
  Turbo Stream `<turbo-stream action="redirect">` or use
  `data-turbo-frame="_top"`.

### Streams

- Streams are deltas — `append`, `prepend`, `replace`, `update`,
  `remove`, `before`, `after`, `refresh`, `morph`.
- One stream tag per change. Multiple `<turbo-stream>` tags in one
  response are fine.
- Don't render a whole page as a stream. Streams are for partial
  DOM updates; if you need a full page, use Drive.
- Broadcasted streams from models (`broadcasts_to :user`) deliver
  via ActionCable to every subscriber. Authorize the subscription;
  the broadcast does not re-authorize per recipient.

### Morphing

- Page morphing (`<meta name="turbo-refresh-method" content="morph">`)
  preserves form input and scroll across refresh. Useful for live-
  reloading admin dashboards.
- Frame morphing: `refresh="morph"` on the frame.
- Morphing is idempotent: the same DOM produces the same result.
  Don't put random IDs in morph-eligible regions.

## Anti-patterns

- Don't return a 200 with no Turbo Stream tag from a stream-expected
  endpoint. Turbo will swap the empty body and confuse users.
- Don't redirect with a 302 from an XHR form submission — Turbo
  expects 422 for validation errors so it can re-render the form.
  Use `unprocessable_entity` for invalid input.
- Don't put JS event listeners on `DOMContentLoaded`. Use
  `turbo:load` (fires after every navigation).
- Don't fight Turbo by removing `data-turbo` on every link. If you
  need server-rendered SPA-like flows, embrace it; if not, use
  plain HTML and disable Drive globally.
- Don't broadcast streams to the entire user base ("everyone in this
  room"). Authorize the subscription, and pre-filter on the server.

## Commands / verification

- Browser DevTools → Network → filter "doc" — Drive requests appear
  as `text/html` XHR responses.
- DevTools → Network → filter "stream" or look for
  `Content-Type: text/vnd.turbo-stream.html` for stream responses.
- For broadcasts: tail the Rails log; `Turbo::StreamsChannel
transmitting` lines show each broadcast.
- Use `Turbo.session.drive = false` in the JS console to disable
  Drive temporarily for debugging.
- Test with JS disabled where progressive enhancement matters — the
  base page should still work, just without the live updates.
