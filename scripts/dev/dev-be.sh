#!/usr/bin/env bash
# =============================================================================
# dev-be.sh — Run CMS Backend (Fastify) with hot-reload (tsx watch)
# Usage: ./scripts/dev-be.sh
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BE_DIR="$ROOT_DIR/packages/cms-backend"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${CYAN}[dev-be]${NC} $*"; }
ok()  { echo -e "${GREEN}[dev-be]${NC} $*"; }
err() { echo -e "${RED}[dev-be]${NC} $*" >&2; }

cd "$BE_DIR"

if [ ! -d "node_modules" ]; then
  log "Installing dependencies..."
  npm install
fi

log "Starting CMS Backend (tsx watch)..."
log "Port: 3001 | http://localhost:3001"
echo ""
exec npm run dev
