---
name: rspec
description: RSpec test layout, factories, system specs, mocking policy for Ruby/Rails projects.
triggers:
  ["spec/ directory exists", 'Gemfile contains "rspec"', ".rspec file present"]
---

# RSpec

## Project context

Read `docs/EXTRA.md` first. It declares the project's spec directory
layout (mirrors `app/`? grouped by feature?), system-spec driver
(rack_test, Cuprite, Selenium), factory library (FactoryBot, Fabrication,
plain fixtures), shared-context conventions, mocking policy (real
collaborators by default vs heavy doubles), and the DB cleaner
strategy (transactional, truncation, deletion). Anything declared
there overrides the defaults below.

## Conventions

- Spec files mirror `app/`: `spec/models/user_spec.rb` tests
  `app/models/user.rb`.
- One `describe` per file at the top level — the class or module
  under test.
- `context` describes a state ("when the user is admin"), `describe`
  describes a method or behavior ("#authorize!"), `it` describes the
  expectation ("denies access to non-owners").
- Sentences start lowercase; no period at the end:
  `it 'returns the canonical url'`.
- One assertion per `it` when feasible. Multiple `expect` calls are
  fine when they assert facets of the same behavior.
- Use `let` for lazy setup, `let!` only when the side effect is the
  point. Use `before` for actions, not value definitions.
- Factories over fixtures unless `docs/EXTRA.md` says otherwise.
  `create(:user, trait, attr: value)` — minimum required to express
  the case.
- System specs cover happy paths and one or two critical failures
  per feature. Don't unit-test through the browser.
- Use `aggregate_failures` (block or `:aggregate_failures` metadata)
  when grouping assertions; saves you from playing whack-a-mole.

## Mocking

- Prefer real collaborators. Mocks lie when the underlying contract
  changes.
- Mock external services (HTTP, third-party APIs) with WebMock or VCR.
  Never let a spec touch the real network.
- Stub time with `travel_to` (ActiveSupport) or `Timecop` per
  project preference. Always `travel_back` / `Timecop.return`.
- `instance_double` and `class_double` over plain `double` — they
  verify the doubled object actually responds to the message.
- If a mock needs five `allow(...)` calls to keep a test passing,
  that's a smell. Inject a real collaborator or refactor.

## Anti-patterns

- Don't test private methods. Test the public behavior that uses them.
- Don't use `before(:all)` / `before(:context)` for state that
  mutates — test isolation will break in unpredictable ways.
- Don't `sleep` in specs to wait for async work. Use Capybara's
  waiting matchers (`have_content`, `have_selector`) — they poll.
- Don't write specs that pass only when run in a specific order.
  `--order random` should never go red.
- Don't use `allow_any_instance_of` — it's a sign the design needs
  changing. Inject the collaborator.
- Don't commit `focus: true` / `:focus` / `fit` / `fdescribe`.

## Commands / verification

- `bin/rspec` — full suite.
- `bin/rspec spec/models/user_spec.rb:42` — single example by line.
- `bin/rspec --tag focus` — run only focused (then remove the focus
  tag before commit).
- `bin/rspec --order random --seed 12345` — reproduce a flaky order.
- `bin/rspec --profile 10` — list the 10 slowest examples; useful
  when the suite starts dragging.
- For system specs, screenshot on failure (Capybara does this by
  default into `tmp/screenshots/` or wherever `docs/EXTRA.md` declares).
