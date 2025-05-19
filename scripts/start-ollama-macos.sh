#!/bin/bash
# Script to start the Ollama service on macOS (without GPU requirements)

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
    exit 1
}

echo "=== Starting Ollama Service for macOS ==="

# Check Docker is running
log "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
  error "Docker is not running. Please start Docker and try again."
fi
log "Docker is running."

# Start just the Ollama service with macOS configuration
log "Starting Ollama service (CPU-only for macOS)..."
docker compose -f docker-compose.yml -f docker-compose.macos.yml up -d ollama

if [ $? -eq 0 ]; then
    log "Ollama service started successfully."
    log "Waiting for Ollama to initialize..."
    
    # Wait for Ollama to be ready
    attempts=0
    max_attempts=30
    until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
        attempts=$((attempts+1))
        if [ $attempts -ge $max_attempts ]; then
            error "Ollama service did not become ready in time."
        fi
        echo "Waiting for Ollama service... (attempt $attempts/$max_attempts)"
        sleep 2
    done
    
    log "Ollama is now running and accessible at http://localhost:11434"
    log "To check if the CodexContinue model is available:"
    echo "  ./scripts/check_ollama_model.sh"
    
    log "To build the CodexContinue model if needed:"
    echo "  docker exec codexcontinue-ml-service-1 bash -c \"cd /app && ./ml/scripts/build_codexcontinue_model.sh\""
else
    error "Failed to start Ollama service."
fi
