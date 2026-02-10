# Grimoire

A **Static Site Factory** for creating beautiful, bespoke websites for friends and personal use. Built with Astro, Tailwind, and AI-assisted development.

## What is Grimoire?

Grimoire is a monorepo workflow for rapidly creating and deploying static websites. Using AI coding assistants, each site is a unique Astro project - a blank canvas with unlimited creative freedom.

**Output**: Static Astro sites served via NGINX.

## Status

**In Development** - Architecture finalized, ready for implementation.

## Documentation

| Document | Description |
|----------|-------------|
| [Vision](docs/VISION.md) | Project philosophy and scope |
| [Architecture](docs/ARCHITECTURE.md) | Technical design and deployment |

## Project Structure

```
grimoire/
├── templates/
│   └── base-astro/      # Blueprint for new sites
├── sites/
│   ├── sircookie/       # Sir.Cookie's link page
│   └── yunasoul/        # YunaSoul's link page
├── docker-compose.yml   # Podman compose deployment
├── nginx.conf           # Subdomain routing
└── docs/                # Documentation
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Site Generator | Astro |
| Styling | Tailwind CSS |
| Containers | Podman + podman-compose |
| Web Server | NGINX Alpine |
| Tunnel | Newt → Pangolin |
| Development | AI-assisted (Cursor, Copilot, etc.) |

## Workflow

1. **Copy template**: `cp -r templates/base-astro sites/newsite`
2. **Customize with AI**: Generate unique layouts and components
3. **Build**: `pnpm run build`
4. **Deploy**: Add volume to docker-compose.yml, `podman-compose up -d`

## Advantages

- **AI Synergy**: AI excels at writing code, not configuring CMS schemas
- **Lightweight**: NGINX uses minimal RAM; no runtime dependencies
- **Secure**: No database to hack, no admin panel to brute-force
- **Unlimited Customization**: Each site is a blank canvas
- **Near-Zero Cost**: Static files are cheap to host

## License

Source code is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0). All creative assets (artwork, images, graphics) are **All Rights Reserved** - see [LICENSE](LICENSE) for details.

Copyright 2026 [KyleDerZweite](https://github.com/KyleDerZweite)
