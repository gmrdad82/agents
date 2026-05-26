---
name: mcp
description: Model Context Protocol servers — tool surface design, transport, schemas, integration with Claude / OpenCode.
triggers:
  [
    "mcp / @modelcontextprotocol/sdk in dependencies",
    ".mcp.json or mcp-server* directory",
    "user mentions MCP / tool surface",
  ]
---

# MCP

## Project context

Read `docs/EXTRA.md` first. It declares which MCP servers the
project ships, the transport (stdio for local subprocess, HTTP/SSE
for remote), the auth model (none / token / OAuth), the tools'
intended audience (Claude Desktop, Claude Code, OpenCode, Cursor),
and the deployment model (local binary, Docker, hosted). Anything
declared there overrides the defaults below.

## Conventions

### Server design

- One server per coherent capability surface. Don't ship "everything
  about X" — clients enable/disable per server.
- Tools have tight, action-oriented names: `create_issue`,
  `search_files`, `query_warehouse` — not `do_stuff`, `helper`.
- Tool descriptions are read by the LLM to decide when to call.
  Write them for that audience: state the tool's purpose, when to
  use it, when NOT to use it, what the result looks like.
- Parameters: descriptive names, JSON Schema with `description` on
  every field, `required` enumerated explicitly, sensible defaults.
- Return structured `content` blocks (text, image, resource). For
  large results, return a `resource` reference instead of inlining
  10KB of text — the client can fetch on demand.
- Errors return `isError: true` with a human-readable message the
  model can use to retry or escalate. Don't throw exceptions across
  the wire.

### Resources

- Use resources for "things the LLM might want to read": files,
  documents, query results. Tools are for actions.
- `uri` is the canonical identifier — make them stable so prompts
  caching them works.
- `mimeType` honestly. `text/plain` for plain text, `application/json`
  for structured data, the right type for images / binaries.

### Prompts

- A prompt is a reusable parameterized template the user can
  invoke. Useful for `/<slash>` workflows in clients that support
  them.
- Don't ship prompts that duplicate what the tool descriptions
  already convey.

### Transport

- **stdio** — default for local servers. Simpler, no port
  management, secure by default.
- **HTTP / SSE** — for hosted / shared servers. Auth + TLS
  required; logging + rate limits expected.
- Don't ship a server that opens an arbitrary network listener
  without auth — it's a confused-deputy risk.

### Auth (when applicable)

- Bearer tokens via `Authorization` header on HTTP transport.
- OAuth 2.1 for end-user-impersonating servers (per the MCP spec's
  auth section).
- Never accept `?token=` in URLs — leaks via referrer / logs.

### Schemas

- JSON Schema 2020-12. Validate inputs server-side; the client
  validates too, but you can't trust that.
- Use enums for closed sets. Use `format` for strings (`uri`,
  `email`, `date-time`).
- Add example values (`examples: [...]`) — they show up in some
  clients' UIs and help the model.

## Anti-patterns

- Don't expose destructive operations without a confirmation flag
  (`confirm: true`) the model has to explicitly set. Don't make
  `delete_repo` a single-tool call with no guard.
- Don't include credentials in tool responses. The model sees them
  and may echo them back.
- Don't log full tool payloads at INFO. They contain user data;
  use DEBUG and rotate.
- Don't return shell command output unfiltered. Strip ANSI, cap
  size, redact paths that leak internal layout.
- Don't ship a server that requires write access to the user's
  filesystem without scoping (root path argument). "Anywhere"
  scope is a footgun.

## Commands / verification

- `npx @modelcontextprotocol/inspector` — interactive client to
  test tools / prompts / resources during development.
- For Claude Desktop: edit `~/Library/Application Support/Claude/
claude_desktop_config.json` (mac) or the platform equivalent;
  restart the app to reload.
- For Claude Code: `~/.claude/settings.json` `"mcpServers": { ... }`
  or per-project `.mcp.json`. `/mcp` lists servers + connection
  state.
- Log every tool call with parameters (redacted) + result size
  during development. Surprises (wrong tool selected, repeated calls
  in a loop) are invisible without the trace.
- Test against multiple clients (Claude Desktop, Claude Code,
  OpenCode, Cursor). Subtle schema differences trip clients up.
