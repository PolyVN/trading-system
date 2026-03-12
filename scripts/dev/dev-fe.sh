#!/usr/bin/env bash
# =============================================================================
# dev-fe.sh — Run CMS Frontend (Next.js) with hot-reload (Fast Refresh)
# Usage: ./scripts/dev-fe.sh
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FE_DIR="$ROOT_DIR/packages/cms-frontend"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${CYAN}[dev-fe]${NC} %s\n" "$*"; }
ok()  { printf "${GREEN}[dev-fe]${NC} %s\n" "$*"; }
err() { printf "${RED}[dev-fe]${NC} %s\n" "$*" >&2; }

cd "$FE_DIR"

if [ ! -d "node_modules" ]; then
  log "Installing dependencies..."
  npm install
fi

log "Starting CMS Frontend (Next.js dev)..."
log "Port: 3000 | http://localhost:3000"
echo ""
exec npm run dev
