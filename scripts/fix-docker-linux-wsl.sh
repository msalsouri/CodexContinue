#!/bin/bash
# fix-docker-linux-wsl.sh - Apply fixes for Docker containers in Linux/WSL environments
#
# This script applies the necessary fixes to ensure CodexContinue Docker containers
# work correctly in Linux and Windows Subsystem for Linux (WSL) environments.

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Make sure we're in the project root
cd "$(dirname "$0")/.."
ROOT_DIR=$(pwd)

echo "==============================================="
echo "CodexContinue Docker Fix for Linux/WSL"
echo "==============================================="
echo

section "Stopping any running containers"
docker-compose down || warn "No containers were running or docker-compose failed"

section "Applying fixes"
log "Setting correct permissions for scripts"
chmod +x scripts/*.sh scripts/check-service-access.py

section "Starting services with fixes applied"
log "Starting all services using docker-compose"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

section "Verifying services"
log "Waiting for services to start (15 seconds)"
sleep 15

log "Testing service accessibility"
python3 scripts/check-service-access.py

section "Summary"
log "Docker fixes have been applied and services started."
log "If you still encounter issues, see: docs/troubleshooting/DOCKER_LINUX_WSL_TROUBLESHOOTING.md"
log "You can also run services independently using scripts/start-ml-service.sh"

exit 0
