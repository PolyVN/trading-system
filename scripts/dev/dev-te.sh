#!/usr/bin/env bash
# =============================================================================
# dev-te.sh — Run Trading Engine (Rust) with auto-recompile
# Requires: cargo-watch (install: cargo install cargo-watch)
# Usage:
#   ./scripts/dev-te.sh              # run with cargo-watch (auto-recompile)
#   ./scripts/dev-te.sh --once       # single run without watch
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TE_DIR="$ROOT_DIR/packages/trading-engine"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[dev-te]${NC} $*"; }
ok()   { echo -e "${GREEN}[dev-te]${NC} $*"; }
warn() { echo -e "${YELLOW}[dev-te]${NC} $*"; }
err()  { echo -e "${RED}[dev-te]${NC} $*" >&2; }

# Source env vars
ENV_HOST="$ROOT_DIR/packages/docker/dev/.env.host"
if [ -f "$ENV_HOST" ]; then
  log "Loading env from .env.host..."
  set -a
  source "$ENV_HOST"
  set +a
else
  err ".env.host not found at $ENV_HOST"
  exit 1
fi

cd "$TE_DIR"

# Kill any existing process on TE port (default 3010)
TE_PORT="${PORT:-3010}"
kill_port() {
  local pids
  if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || "$OSTYPE" == win* ]]; then
    # Windows: use netstat + taskkill
    pids=$(netstat -ano 2>/dev/null | grep ":${TE_PORT} " | grep 'LISTENING' | awk '{print $5}' | sort -u || true)
    for pid in $pids; do
      if [ -n "$pid" ] && [ "$pid" != "0" ]; then
        warn "Killing PID $pid on port $TE_PORT..."
        taskkill //F //PID "$pid" 2>/dev/null || true
      fi
    done
  else
    # Unix: use lsof
    pids=$(lsof -ti ":${TE_PORT}" 2>/dev/null || true)
    for pid in $pids; do
      warn "Killing PID $pid on port $TE_PORT..."
      kill -9 "$pid" 2>/dev/null || true
    done
  fi
}
kill_port

if [ "${1:-}" = "--once" ]; then
  log "Starting Trading Engine (single run)..."
  log "Port: 3010 | Engine ID: ${ENGINE_ID:-te-dev-001}"
  exec cargo run
fi

# Check cargo-watch
if cargo watch --version &>/dev/null; then
  ok "cargo-watch detected"
  log "Starting Trading Engine with auto-recompile..."
  log "Port: 3010 | Engine ID: ${ENGINE_ID:-te-dev-001}"
  log "Watching src/ for changes..."
  echo ""
  exec cargo watch -x run -w src -w Cargo.toml
else
  warn "cargo-watch not installed. Install it for auto-recompile:"
  warn "  cargo install cargo-watch"
  echo ""
  warn "Falling back to single cargo run..."
  log "Port: 3010 | Engine ID: ${ENGINE_ID:-te-dev-001}"
  exec cargo run
fi
