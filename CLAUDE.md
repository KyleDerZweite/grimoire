# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Grimoire is a **Static Site Factory** — a monorepo for creating bespoke static websites for friends using Astro + Tailwind CSS. Each site under `sites/` is a unique Astro project (blank canvas), not a CMS-driven page. Sites are served via NGINX and tunneled through Pangolin/Newt.

## Commands

```bash
# Install dependencies
pnpm install

# Build all sites
pnpm run build

# Dev server for a specific site
pnpm --filter sites/<name> dev

# Build a specific site
pnpm --filter sites/<name> run build

# Create a new site from template
pnpm run new-site <name>

# Clean build artifacts
pnpm run clean

# Container deployment
podman-compose up -d
podman-compose restart builder    # Force immediate rebuild
```

## Architecture

**Deployment flow**: Pangolin (reverse proxy) → Newt (tunnel) → NGINX (static files)

**Three container services** (docker-compose.yml):
- **builder**: Node 20 Alpine container that polls git and runs `pnpm install && pnpm build` on changes (interval controlled by `BUILD_INTERVAL` env var, default 2 hours)
- **router**: NGINX Alpine serving static files from each site's `dist/` directory
- **newt**: Network tunnel connecting NGINX to Pangolin gateway

**NGINX routing**: Subdomain `<name>.kylehub.dev` maps to `/usr/share/nginx/html/<name>` via `map $host` directive in nginx.conf.

## Monorepo Structure

- `templates/base-astro/` — Blueprint for new sites. `new-site.sh` copies this to `sites/`.
- `sites/<name>/` — Each site is an independent Astro project with its own `package.json`, `astro.config.mjs`, `src/`, and `dist/`.
- `scripts/build-loop.sh` — Builder container entrypoint: initial build on start, then git-poll loop.
- `scripts/new-site.sh` — Copies template, updates package name, prints deployment instructions.

PNPM workspaces defined in `pnpm-workspace.yaml` cover `templates/*` and `sites/*`.

## Adding a New Site

1. `pnpm run new-site <name>`
2. Customize `sites/<name>/src/`
3. Add volume mount to docker-compose.yml: `./sites/<name>/dist:/usr/share/nginx/html/<name>:ro`
4. Push to git (builder auto-deploys) or `podman-compose restart builder`

## Stack Details

- **Astro 5** with `output: 'static'` — zero JavaScript by default
- **Tailwind CSS 4** via `@tailwindcss/vite` plugin (imported as `@import "tailwindcss"` in CSS)
- **Node >=20, PNPM >=9**
- **Podman** (not Docker) with podman-compose

## Per-Site Conventions

Each site defines its own theme via CSS custom properties (e.g., `--color-bg`, `--color-accent`). Sites use staggered CSS entrance animations (`fadeUp`, `scaleIn`) with delay utility classes (`.delay-1` through `.delay-12`). Some sites use `base: ''` and `build: { assetsPrefix: '.' }` in astro.config.mjs for relative asset paths.

## Design Philosophy

Sites should have bold, intentional aesthetics — not generic "AI slop." Prioritize strong typography, purposeful color palettes, considered motion/animation, and thoughtful spatial composition. Each site is a creative project, not a template fill-in.
