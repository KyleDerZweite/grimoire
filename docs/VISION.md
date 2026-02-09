# Grimoire — Project Vision

## Overview

Grimoire is a **Static Site Factory** — a streamlined workflow for generating bespoke static websites for friends and personal use. Using AI-assisted coding, each site is built as a unique Astro project with zero ongoing maintenance overhead.

## Why This Works

1. **AI Synergy**: AI coding assistants excel at writing Astro/Tailwind code
2. **Lightweight**: NGINX Alpine serves static files with minimal resources
3. **Security**: No database, no admin panel — minimal attack surface
4. **True Customization**: Every site is a blank canvas

## Target Users

| User Type | Needs | Example |
|-----------|-------|---------|
| Friends | Free Carrd/Beacons replacement | Links, profile pic, Spotify embed |
| Kyle | Portfolio with depth | Projects, resume, embeds |
| Future friends | Unique business sites | Whatever they want |

## Core Value Proposition

> A monorepo workflow where you use AI to rapidly create beautiful, performant static sites for friends — deployed via NGINX and managed as code.

## What Grimoire Is

- A **monorepo** containing all friend sites
- A **template system** for rapidly spinning up new Astro projects
- A **shared component library** for consistent styling
- A **deployment workflow** via NGINX + Pangolin

## What Grimoire Is NOT

- A CMS or database-backed platform
- A self-service platform where friends edit their own content
- Enterprise software
- A Wix/Squarespace/Carrd clone

## Content Updates: The Webmaster Model

Since there's no CMS, you are the webmaster:

1. Friend texts you: "Can you change my bio?"
2. You use AI to update the code
3. You push to Git and rebuild
4. Site is updated

If this becomes a bottleneck, integrate a Git-based CMS like **Keystatic** or **Decap CMS** — zero database, zero backend.

## Design Principles

1. **Code over Configuration** — Write actual code, not CMS configs
2. **AI-Assisted Development** — Leverage coding assistants for rapid iteration
3. **Static over Dynamic** — Output is HTML/CSS/JS, fast and cheap to host
4. **Monorepo for Consistency** — Shared components, consistent tooling
5. **Fun and Learning** — This is a creative outlet, not enterprise software

## Scope

### Now: Foundation

- Monorepo structure with PNPM workspaces
- Base Astro template
- Shared UI components (Tailwind-based)
- NGINX + Docker deployment
- Documentation

### Soon: First Sites

- Kyle's portfolio site
- First friend sites (linktree-style)
- Refined template and components

### Later: Enhancements

- Automated builds (CI/CD)
- Preview deployments
- Git-based CMS integration (if needed)
- Additional templates
