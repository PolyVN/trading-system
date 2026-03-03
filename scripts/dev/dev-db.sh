#!/usr/bin/env bash
# =============================================================================
# dev-db.sh — Start/stop Docker dev databases (MongoDB + Redis)
# Usage:
#   ./scripts/dev/dev-db.sh          # start (default)
#   ./scripts/dev/dev-db.sh up       # start
#   ./scripts/dev/dev-db.sh down     # stop and remove
#   ./scripts/dev/dev-db.sh status   # show container status
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMPOSE_DIR="$ROOT_DIR/packages/docker/dev"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

# Source credentials from .env
if [ -f "$COMPOSE_DIR/.env" ]; then
  set -a; source "$COMPOSE_DIR/.env"; set +a
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[dev-db]${NC} $*"; }
ok()   { echo -e "${GREEN}[dev-db]${NC} $*"; }
warn() { echo -e "${YELLOW}[dev-db]${NC} $*"; }
err()  { echo -e "${RED}[dev-db]${NC} $*" >&2; }

cmd_up() {
  log "Starting MongoDB + Redis..."
  docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" up -d

  log "Waiting for MongoDB to be healthy..."
  local retries=30
  while [ $retries -gt 0 ]; do
    if docker exec dev-mongodb mongosh -u "${MONGO_USER:-admin}" -p "${MONGO_PASS:-devpassword123}" --quiet --eval "db.adminCommand('ping')" &>/dev/null; then
      ok "MongoDB is ready (port 27017)"
      break
    fi
    retries=$((retries - 1))
    sleep 1
  done
  if [ $retries -eq 0 ]; then
    err "MongoDB failed to start within 30s"
    return 1
  fi

  log "Waiting for Redis to be ready..."
  retries=15
  while [ $retries -gt 0 ]; do
    if docker exec dev-redis redis-cli -a "${REDIS_PASSWORD:-devpassword123}" ping 2>/dev/null | grep -q PONG; then
      ok "Redis is ready (port 6379)"
      break
    fi
    retries=$((retries - 1))
    sleep 1
  done
  if [ $retries -eq 0 ]; then
    err "Redis failed to start within 15s"
    return 1
  fi

  echo ""
  ok "Databases ready!"
  echo -e "  MongoDB: ${CYAN}mongodb://localhost:27017${NC}"
  echo -e "  Redis:   ${CYAN}redis://localhost:6379${NC}"
}

cmd_down() {
  log "Stopping databases..."
  docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" down
  ok "Databases stopped."
}

cmd_status() {
  docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_DIR/.env" ps
}

# --- Main ---
case "${1:-up}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  *)
    err "Unknown command: $1"
    echo "Usage: $0 [up|down|status]"
    exit 1
    ;;
esac
