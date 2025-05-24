#!/bin/bash
# Script to diagnose Ollama connectivity from the frontend container

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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

# Make sure we're in the project root
cd "$(dirname "$0")/.." || error "Failed to change to project root directory"

log "Checking Ollama connectivity from frontend container..."

# Test if Ollama is accessible from the frontend container
docker exec codexcontinue-frontend-1 curl -v http://ollama:11434/api/tags
RESULT=$?
HTTP_CODE=$(docker exec codexcontinue-frontend-1 curl -s -o /dev/null -w "%{http_code}" http://ollama:11434/api/tags 2>/dev/null || echo "000")

if [ $RESULT -eq 0 ] && [ "$HTTP_CODE" = "200" ]; then
    log "Ollama is accessible from the frontend container (HTTP 200)"
else
    error "Ollama is NOT accessible from the frontend container (HTTP $HTTP_CODE)"
    
    # Check if Ollama container is running
    if docker ps | grep -q codexcontinue-ollama-1; then
        log "Ollama container is running"
    else
        error "Ollama container is NOT running"
    fi
    
    # Check if Ollama is accessible from the host
    log "Checking Ollama from host..."
    curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags
    HOST_RESULT=$?
    HOST_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags)
    
    if [ $HOST_RESULT -eq 0 ] && [ "$HOST_HTTP_CODE" = "200" ]; then
        log "Ollama is accessible from the host (HTTP 200)"
    else
        error "Ollama is NOT accessible from the host (HTTP $HOST_HTTP_CODE)"
    fi
    
    # Check network connectivity between containers
    log "Checking network connectivity between containers..."
    docker exec codexcontinue-frontend-1 ping -c 1 ollama
    PING_RESULT=$?
    
    if [ $PING_RESULT -eq 0 ]; then
        log "Network connectivity to Ollama container is OK"
    else
        error "Network connectivity to Ollama container FAILED"
    fi
    
    # Suggest solutions
    log "Potential solutions:"
    log "1. Restart the Ollama container: docker compose -f docker-compose.yml -f docker-compose.dev.yml restart ollama"
    log "2. Update the frontend code to use the correct Ollama URL"
    log "3. Rebuild and restart all containers: docker compose -f docker-compose.yml -f docker-compose.dev.yml down && docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d"
fi
