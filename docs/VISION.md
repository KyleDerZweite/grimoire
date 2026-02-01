# Grimoire — Project Vision

## Overview

Grimoire is a self-hosted website builder that allows users to create beautiful linktree-style and portfolio pages through a form-based editor with real-time preview. It serves as a free, self-hosted alternative to services like Carrd and Beacons.

## Target Users

| User Type | Needs | Example |
|-----------|-------|---------|
| Friends (Primary) | Free Carrd/Beacons replacement with simple linktree pages | Links, profile pic, Spotify embed |
| Developer (Kyle) | Portfolio with more depth — projects, resume, embeds | Future scope, architecture should support it |

## Core Value Proposition

> A self-hosted platform where users authenticate, customize their site via forms, preview in real-time, and publish to their own subdomain — without paying for Carrd Pro or similar services.

## Scope per Phase

### Phase 1: MVP — "Better Free Carrd"

**Goal**: Friends can create a linktree-style page and download it as a deployable ZIP.

| Component | Description |
|-----------|-------------|
| Landing Page | Simple "What is Grimoire?" at `grimoire.kylehub.dev` |
| Auth | Zitadel login (OIDC/PKCE) |
| Dashboard | User sees their site(s), can create/edit |
| Editor | Form-based: name, bio, avatar, list of links, theme |
| Preview | Live preview showing their page as they edit |
| Export | Download button → ZIP with complete Astro project |

**Deployment (v1)**: Manual — take ZIP, deploy via Pangolin/Newt tunnel.

### Phase 2: Auto-Deploy Pipeline

**Goal**: Push-button deployment to subdomains.

| Component | Description |
|-----------|-------------|
| Internal Git | Gitea instance, each user gets a repo |
| CI/CD | On save/publish → build Astro → deploy |
| Pangolin Integration | Auto-create resource, configure Newt tunnel |
| Subdomain Routing | `yuna.grimoire.kylehub.dev` works automatically |

### Phase 3: Advanced Features

**Goal**: Portfolio pages, custom domains.

| Feature | Description |
|---------|-------------|
| Portfolio Template | Multi-section: about, projects, resume, contact |
| Resume Download | PDF upload + styled download button |
| Embeds | Spotify, YouTube, GitHub stats, etc. |
| Custom Domains | User brings domain, shown DNS instructions |
| Theme Customization | Color schemes, fonts, layouts |

## What Grimoire Will Never Be

- A full CMS or blog platform
- A drag-and-drop page builder (too complex)
- A generic website hosting service
- Enterprise software

## Design Principles

1. **Simple over Complex** — Form-based editing, not visual drag-and-drop
2. **Static over Dynamic** — Output is Astro static sites, fast and cheap to host
3. **Modular from Day 1** — Architecture supports adding features without rewrites
4. **KyleHub-Native First** — Leverage existing infrastructure, portability is a future concern
5. **Fun and Learning** — This is a passion project, not production enterprise software
