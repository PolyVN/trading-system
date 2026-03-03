#!/usr/bin/env bash
# =============================================================================
# dev-all.sh — Start all dev services (DB + TE + Backend + Frontend)
# Usage:
#   ./scripts/dev/dev-all.sh                  # start everything
#   ./scripts/dev/dev-all.sh --no-te          # skip Trading Engine
#   ./scripts/dev/dev-all.sh --no-be          # skip CMS Backend
#   ./scripts/dev/dev-all.sh --no-fe          # skip CMS Frontend
#   ./scripts/dev/dev-all.sh --no-te --no-fe  # only DB + Backend
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts/dev"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[dev-all]${NC} $*"; }
ok()   { echo -e "${GREEN}[dev-all]${NC} $*"; }
warn() { echo -e "${YELLOW}[dev-all]${NC} $*"; }
err()  { echo -e "${RED}[dev-all]${NC} $*" >&2; }

# Parse flags
RUN_TE=true
RUN_BE=true
RUN_FE=true

for arg in "$@"; do
  case "$arg" in
    --no-te) RUN_TE=false ;;
    --no-be) RUN_BE=false ;;
    --no-fe) RUN_FE=false ;;
    *)
      err "Unknown flag: $arg"
      echo "Usage: $0 [--no-te] [--no-be] [--no-fe]"
      exit 1
      ;;
  esac
done

# Track child PIDs for cleanup
PIDS=()

cleanup() {
  echo ""
  warn "Shutting down services..."
  for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  # Wait briefly for graceful shutdown
  sleep 2
  for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  done
  ok "All services stopped."
  warn "Docker databases are still running. Run ./scripts/dev/dev-db.sh down to stop them."
}

trap cleanup EXIT INT TERM

# --- Step 1: Start databases ---
log "Step 1/2: Starting databases..."
bash "$SCRIPTS_DIR/dev-db.sh" up
echo ""

# --- Step 2: Start app services ---
log "Step 2/2: Starting app services..."
echo ""

if [ "$RUN_TE" = true ]; then
  log "Launching Trading Engine..."
  bash "$SCRIPTS_DIR/dev-te.sh" &
  PIDS+=($!)
  sleep 1
fi

if [ "$RUN_BE" = true ]; then
  log "Launching CMS Backend..."
  bash "$SCRIPTS_DIR/dev-be.sh" &
  PIDS+=($!)
  sleep 1
fi

if [ "$RUN_FE" = true ]; then
  log "Launching CMS Frontend..."
  bash "$SCRIPTS_DIR/dev-fe.sh" &
  PIDS+=($!)
  sleep 1
fi

echo ""
echo -e "${BOLD}========================================${NC}"
ok "Dev environment running!"
echo -e "${BOLD}========================================${NC}"
echo -e "  MongoDB:         ${CYAN}mongodb://localhost:27017${NC}"
echo -e "  Redis:           ${CYAN}redis://localhost:6379${NC}"
[ "$RUN_FE" = true ] && echo -e "  CMS Frontend:    ${CYAN}http://localhost:3000${NC}"
[ "$RUN_BE" = true ] && echo -e "  CMS Backend:     ${CYAN}http://localhost:3001${NC}"
[ "$RUN_TE" = true ] && echo -e "  Trading Engine:  ${CYAN}http://localhost:3010${NC}"
echo -e "${BOLD}========================================${NC}"
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop all services"
echo ""

# Wait for all child processes
wait
