---
name: rails
description: Ruby and Ruby on Rails conventions — controllers, models, services, ERB, generators, gems.
triggers:
  [
    'Gemfile contains "rails"',
    "config/application.rb exists",
    "app/controllers/ exists",
  ]
---

# Rails

## Project context

Read `docs/EXTRA.md` first. It declares the project's view layer
(ERB, ViewComponent, Phlex), JS framework (Stimulus + Turbo unless
overridden), service-object pattern (plain POROs, `dry-rb`,
Interactor), background-job adapter (Sidekiq, Solid Queue, GoodJob),
auth (Devise, custom, Rodauth), the test directory layout, and any
project-specific conventions for naming, error handling, and API
shape. Anything declared there overrides the defaults below.

## Conventions

### Ruby

- Two-space indent, no tabs. Use `# frozen_string_literal: true` at
  the top of every Ruby file unless `docs/EXTRA.md` opts out.
- Prefer keyword arguments for any method with more than one
  parameter. Positional args are fine for single-param methods.
- Use `attr_reader` (not bare `@var` access in methods) when the
  value is set once at init.
- Use guard clauses (`return unless x`) at the top of methods rather
  than nested `if` blocks.
- Use `.then` / `.tap` for pipelines and assertions; don't overuse.
- Constants in `SCREAMING_SNAKE_CASE`. Classes / modules in
  `CamelCase`. Methods / variables in `snake_case`.

### Rails app structure

- Stick to convention-over-configuration. Don't relocate `app/models`,
  `app/controllers`, etc.
- Service objects under `app/services/<domain>/<verb>.rb`. Single
  public method (`call`), instance state minimal.
- Decorators / presenters: prefer ViewComponent over Draper unless
  `docs/EXTRA.md` declares otherwise.
- Form objects under `app/forms/` when a controller action posts to
  multiple models — keeps controllers thin.
- Concerns under `app/{models,controllers}/concerns/` only when
  shared between 3+ classes. Two callers do not justify a concern.
- ERB partials under `app/views/<resource>/_<name>.html.erb`. Pass
  locals explicitly with `locals: { ... }`; never rely on instance
  variables in partials.
- Stimulus controllers under `app/javascript/controllers/`. One
  controller per file, named `<thing>_controller.js`.

### ActiveRecord

- Migrations always reversible. Use `change` not `up`/`down` unless
  the operation can't be inferred.
- Add database-level constraints (`null: false`, `unique: true`,
  foreign keys) — model validations are a UX layer, not data
  integrity.
- Use `references` with `foreign_key: true, null: false` for required
  associations.
- Avoid N+1: `includes`, `preload`, or `eager_load` as appropriate.
  `bullet` gem (dev/test) helps spot them.
- Scopes return relations, methods return values. Don't mix.
- Use `find_each` / `in_batches` for any iteration over more than a
  few hundred records.

### Controllers

- Skinny controllers — instantiate a service / form, render its
  result.
- One resource per controller, RESTful actions only. If you need a
  seventh action, you probably need a new controller.
- Use strong parameters; never `params.permit!` without a reason.
- Render JSON via `Jbuilder`, `ActiveModel::Serializer`, or whatever
  `docs/EXTRA.md` specifies — not raw `render json:` for non-trivial
  shapes.

### Gems

- Add a gem only when its problem is non-trivial and load-bearing.
  Prefer a 20-line PORO over a 50KB gem for one-off needs.
- Pin Gemfile versions for production gems (`~> 1.2`); leave dev
  gems unpinned within reason.
- Run `bundle outdated` periodically; security-pin via `bundler-audit`.

## Anti-patterns

- Don't introduce React, Vue, Svelte, or other JS frameworks unless
  `docs/EXTRA.md` explicitly authorizes — Rails default is Hotwire.
- Don't write callbacks (`before_save`, `after_create`) for cross-
  model behavior. Use service objects; callbacks make tests painful
  and side effects invisible.
- Don't use `update_column` to bypass validations or callbacks
  without a comment explaining why.
- Don't add `default_scope` — it bites every developer who later
  forgets it's there.
- Don't put business logic in views or helpers. If a helper exceeds
  ten lines, it's a service or a component.
- Don't introduce a new auth library if the project already has one.
- Don't add `byebug` / `binding.pry` / `puts` to committed code.

## Commands / verification

- `bin/rails db:migrate` after schema changes; verify `db/schema.rb`
  (or `db/structure.sql`) updated cleanly.
- `bin/rails db:rollback` to confirm migrations are reversible.
- `bin/rspec` (or whatever `docs/EXTRA.md` declares) for affected
  specs at minimum; full suite before declaring done.
- `bundle exec rubocop` for style — see `docs/EXTRA.md` for the
  project's `.rubocop.yml` overrides.
- `bin/brakeman -q -w2` for security findings; report new ones, do
  not auto-suppress.
- For view changes, render the affected page at least once in a
  browser or system spec — broken layouts often pass model tests.
