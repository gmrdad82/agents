---
name: shell
description: Write and maintain Bash scripts under bin/, scripts/, or similar.
triggers:
  ["bin/*.sh present", "scripts/ present", "user asks for a shell script"]
---

# Shell

## Project context

Read `docs/EXTRA.md` first. It may declare the target Bash version
(some projects need POSIX sh; most assume Bash 5+), the canonical
location for scripts, and whether scripts must be Linux-only or
cross-platform (macOS BSD vs GNU coreutils differences). Anything
declared there overrides the defaults below.

## Conventions

- First line: `#!/usr/bin/env bash`. Never hard-code `/bin/bash`.
- Second line: `set -euo pipefail`. Add `IFS=$'\n\t'` if iterating
  whitespace-sensitive input.
- Quote every variable expansion. `"$var"`, never bare `$var`. Same
  for command substitution: `"$(cmd)"`.
- Use `[[ ... ]]` for tests, not `[ ... ]`. Use `(( ... ))` for
  arithmetic.
- Functions return via exit code (0 = success, non-zero = failure).
  Use stdout for the function's "return value", stderr for diagnostics.
- Use `printf '%s\n' "$x"` instead of `echo "$x"` when `$x` may begin
  with `-` or contain backslashes.
- Long flag names in scripts (`--include` not `-i`) — they read better
  in invocations and resist typo-induced bugs.
- Use `mktemp -d` for temp dirs. Trap them for cleanup:
  `trap 'rm -rf "$tmpdir"' EXIT`.
- Group related commands into functions, even single-call ones, when
  they pair with a meaningful name.
- Print actionable error messages — what failed and what the user
  should do next. Send them to stderr: `>&2`.

## Anti-patterns

- Don't pipe to `sh` or `bash` from a `curl`. Tell the user to inspect
  and run, never auto-execute.
- Don't `cd` without checking the result: `cd "$dir" || exit 1`.
- Don't parse `ls`. Use globs or `find -print0 | xargs -0`.
- Don't use `eval` on user input.
- Don't silently swallow errors with `|| true` unless you've thought
  about what happens when the LHS fails for a reason you didn't expect.
- Don't iterate with `for f in $(ls)` — globs handle spaces; `ls`
  output does not.

## Commands / verification

- `shellcheck bin/*.sh` — required clean. Disable individual rules
  inline with `# shellcheck disable=SCxxxx` only with a justification
  comment.
- `bash -n script.sh` — syntax check without executing.
- `bash -x script.sh` — trace execution for debugging.
- For destructive flows, support `--dry-run` that prints what would
  happen without doing it. Verify the dry-run is a true no-op.
