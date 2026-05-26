---
name: action-cable
description: Rails ActionCable — channels, subscriptions, broadcasting, authentication, testing.
triggers:
  [
    "app/channels/ exists",
    "config/cable.yml present",
    "Turbo Streams over WebSocket in use",
  ]
---

# ActionCable

## Project context

Read `docs/EXTRA.md` first. It declares the project's adapter
(`redis`, `postgresql`, `async` — only `async` is acceptable in dev /
test), the auth strategy used in `ApplicationCable::Connection`,
whether channels are namespaced per tenant, and how Turbo Streams
broadcasts are wired (model callbacks vs explicit `broadcast_*`).
Anything declared there overrides the defaults below.

## Conventions

### Connection

- `ApplicationCable::Connection` authenticates once at handshake.
  Pull the session cookie or a JWT — never trust a `user_id` query
  param.
- Reject unauthenticated connections explicitly with `reject_unauthorized_connection`.
- Set `identified_by :current_user` (or `:current_account`) so
  channels can call `current_user` without re-authenticating.

### Channels

- One channel per real-time surface (chat, notifications, presence).
  Don't multiplex unrelated concerns through one channel — clients
  can't unsubscribe selectively.
- `subscribed` must authorize the stream. Verify the user can read
  the resource before calling `stream_for`.
- Use `stream_for(record)` over `stream_from("string")` when the
  resource is a model — Rails handles the channel name.
- `unsubscribed` is a no-op only if you genuinely have no cleanup.
  Otherwise tear down presence, timers, locks.
- Channel actions are sparse. Most real-time UIs broadcast one-way
  from the server; rich two-way protocols belong in a dedicated
  service.

### Broadcasting

- Broadcast from models or service objects, never from controllers
  (controllers should be sync HTTP). Use `after_commit` callbacks or
  Turbo's `broadcasts_to`.
- Payloads are small. Don't broadcast a full HTML body when an ID is
  enough — let the client refetch (or use Turbo Stream frames).
- For Turbo Streams: `<model>.broadcast_replace_to(target, partial:, locals:)`
  and similar. The partial path is canonical; don't render inline.
- Broadcasts during a transaction fire on commit (with `after_commit`).
  Don't broadcast inside the transaction itself — subscribers may
  see state that doesn't yet exist in the DB.

### Authorization

- `subscribed` is the authorization layer. Treat it like a
  controller action — call Pundit / your policy class.
- If the resource is revoked (membership removed), broadcast a
  "kick" message and call `reject` on the server side; clients
  should re-subscribe and get refused.

## Anti-patterns

- Don't broadcast the same payload twice — once from a callback and
  once from a service. Pick one source of truth.
- Don't use the `async` adapter outside dev / test. Production needs
  Redis (or Postgres, which has limits).
- Don't ignore client reconnect. The client reconnects automatically;
  the server should re-authenticate and re-authorize on each new
  subscription.
- Don't hold long locks or DB transactions inside channel callbacks.
  ActionCable runs in a small worker pool; blocking starves other
  clients.
- Don't include sensitive data (other users' IDs, internal counts)
  in broadcasts a client could inspect.

## Commands / verification

- `bin/rails console` then `<Model>.broadcast_replace_to(:foo, ...)`
  to manually fire a broadcast and confirm clients receive it.
- Browser devtools → Network → WS to inspect the WebSocket frames.
  Confirm payloads are what you expect.
- For specs: ActionCable's `have_broadcasted_to` matcher
  (`expect { ... }.to have_broadcasted_to(channel).with(...)`).
- Load test with a tool that supports WebSocket (e.g., `artillery`,
  `wrk2` with a WS plugin) before relying on cable for
  high-concurrency surfaces.
- `redis-cli pubsub channels '*'` to inspect active subscriptions
  on the Redis adapter.
