---
name: security
description: Security audit pass — auth, authorization, input validation, secrets, dependencies, OWASP top 10.
triggers:
  [
    "user asks for security review",
    "pre-release / pre-deploy gate",
    "CVE in a dependency",
  ]
---

# Security

## Project context

Read `docs/EXTRA.md` first. It declares the project's auth library,
session storage, encryption-at-rest policy, secrets management
(env vars, Vault, AWS Secrets Manager, Rails credentials), the
threat model, the responsible-disclosure / coordinated-disclosure
process, and any accepted-risk register. Anything declared there
overrides the defaults below.

## Conventions

### What to audit (every pass)

- **Authentication** — login, signup, password reset, MFA, session
  lifetime, remember-me cookies, OAuth callbacks. Check for:
  - Timing-safe comparisons on tokens (`ActiveSupport::SecurityUtils.secure_compare`,
    `crypto.timingSafeEqual`).
  - Rate limiting on login + reset endpoints.
  - Password storage: bcrypt / argon2 / scrypt with sane cost.
    Never SHA / MD5 / unsalted.
  - Session fixation: regenerate session on login.
- **Authorization** — every controller action, every channel, every
  job, every background script that touches user data. Check:
  - Pundit / Cancancan / equivalent policies exist and are invoked.
  - IDOR — does the action verify the resource belongs to the
    current user / tenant?
  - Mass assignment — strong params, not `permit!`.
- **Input validation** — at trust boundaries (HTTP params, file
  uploads, third-party webhooks, queue payloads). Whitelist, not
  blacklist.
- **Output encoding** — XSS in views (`html_safe` only on truly
  safe content), SQL injection (parameterized queries — never
  string-interpolated `where("name = '#{x}'")`), shell injection
  (`Open3.capture3` with array args, never `system("cmd #{x}")`).
- **Secrets** — `git log -p | grep -iE 'password|api_key|token|secret'`.
  No secrets in code, in commit history, in error messages, or in
  logs. Use the project's secret store.
- **Transport** — HTTPS everywhere, HSTS header, secure / httpOnly
  / samesite cookies, no mixed content.
- **Dependencies** — `bundler-audit`, `cargo audit`, `npm audit`,
  `pip-audit`. Triage advisories: confirm the vulnerable code path
  is reachable before raising the alarm.
- **File uploads** — validate content-type AND magic bytes, cap
  size, store outside the web root, sanitize filenames, never
  execute uploaded content.
- **CSRF** — Rails has it on by default. Check that any `skip_before_action
:verify_authenticity_token` has a justification (typically: a
  webhook with its own signature verification).
- **CSP** — Content-Security-Policy header set, no `unsafe-eval`
  unless reviewed, `nonce` for inline scripts, report-uri configured.

### Reporting findings

- Categorize: **Critical** (active exploitation possible),
  **High** (exploitable with auth), **Medium** (exploitable in
  uncommon configurations), **Low** (defense-in-depth).
- For each finding: file:line, the attack scenario, the suggested
  fix, the false-positive rate (your confidence).
- Critical findings get a coordinated-disclosure path — don't open
  a public issue. See `docs/EXTRA.md` for the project's process.

## Anti-patterns

- Don't trust client-side validation. It's UX, not security.
- Don't use `eval` / `instance_eval` / `Marshal.load` / `pickle.loads`
  on user-controlled input.
- Don't roll your own crypto. Use the language's standard library
  (`OpenSSL`, `libsodium`, `crypto`) and well-known constructions.
- Don't disable SSL verification (`verify_mode = VERIFY_NONE`,
  `rejectUnauthorized: false`) in production. Test environments,
  fine; production, never.
- Don't include user input in regex without `Regexp.escape` — ReDoS.
- Don't return different error messages for "user not found" vs
  "wrong password" — user enumeration.

## Commands / verification

- `bin/brakeman -q -w2` — Rails static analysis.
- `bundle exec bundler-audit check --update` — Ruby deps.
- `cargo audit` — Rust deps.
- `npm audit --production` — Node prod deps.
- `gitleaks detect` or `trufflehog filesystem .` — secret scan.
- `nuclei -u <url>` — broad-spectrum vuln scan for web apps (test
  envs only).
- For the diff: `git diff main...HEAD | grep -E '(password|secret|api_key|token|api-key)'i`
- Browser DevTools → Security tab → confirm HTTPS chain, CSP, HSTS.
