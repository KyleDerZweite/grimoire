# Grimoire

A **Static Site Factory** for creating beautiful, bespoke websites for friends and personal use. Built with Astro, Tailwind, and AI-assisted development.

## What is Grimoire?

Grimoire is a monorepo workflow for rapidly creating and deploying static websites. Using AI coding assistants, each site is a unique Astro project — a blank canvas with unlimited creative freedom.

**Output**: Static Astro sites served via NGINX.

## Status

**In Development** — Architecture finalized, ready for implementation.

## Documentation

| Document | Description |
|----------|-------------|
| [Vision](docs/VISION.md) | Project philosophy and scope |
| [Architecture](docs/ARCHITECTURE.md) | Technical design and deployment |

## Project Structure

```
grimoire/
├── packages/
│   └── ui/              # Shared Tailwind components
├── templates/
│   └── base-astro/      # Blueprint for new sites
├── sites/
│   ├── kyle/            # Kyle's portfolio
│   ├── sarah/           # Friend A's linktree
│   └── tom/             # Friend B's business site
├── docker-compose.yml   # NGINX deployment
├── nginx.conf           # Subdomain routing
└── docs/                # Documentation
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Site Generator | Astro |
| Styling | Tailwind CSS |
| Web Server | NGINX Alpine |
| Tunnel | Newt → Pangolin |
| Development | AI-assisted (Cursor, Copilot, etc.) |

## Workflow

1. **Copy template**: `cp -r templates/base-astro sites/newsite`
2. **Customize with AI**: Generate unique layouts and components
3. **Build**: `pnpm run build`
4. **Deploy**: Add volume to Docker, restart NGINX

## Advantages

- **AI Synergy**: AI excels at writing code, not configuring CMS schemas
- **Lightweight**: NGINX uses minimal RAM; no runtime dependencies
- **Secure**: No database to hack, no admin panel to brute-force
- **Unlimited Customization**: Each site is a blank canvas
- **Near-Zero Cost**: Static files are cheap to host

## License

This project is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).

Copyright 2026 [KyleDerZweite](https://github.com/KyleDerZweite)
