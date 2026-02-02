# Grimoire — Architecture

## Overview

Grimoire is a KyleHub-native application, meaning it leverages existing KyleHub infrastructure rather than bundling its own auth, database, and deployment systems.

## System Context

```
┌─────────────────────────────────────────────────────┐
│                   KyleHub Gateway                    │
│           (Reverse Proxy + Auth + Routing)          │
└─────────────────────────┬───────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│   Grimoire    │ │  Git Server   │ │  Postgres +   │
│   Dashboard   │ │  (per-user    │ │    Redis      │
│   + Editor    │ │    repos)     │ │  (centralized)│
└───────┬───────┘ └───────────────┘ └───────────────┘
        │
        ▼ (on publish)
┌───────────────┐
│  Build + Push │
│   to Git      │
└───────┬───────┘
        │
        ▼ (CI/CD)
┌───────────────┐
│ Deploy static │
│  site via     │
│    tunnel     │
└───────────────┘
        │
        ▼
┌───────────────┐
│ yuna.grimoire │
│ .kylehub.dev  │
└───────────────┘
```

## External Dependencies (KyleHub Infrastructure)

| Service | Purpose | Endpoint |
|---------|---------|----------|
| OIDC Provider | Authentication (OIDC/PKCE) | `auth.kylehub.dev` |
| PostgreSQL | User data, site configs | Centralized DB |
| Git Server | Version control, per-user repos | TBD |
| Reverse Proxy | Ingress, tunnel management | `*.kylehub.dev` |
| Tunnel Agent | Secure tunnels for site hosting | Via reverse proxy |

## Finalized Tech Stack

Based on research, the following stack has been selected:

### Infrastructure

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Identity | OIDC Provider | Existing KyleHub auth |
| Git Server | Forgejo | Lightweight (~150MB RAM), GitHub Actions compatible, non-profit governance |
| CI/CD Runner | act_runner | GitHub Actions workflows, minimal resources |
| Database | PostgreSQL | Existing infrastructure |
| Reverse Proxy | Traefik | Dynamic subdomain routing, auto-SSL |

### Application

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Dashboard | Astro + React (SSR) | Islands architecture, rich interactivity where needed |
| Visual Editor | Puck | Open-source, JSON-first, data-centric |
| Build Engine | Astro (Static) | Zero-JS output, perfect for user sites |
| ORM | Drizzle | Type-safe, works with PostgreSQL |
| State | Zustand + React Query | Simple, performant |
| Styling | Tailwind CSS | Utility-first, consistent |

### Output

| Output | Format |
|--------|--------|
| User Sites | Static Astro (HTML/CSS, minimal JS) |
| Interactive Elements | React Islands (Spotify embeds, etc.) |

## Monorepo Structure

```
grimoire/
├── apps/
│   ├── dashboard/          # Astro + React (SSR) — Admin + Editor
│   │   ├── src/
│   │   │   ├── pages/      # Landing, login, dashboard, editor
│   │   │   ├── components/ # React components for editor
│   │   │   └── lib/        # API client, auth helpers
│   │   └── astro.config.mjs
│   │
│   └── renderer/           # Astro (Static) — Build engine
│       └── src/
│           └── pages/
│               └── [...slug].astro  # Catch-all dynamic route
│
├── packages/
│   ├── ui/                 # Design system (buttons, inputs, modals)
│   ├── blocks/             # Site components (Hero, Links, Profile, etc.)
│   ├── database/           # Drizzle schema + client
│   ├── auth/               # OIDC utilities and middleware
│   └── config/             # Shared TypeScript and Tailwind config
│
├── docker/                 # Docker Compose, Nginx/Traefik config
├── docs/                   # Documentation
└── research/               # Research documents
```

## Data Model

### User

```typescript
interface User {
  id: string;              // Internal ID
  externalId: string;      // OIDC provider ID
  email: string;
  displayName: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Site

```typescript
interface Site {
  id: string;
  userId: string;          // Owner
  slug: string;            // URL path (e.g., "yuna")
  template: 'linktree' | 'portfolio';
  config: SiteConfig;      // Template-specific config (JSONB)
  theme: ThemeConfig;
  published: boolean;
  publishedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### SiteConfig (Linktree)

```typescript
interface LinktreeSiteConfig {
  profile: {
    name: string;
    bio: string;
    avatarUrl: string;
  };
  links: Array<{
    id: string;
    label: string;
    url: string;
    icon?: string;
  }>;
  socials: Array<{
    platform: 'twitter' | 'instagram' | 'github' | 'discord' | 'spotify';
    url: string;
  }>;
  embeds?: Array<{
    type: 'spotify' | 'youtube' | 'soundcloud';
    embedId: string;
  }>;
}
```

### ThemeConfig

```typescript
interface ThemeConfig {
  preset?: string;         // e.g., "dark-purple", "light-minimal"
  background: {
    type: 'solid' | 'gradient' | 'image';
    value: string;         // Color, gradient CSS, or image URL
  };
  colors: {
    primary: string;
    secondary: string;
    text: string;
    accent: string;
  };
  font: string;            // Google Font name
  borderRadius: 'none' | 'sm' | 'md' | 'lg' | 'full';
}
```

## Key Architectural Patterns

### Dual-Context Components

Components in `packages/blocks` are used in two contexts:
1. **Editor Context**: Wrapped with drag-and-drop handlers, overlay controls
2. **Renderer Context**: Pure HTML/CSS output, no editor overhead

This is solved by the monorepo — same source code, different build targets.

### Live Preview

Uses **SSR iframe preview** (not client-side mock):
1. User edits in Puck editor
2. Changes debounced and sent to `/api/preview`
3. Astro SSR renders actual HTML
4. Iframe displays the real output

This ensures WYSIWYG accuracy.

### Build Engine

The renderer is invoked programmatically:
1. Dashboard spawns child process
2. `astro build` runs with `SITE_ID` env var
3. Catch-all route fetches config from database
4. Static `dist/` folder is generated
5. ZIP for download or push to Git for deployment

### Dynamic Subdomain Routing

Nginx/Traefik `map` directive handles subdomains without config reloads:
- `alice.grimoire.kylehub.dev` → `/var/www/sites/alice`
- Custom domains via Traefik with auto Let's Encrypt

## API Endpoints

```
GET    /api/sites              # List user's sites
POST   /api/sites              # Create new site
GET    /api/sites/:id          # Get site config
PUT    /api/sites/:id          # Update site config
DELETE /api/sites/:id          # Delete site

POST   /api/sites/:id/build    # Trigger build
GET    /api/sites/:id/download # Download ZIP

POST   /api/preview            # SSR preview endpoint

GET    /api/templates          # List available templates
GET    /api/templates/:id      # Get template info
```

## Security Considerations

| Risk | Mitigation |
|------|------------|
| XSS in user content | DOMPurify sanitization at build time |
| SVG script injection | Strip `<script>` and `on*` attributes |
| Cookie scope | `SameSite=Lax`, don't scope to wildcard |
| IDOR attacks | Middleware validates `org_id` on every request |
| M2M auth | Service Users with JWT Profile |

## Deployment Flow

### v1: Manual ZIP Download

```
User saves site → Build triggered → ZIP generated → User downloads → Manual deploy
```

### v2: Automated Pipeline

```
User clicks "Publish"
      ↓
Backend pushes to Git (user's repo)
      ↓
Git webhook triggers CI/CD
      ↓
CI/CD builds and deploys to tunnel endpoint
      ↓
Reverse proxy routes subdomain → tunnel
      ↓
Site is live!
```
