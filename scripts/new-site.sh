#!/usr/bin/env bash
set -euo pipefail

# new-site.sh - Create a new Grimoire site from the base template
#
# Usage: pnpm run new-site <site-name>
#   or:  bash scripts/new-site.sh <site-name>

SITE_NAME="${1:-}"

if [ -z "$SITE_NAME" ]; then
  echo "Usage: pnpm run new-site <site-name>"
  echo "Example: pnpm run new-site sarah"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$ROOT_DIR/templates/base-astro"
SITE_DIR="$ROOT_DIR/sites/$SITE_NAME"

if [ -d "$SITE_DIR" ]; then
  echo "Error: Site '$SITE_NAME' already exists at $SITE_DIR"
  exit 1
fi

echo "Creating new site: $SITE_NAME"

# Copy template
cp -r "$TEMPLATE_DIR" "$SITE_DIR"

# Update package name in the new site's package.json
sed -i "s|@grimoire/base-astro|@grimoire/site-${SITE_NAME}|g" "$SITE_DIR/package.json"
sed -i "s|Base Astro template - copy this to sites/ to create a new site|${SITE_NAME}'s site|g" "$SITE_DIR/package.json"

echo ""
echo "Site created at: sites/$SITE_NAME"
echo ""
echo "Next steps:"
echo "  cd sites/$SITE_NAME"
echo "  pnpm install"
echo "  pnpm dev"
echo ""
echo "When ready to deploy, add this volume to docker-compose.yml:"
echo "  - ./sites/${SITE_NAME}/dist:/usr/share/nginx/html/${SITE_NAME}"
