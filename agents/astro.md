---
name: astro
description: Astro static sites — content collections, integrations, partial hydration, deployment.
triggers:
  [
    "astro.config.* present",
    '"astro" in package.json',
    "src/content/ + src/pages/ exist",
  ]
---

# Astro

## Project context

Read `docs/EXTRA.md` first. It declares the Astro version (v4 / v5
have different routing + content-collection APIs), the integrations
in use (Tailwind, MDX, sitemap, image), the deploy target (Cloudflare
Pages, Netlify, Vercel, static export), the i18n strategy if any,
and any content-collection schemas. Anything declared there
overrides the defaults below.

## Conventions

### Pages and routing

- File-based routing under `src/pages/`. `src/pages/about.astro` →
  `/about`. Dynamic routes use brackets: `src/pages/posts/[slug].astro`.
- Endpoints (JSON / API responses) under `src/pages/api/` returning
  `Response` objects.
- `getStaticPaths` for SSG dynamic routes — return all the
  parameter combinations to pre-render.
- `output: "static"` (default) for sites that don't need a server.
  Switch to `"hybrid"` only if specific pages need SSR; switch to
  `"server"` only if most do.

### Content collections

- Define schemas in `src/content.config.ts` (v5) or
  `src/content/config.ts` (v4). Use Zod for types.
- One collection per content type (`blog`, `docs`, `case-studies`).
- Query with `getCollection('blog', filterFn)` —
  `getCollection` returns parsed + typed entries.
- Frontmatter in `.md` / `.mdx` matches the Zod schema. Schema
  mismatch is a build error — good.
- Use `render()` to render an entry's body; pull `Content` from
  the returned object.

### Components

- `.astro` for static / build-time components. They have no runtime
  on the client.
- Frameworks (React, Vue, Svelte, Solid) only when you need
  interactivity. Each costs runtime bytes.
- Hydration directives on framework components:
  - `client:load` — hydrate immediately (use sparingly).
  - `client:idle` — hydrate when the browser is idle.
  - `client:visible` — hydrate when scrolled into view (best for
    below-the-fold widgets).
  - `client:media="(...)"` — hydrate when a media query matches.
  - `client:only="<framework>"` — render only client-side
    (escape hatch for SSR-incompatible code).
- Default to no hydration. Static is the win.

### Images

- `<Image src={...} />` from `astro:assets` — auto-optimizes,
  converts to AVIF/WebP, lazy-loads.
- Imported images get hashed filenames + width/height inferred —
  prevents layout shift.
- External images: configure `image.domains` / `image.remotePatterns`
  in `astro.config`.

### Integrations

- Add via `astro add <integration>` — handles config + dependencies.
- Common: `@astrojs/tailwind`, `@astrojs/mdx`, `@astrojs/sitemap`,
  `@astrojs/rss`.
- Adapter for non-static output: `@astrojs/cloudflare`,
  `@astrojs/netlify`, `@astrojs/vercel`, `@astrojs/node`.

### Styling

- Scoped styles in `.astro` components by default (`<style>` is
  component-scoped).
- Global styles in `src/styles/global.css`, imported in a layout.
- Tailwind via `@astrojs/tailwind` integration.

## Anti-patterns

- Don't `client:load` everything. The whole point of Astro is "ship
  no JS unless you must". Audit hydrated components in the build
  output.
- Don't fetch data in components when you could fetch at build time
  via `getStaticPaths` or `Astro.glob` / collection queries — that
  data ends up in the static HTML, no runtime cost.
- Don't put secrets in `import.meta.env.PUBLIC_*` — `PUBLIC_` is
  exposed to the client bundle.
- Don't mix SSR and SSG without considering the deploy target.
  Cloudflare Pages handles hybrid, but some providers don't.
- Don't bundle large client-side libraries (lodash, moment) when
  smaller alternatives or `Astro.glob`-style build-time work would do.

## Commands / verification

- `npm run dev` — local dev server with HMR.
- `npm run build` — production build to `dist/`.
- `npm run preview` — serve `dist/` locally to test the production
  output before deploy.
- After build: inspect `dist/_astro/` for JS bundles. Each
  hydrated island shows here; surprises mean unintended hydration.
- `astro check` — TypeScript + Astro diagnostics across the project.
- Lighthouse / WebPageTest against the preview. Astro defaults
  to good scores; regressions usually mean a heavy hydrated
  component or a large image without `<Image>`.
- For content collections: `astro sync` after schema changes to
  regenerate types — IDE autocomplete will lie otherwise.
