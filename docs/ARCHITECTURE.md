# Grimoire - Architecture

## Overview

Grimoire is a **Static Site Factory** - a streamlined workflow for generating bespoke static sites for friends and personal use. Using AI-assisted coding, each site is built as a unique Astro project and deployed via NGINX.

## System Context

```
┌─────────────────────────────────────────────────────┐
│                   Pangolin Gateway                   │
│              (Reverse Proxy + Routing)               │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                   Newt (Network Bridge)              │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    NGINX Router                      │
│              (Serves Static Files)                   │
└─────────────────────────┬───────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌──────────┐
    │ sircookie/ │  │ yunasoul/  │  │  etc./   │
    │   dist/    │  │   dist/    │  │  dist/   │
    └────────────┘  └────────────┘  └──────────┘
```

## URL & Domain Structure

| URL | Purpose |
|-----|---------|
| `sircookie.kylehub.dev` | Sir.Cookie's link page |
| `yunasoul.kylehub.dev` | YunaSoul's link page |
| `kylesoul.de` | Custom domain example |

### Routing Logic

1. **Wildcard DNS**: `*.kylehub.dev` → Pangolin → Newt → NGINX
2. **NGINX map**: Subdomain → corresponding `/usr/share/nginx/html/{subdomain}` folder
3. **Custom domains**: DNS A/CNAME record → Pangolin handles SSL

### SSL Strategy

- **Wildcard cert** for `*.kylehub.dev` via Pangolin
- **Custom domains** auto-provisioned via Pangolin's Let's Encrypt integration

## Tech Stack

### Infrastructure

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Containers | Podman + podman-compose | Daemonless, rootless container runtime |
| Reverse Proxy | Pangolin | Existing KyleHub infrastructure |
| Network Bridge | Newt | Secure tunnel from Pangolin to local NGINX |
| Web Server | NGINX Alpine | Minimal RAM, serves static files |
| Build Tool | Astro | Zero-JS output, perfect for static sites |

### Development Workflow

| Tool | Purpose |
|------|---------|
| AI Coding Assistant | Generate Astro components, Tailwind styles |
| PNPM Workspaces | Monorepo management |
| Git | Version control |

## Monorepo Structure

```
grimoire/
├── package.json                 # PNPM workspace config
├── pnpm-workspace.yaml
├── docker-compose.yml           # Podman compose stack
├── nginx.conf                   # Subdomain routing config
│
├── templates/
│   └── base-astro/              # Blueprint for new projects
│       ├── src/
│       │   ├── layouts/
│       │   ├── pages/
│       │   └── components/
│       ├── astro.config.mjs
│       └── package.json
│
├── sites/
│   ├── sircookie/               # Sir.Cookie's link page
│   │   ├── src/
│   │   ├── dist/                # Built output
│   │   └── package.json
│   │
│   └── yunasoul/                # YunaSoul's link page
│       ├── src/
│       ├── dist/
│       └── package.json
│
└── docs/                        # Documentation
```

## Podman Deployment

```yaml
services:
  # The Build Engine - pulls & rebuilds on a schedule
  builder:
    build:
      context: .
      dockerfile: Containerfile.builder
    container_name: grimoire_builder
    restart: unless-stopped
    volumes:
      - .:/app:z
    environment:
      - BUILD_INTERVAL=${BUILD_INTERVAL:-300}
      - GIT_BRANCH=${GIT_BRANCH:-main}
      - BUILD_ON_START=${BUILD_ON_START:-true}

  # The Traffic Director
  router:
    image: nginx:alpine
    container_name: grimoire_router
    restart: unless-stopped
    volumes:
      - ./sites/sircookie/dist:/usr/share/nginx/html/sircookie
      - ./sites/yunasoul/dist:/usr/share/nginx/html/yunasoul
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    networks:
      - pangolin_net
    depends_on:
      builder:
        condition: service_started

  # The Network Connector (Newt)
  newt:
    image: fosrl/newt:latest
    container_name: grimoire_newt
    restart: unless-stopped
    environment:
      - PANGOLIN_ENDPOINT=https://pangolin.kylehub.dev
      - NEWT_ID=${NEWT_ID}
      - NEWT_SECRET=${NEWT_SECRET}
    networks:
      - pangolin_net
    depends_on:
      - router

networks:
  pangolin_net:
    external: true
```

### Builder Service

The `builder` container handles continuous deployment:

1. On startup: runs `pnpm install && pnpm build` to ensure `dist/` folders exist
2. Every `BUILD_INTERVAL` seconds (default 300 = 5 min): fetches from git
3. If new commits detected: pulls changes and rebuilds all sites
4. NGINX serves updated files immediately (no restart needed)

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `BUILD_INTERVAL` | `7200` | Seconds between git fetch checks (2 hours) |
| `GIT_BRANCH` | `main` | Branch to track |
| `BUILD_ON_START` | `true` | Build immediately on container start |

## NGINX Configuration

```nginx
# Subdomain routing
map $host $site_folder {
    ~^(?<subdomain>.+)\.kylehub\.dev$ $subdomain;
    default "kyle";
}

server {
    listen 80;
    server_name *.kylehub.dev;

    root /usr/share/nginx/html/$site_folder;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Workflow: Creating a New Site

### 1. Copy Template

```bash
cp -r templates/base-astro sites/newsite
cd sites/newsite
pnpm install
```

### 2. Customize with AI

Use AI coding assistant to:
- Generate unique layouts and components
- Apply custom Tailwind styling
- Add React/Svelte islands if needed

### 3. Build

```bash
pnpm run build
# Output: sites/newsite/dist/
```

### 4. Deploy

```bash
# 1. Add volume to docker-compose.yml for the new site
# 2. Push to git - the builder will auto-pull and rebuild
git add . && git commit -m "Add newsite" && git push
# Or force a manual rebuild:
podman-compose restart builder
```

## Content Management (The Trade-off)

Dropping a full CMS means friends can't self-edit content. Solutions:

### Option 1: Webmaster Model

You are the webmaster. Friends text you changes, you use AI to apply the diff, you push.

### Option 2: Git-based CMS (Future)

If self-service editing becomes necessary, integrate a Git-based CMS:

| Option | Description |
|--------|-------------|
| [Keystatic](https://keystatic.com) | Local/cloud editor, saves to JSON/Markdown |
| [Decap CMS](https://decapcms.org) | Browser-based, saves to Git |

These require **zero database** and **zero backend hosting** - they fit perfectly into the static workflow.

## Security Considerations

| Risk | Mitigation |
|------|------------|
| No database to hack | ✅ Static files only |
| No admin panel | ✅ No brute-force target |
| XSS in content | DOMPurify at build time (if accepting user input) |
| DDOS | Pangolin rate limiting, NGINX cache headers |

## Advantages of This Architecture

1. **AI Synergy**: AI assistants excel at writing code (Astro, Tailwind), not configuring CMS schemas
2. **Performance**: NGINX uses minimal RAM; no Node.js runtime
3. **True Customization**: Each site is a blank canvas - use React, Svelte, or plain HTML
4. **Security**: No database, no admin panel, minimal attack surface
5. **Cost**: Near-zero hosting costs for static files
6. **Simplicity**: From "Platform Maintainer" to "Creative Director"

## Server Deployment

### Initial Setup (one-time)

```bash
# 1. Clone the repo on your server
git clone https://github.com/your-user/grimoire.git
cd grimoire

# 2. Create your .env file
cp .env.example .env
# Edit .env with your Pangolin credentials

# 3. Start everything
podman-compose up -d
```

That's it. The builder container handles everything from here:
- Builds all sites on first start
- Checks for git updates every 2 hours
- Rebuilds automatically when changes are detected

### Updating

Just push to the tracked branch. The builder picks up changes automatically.
To force an immediate rebuild: `podman-compose restart builder`

## Future Considerations

- **GitHub webhook trigger**: Replace polling with instant webhook-triggered builds
- **Preview deployments**: Feature branches → preview URLs
- **Shared component library**: Publish `packages/ui` to private npm registry
