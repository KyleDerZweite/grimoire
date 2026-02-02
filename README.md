# Grimoire

A self-hosted website builder for creating linktree-style and portfolio pages. Built as part of the KyleHub ecosystem.

## What is Grimoire?

Grimoire is a free, self-hosted alternative to Carrd, Beacons, and Linktree. Users authenticate, customize their site through a form-based editor with live preview, and publish to their own subdomain.

**Target output**: Static Astro sites with React islands for interactive elements.

## Status

**In Planning** — Architecture finalized, ready for implementation.

## Documentation

| Document | Description |
|----------|-------------|
| [Vision](docs/VISION.md) | Project goals, scope, and phasing |
| [Architecture](docs/ARCHITECTURE.md) | Technical design and data models |

## Features (Planned)

### Phase 1: MVP
- User authentication (OIDC)
- Form-based site editor with Puck
- Live SSR preview
- Linktree-style template
- Export as downloadable ZIP

### Phase 2: Auto-Deploy
- Push-button publishing
- Git integration (Forgejo) for versioning
- CI/CD pipeline with act_runner
- Subdomain routing

### Phase 3: Advanced
- Portfolio template
- Spotify/YouTube embeds
- Resume download
- Custom domain support

## Tech Stack

| Component | Technology |
|-----------|------------|
| Dashboard | Astro + React (SSR) |
| Visual Editor | Puck |
| Build Engine | Astro (Static) |
| Database | PostgreSQL + Drizzle |
| Auth | OIDC Provider (PKCE) |
| Git Server | Forgejo |
| CI/CD | act_runner |
| Output | Static Astro sites |

## Project Structure

```
grimoire/
├── apps/
│   ├── dashboard/     # Admin + Visual Editor
│   └── renderer/      # Static site generator
├── packages/
│   ├── ui/            # Design system
│   ├── blocks/        # Site components
│   ├── database/      # Drizzle schema
│   └── auth/          # OIDC utilities
├── docs/              # Documentation
└── research/          # Research documents
```

## KyleHub Infrastructure

Grimoire is a KyleHub-native application, leveraging:

- **OIDC Provider** for authentication
- **PostgreSQL** for data storage
- **Reverse Proxy + Tunnels** for deployment and routing
- **Forgejo** for version control

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).

If you modify and deploy this software, you must make your source code available to users.

Copyright 2026 [KyleDerZweite](https://github.com/KyleDerZweite)
