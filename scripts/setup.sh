#!/usr/bin/env bash
# =============================================================================
# setup.sh — Install all dev dependencies for the trading system
# Run once after cloning the repo.
# Usage: ./scripts/setup.sh
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[setup]${NC} $*"; }
ok()   { echo -e "${GREEN}[setup]${NC} ✓ $*"; }
warn() { echo -e "${YELLOW}[setup]${NC} ⚠ $*"; }
err()  { echo -e "${RED}[setup]${NC} ✗ $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

ERRORS=0

require_cmd() {
  local cmd="$1" hint="$2"
  if ! command -v "$cmd" &>/dev/null; then
    err "Required: '$cmd' not found. $hint"
    ERRORS=$((ERRORS + 1))
  else
    ok "$cmd found ($(command -v "$cmd"))"
  fi
}

# =============================================================================
section "Checking required system tools"
# =============================================================================

require_cmd docker   "Install Docker Desktop: https://docs.docker.com/get-docker/"
require_cmd cargo    "Install Rust: https://rustup.rs/"
require_cmd node     "Install Node.js 22 LTS: https://nodejs.org/"
require_cmd npm      "Install Node.js 22 LTS: https://nodejs.org/"

if [ $ERRORS -gt 0 ]; then
  err "$ERRORS required tool(s) missing. Please install them and re-run."
  exit 1
fi

# =============================================================================
section "Cargo tools (Rust)"
# =============================================================================

install_cargo_tool() {
  local crate="$1" bin="${2:-$1}"
  if cargo "$bin" --version &>/dev/null 2>&1; then
    ok "$crate already installed"
  else
    log "Installing $crate..."
    cargo install "$crate"
    ok "$crate installed"
  fi
}

install_cargo_tool "cargo-watch" "watch"

# =============================================================================
section "Node.js dependencies"
# =============================================================================

install_npm() {
  local dir="$1" label="$2"
  if [ -d "$dir/node_modules" ]; then
    ok "$label node_modules already present (skipping)"
  else
    log "Installing $label dependencies..."
    npm install --prefix "$dir"
    ok "$label installed"
  fi
}

install_npm "$ROOT_DIR/packages/cms-backend"  "cms-backend"
install_npm "$ROOT_DIR/packages/cms-frontend" "cms-frontend"

# =============================================================================
section "Environment files"
# =============================================================================

check_env() {
  local src="$1" dst="$2" label="$3"
  if [ -f "$dst" ]; then
    ok "$label ($dst) exists"
  else
    log "Copying $label from example..."
    cp "$src" "$dst"
    warn "$label created from example — review and update secrets if needed: $dst"
  fi
}

check_env \
  "$ROOT_DIR/packages/docker/dev/.env.example" \
  "$ROOT_DIR/packages/docker/dev/.env" \
  "docker dev .env"

check_env \
  "$ROOT_DIR/packages/cms-backend/.env.example" \
  "$ROOT_DIR/packages/cms-backend/.env" \
  "cms-backend .env"

# =============================================================================
section "Summary"
# =============================================================================

echo ""
ok "Setup complete! Next steps:"
echo -e "  1. Start databases:      ${CYAN}./scripts/dev/dev-db.sh${NC}"
echo -e "  2. Start trading engine: ${CYAN}./scripts/dev/dev-te.sh${NC}"
echo -e "  3. Start CMS backend:    ${CYAN}./scripts/dev/dev-be.sh${NC}"
echo -e "  4. Start CMS frontend:   ${CYAN}./scripts/dev/dev-fe.sh${NC}"
echo -e "  (or run all at once):    ${CYAN}./scripts/dev/dev-all.sh${NC}"
echo ""
