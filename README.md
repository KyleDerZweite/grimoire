# Grimoire

Grimoire is the central content hub and knowledge base for the kylehub.dev ecosystem.

It is a centralized, self-hosted Headless CMS powered by [PayloadCMS 3.0](https://payloadcms.com/) that serves as the single source of truth for configuration, user data, and content.

## Architecture

Grimoire runs as a standalone service node. It does not share a Docker network with the core infrastructure and connects to authentication and clients exclusively via public HTTPS APIs.

```mermaid
graph TD
    subgraph "Core HA Cluster"
        Pangolin[Pangolin - Ingress]
        Zitadel[Zitadel - auth.kylehub.dev]
    end

    subgraph "Standalone Node - Grimoire Stack"
        CMS[PayloadCMS Container]
        DB[(Local PostgreSQL)]
    end

    subgraph "Frontend Clients"
        PageBuilder[Page Builder App]
    end

    CMS -->|Internal Docker Net| DB
    CMS -->|OIDC / HTTPS| Zitadel
    
    PageBuilder -->|REST API / HTTPS| Pangolin --> CMS
```

## Tech Stack

| Component       | Technology                                      |
|-----------------|-------------------------------------------------|
| Core            | [PayloadCMS 3.0](https://payloadcms.com) (Node.js / Next.js) |
| Database        | PostgreSQL 16 (bundled in this stack)           |
| Authentication  | OIDC via Zitadel (external)                     |
| Storage         | Local disk or S3 (MinIO)                        |
| Ingress         | Traefik (via external Pangolin)                 |

## External Requirements

Grimoire relies on external core infrastructure, which must be reachable via the public internet or internal DNS.

### Zitadel

- Endpoint: `auth.kylehub.dev`
- Purpose: Admin login via SSO
- Grimoire must be able to reach `https://auth.kylehub.dev`

### Pangolin

- Endpoint: `pangolin.kylehub.dev`
- Purpose: Reverse proxy that routes traffic to this node
- Ensure DNS points `pcms.kylehub.dev` to this node's IP

## Deployment

Since Grimoire runs on a separate node, this stack includes its own PostgreSQL database and acts as a self-contained unit.

### Configuration

Create a `.env` file in the project root:

```bash
# Application Settings
PAYLOAD_SECRET=generate-a-very-long-random-string
PORT=3000
SERVER_URL=https://pcms.kylehub.dev

# Database (internal to this stack)
POSTGRES_USER=grimoire
POSTGRES_PASSWORD=secure_db_password
POSTGRES_DB=grimoire
DATABASE_URI=postgres://grimoire:secure_db_password@postgres:5432/grimoire

# Authentication (external HA cluster)
ZITADEL_ISSUER=https://auth.kylehub.dev
ZITADEL_CLIENT_ID=your-generated-client-id
ZITADEL_CLIENT_SECRET=your-generated-client-secret

# Object Storage (optional)
# S3_ENDPOINT=https://s3.kylehub.dev
```

Note: `DATABASE_URI` uses the internal hostname `postgres` because the database runs inside this stack.

### Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  grimoire:
    image: kylehub/grimoire:latest
    container_name: grimoire_cms
    restart: unless-stopped
    env_file: .env
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grimoire.rule=Host(`pcms.kylehub.dev`)"
      - "traefik.http.routers.grimoire.tls=true"

  postgres:
    image: postgres:16-alpine
    container_name: grimoire_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./grimoire_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

If Pangolin runs on a different server, configure it manually to point to this node's IP on port 3000. If using Cloudflare Tunnel, the Traefik labels can be omitted.

## Project Structure

```
src/
├── collections/
│   ├── Users.ts              # User accounts (synced with Zitadel)
│   ├── Media.ts              # Asset repository
│   ├── Pages.ts              # User pages (linktree, portfolio, custom)
│   ├── Templates.ts          # Page templates
│   └── LayoutTemplates.ts    # Reusable layout patterns
├── blocks/
│   ├── Hero.ts               # Hero section with image/video
│   ├── LinkList.ts           # Simple link list (linktree-style)
│   ├── ProfileCard.ts        # Avatar, name, bio
│   ├── ProjectGrid.ts        # Portfolio project showcase
│   ├── TextContent.ts        # Rich text / markdown
│   ├── ContactForm.ts        # Contact form block
│   ├── Gallery.ts            # Image gallery
│   ├── Embed.ts              # External embed (YouTube, etc.)
│   └── Spacer.ts             # Layout spacing
└── globals/
    ├── SiteSettings.ts       # Default themes, fonts, colors
    └── SocialProviders.ts    # Available social link types
```

## Page Builder Concept

Grimoire supports two page creation modes:

### Simple Mode (Linktree-style)

A streamlined interface for creating link-in-bio pages:

- Profile section (avatar, display name, bio)
- Ordered list of links with optional icons
- Social media quick-links
- Theme selection from presets

### Advanced Mode (Custom Pages)

A block-based page builder for complex layouts:

- Drag-and-drop block arrangement
- Nested layout containers (columns, grids)
- Per-block styling overrides
- Custom CSS injection (optional)

## Collections

### Pages

The central collection storing all user-created pages.

| Field         | Type        | Description                                      |
|---------------|-------------|--------------------------------------------------|
| title         | text        | Page title                                       |
| slug          | text        | URL-friendly identifier                          |
| owner         | relation    | Reference to Users collection                    |
| pageType      | select      | `linktree`, `portfolio`, `custom`                |
| template      | relation    | Optional starting template                       |
| layout        | relation    | Optional layout template                         |
| blocks        | blocks      | Array of content blocks                          |
| theme         | group       | Colors, fonts, background                        |
| seo           | group       | Meta title, description, og:image                |
| published     | checkbox    | Visibility toggle                                |

### Templates

Pre-built page configurations users can start from.

| Field         | Type        | Description                                      |
|---------------|-------------|--------------------------------------------------|
| name          | text        | Template display name                            |
| description   | textarea    | What this template is for                        |
| category      | select      | `linktree`, `portfolio`, `landing`, `blog`       |
| thumbnail     | upload      | Preview image                                    |
| defaultBlocks | blocks      | Pre-configured block arrangement                 |
| defaultTheme  | group       | Suggested theme settings                         |

### Layout Templates

Reusable structural patterns applied across pages.

| Field         | Type        | Description                                      |
|---------------|-------------|--------------------------------------------------|
| name          | text        | Layout name                                      |
| structure     | select      | `single-column`, `sidebar-left`, `sidebar-right`, `split` |
| header        | blocks      | Optional fixed header blocks                     |
| footer        | blocks      | Optional fixed footer blocks                     |
| contentAreas  | array       | Named regions where page blocks render           |

## Customization Scope

The following elements are customizable per page:

| Element           | Customizable | Constraints                              |
|-------------------|--------------|------------------------------------------|
| Colors            | Yes          | Primary, secondary, background, text     |
| Fonts             | Yes          | From approved Google Fonts list          |
| Background        | Yes          | Solid, gradient, or image                |
| Block order       | Yes          | Drag-and-drop reordering                 |
| Block visibility  | Yes          | Show/hide individual blocks              |
| Block styling     | Partial      | Padding, margin, border-radius           |
| Custom CSS        | Optional     | Enabled per-user or per-plan             |
| Custom domains    | Future       | CNAME mapping to user pages              |

## Authentication Strategy

1. **Login**: Admin users are redirected to `https://auth.kylehub.dev`
2. **Token Validation**: Grimoire validates the OIDC token signature against Zitadel's public keys (fetched over HTTPS)
3. **User Sync**: On first login, Grimoire creates a local user record referencing the Zitadel ID

## License

This project is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).

Copyright 2026 [KyleDerZweite](https://github.com/KyleDerZweite)
