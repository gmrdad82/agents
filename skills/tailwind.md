---
name: tailwind
description: Tailwind CSS utility-first conventions, theming, component extraction, dark mode.
triggers:
  [
    "tailwind.config.* present",
    '@import "tailwindcss" in CSS',
    "tailwindcss in package.json",
  ]
---

# Tailwind

## Project context

Read `docs/EXTRA.md` first. It declares the Tailwind version (v3 vs
v4 differ on config and tokens), the theme tokens (colors, spacing,
fonts), the dark-mode strategy (`media` vs `class` vs `selector`),
the component library on top (DaisyUI, ViewComponent partials,
plain partials), and any custom plugins. Anything declared there
overrides the defaults below.

## Conventions

- Utility-first. Reach for `@apply` only when a utility cluster
  recurs in 3+ places AND naming the cluster meaningfully helps
  readability.
- Order utilities consistently: layout → box model → typography →
  color → state. Or use `prettier-plugin-tailwindcss` to enforce.
- Responsive prefixes (`md:`, `lg:`) at the end of the class list
  by convention — easier to scan.
- State variants stack right-to-left: `hover:focus:bg-blue-500`
  means hover AND focus.
- Use theme tokens (`text-primary`, `bg-surface`) not raw colors
  (`text-blue-500`) once tokens are defined. Tokens centralize
  design-system changes.
- For complex repeated UI, extract to a component (ViewComponent,
  React component, Astro component) — not a Tailwind `@apply` blob.
  Components carry behavior; CSS doesn't.
- `space-x-*` / `space-y-*` for inline spacing; `gap-*` inside flex
  / grid. Don't margin-collapse-fight.
- Dark mode: the `dark:` variant only works if config matches. v3
  defaults to `media`; most projects switch to `class` for user
  toggle support.
- Arbitrary values (`top-[17px]`, `bg-[#1a1a1a]`) are an escape
  hatch — flag them in review. Most should become tokens.

## Anti-patterns

- Don't string-concat Tailwind classes from variables in templates.
  Tailwind's JIT scanner won't find them and they'll be purged from
  production CSS. Use full class names with conditionals.
- Don't write raw CSS that duplicates utilities. If you find
  yourself writing `padding: 1rem`, use `p-4`.
- Don't use `!important` (`!bg-red-500`) to win specificity battles.
  Reorder selectors or restructure.
- Don't override Tailwind's color palette wholesale unless the
  design system genuinely doesn't use it. Extend, don't replace.
- Don't add a CSS preprocessor (Sass, Less) on top of Tailwind for
  styling. Use it only for build orchestration if needed.

## Commands / verification

- `npx tailwindcss --watch` (v3) or the v4 equivalent for local dev
  if not running through the framework's pipeline.
- `npx tailwindcss --minify -o build/app.css` — production build,
  check the size.
- Check the production CSS size after big PRs. If it grew > 10%,
  something is wrong (typically: dynamic class names defeating
  purge, or duplicate utility libraries).
- For dark mode: toggle the strategy in DevTools (add `class="dark"`
  on `<html>` and re-render). Confirm contrast is acceptable on
  hover / focus / disabled states too.
- Run the project's a11y check (axe, pa11y) — utility-first makes
  it easy to accidentally drop focus rings or label associations.
