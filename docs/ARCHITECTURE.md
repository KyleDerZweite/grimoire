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

## Proposed Tech Stack

> **Note**: Final stack pending research.

| Layer | Candidates | Decision Pending |
|-------|------------|------------------|
| Dashboard/Editor | Astro + React, Next.js, SvelteKit | Yes |
| Backend API | Hono, FastAPI, Astro API routes | Yes |
| Database | PostgreSQL (existing) | Decided |
| Auth | OIDC Provider | Decided |
| Preview | Client-side mock, SSR, or real dev server | Yes |
| Output | Astro static sites + React islands | Decided |
| Storage | Local disk or S3-compatible | TBD |

## Data Model (Draft)

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
  config: SiteConfig;      // Template-specific config
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
    platform: 'twitter' | 'instagram' | 'github' | 'discord' | 'spotify' | ...;
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

## Template System

Templates are complete Astro projects that get populated with user config at build time.

```
templates/
├── linktree/
│   ├── astro.config.mjs
│   ├── package.json
│   ├── src/
│   │   ├── pages/
│   │   │   └── index.astro    # Uses config from props/data
│   │   ├── components/
│   │   │   ├── ProfileCard.astro
│   │   │   ├── LinkButton.astro
│   │   │   ├── SocialIcons.astro
│   │   │   └── SpotifyEmbed.tsx  # React island
│   │   └── styles/
│   │       └── global.css
│   └── public/
│
└── portfolio/              # Future
    └── ...
```

**Build Process**:
1. Copy template to temp directory
2. Inject user's `SiteConfig` as JSON
3. Run `npm install && npm run build`
4. Output is static `dist/` folder
5. ZIP and return, or push to Git for deployment

## API Endpoints (Draft)

```
GET    /api/sites              # List user's sites
POST   /api/sites              # Create new site
GET    /api/sites/:id          # Get site config
PUT    /api/sites/:id          # Update site config
DELETE /api/sites/:id          # Delete site

POST   /api/sites/:id/build    # Trigger build
GET    /api/sites/:id/download # Download ZIP

GET    /api/templates          # List available templates
GET    /api/templates/:id      # Get template info
```

## Preview Strategy Options

| Approach | Pros | Cons |
|----------|------|------|
| Client-side mock | Instant, lightweight | May not match build 100% |
| Server-rendered | Accurate | Slower feedback |
| Real Astro dev server | True preview | Resource heavy |
| Build-on-change | Accurate | Slow (seconds per change) |

**Recommendation**: Start with client-side mock for v1. Components render in the editor using the same React components that will be used in the build, ensuring visual accuracy.

## Deployment Flow (v1)

```
User saves site
      │
      ▼
Dashboard calls POST /api/sites/:id/build
      │
      ▼
Backend copies template + injects config
      │
      ▼
Backend runs `npm run build`
      │
      ▼
Backend zips `dist/` folder
      │
      ▼
User downloads ZIP
      │
      ▼
Kyle manually deploys via reverse proxy
```

## Future: Automated Deployment (v2)

```
User clicks "Publish"
      │
      ▼
Backend pushes site to Git (user's repo)
      │
      ▼
Git webhook triggers CI/CD
      │
      ▼
CI/CD builds and deploys to tunnel endpoint
      │
      ▼
Reverse proxy routes yuna.grimoire.kylehub.dev → tunnel
      │
      ▼
Site is live!
```
