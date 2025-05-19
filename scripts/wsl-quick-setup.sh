#!/bin/bash
# Windows WSL Quick Setup Helper
# Run this script after cloning the repository to set up quickly on WSL

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Make sure we're in the project root
cd "$(dirname "$0")/.." || error "Failed to change to project root directory"

echo "=== CodexContinue WSL Quick Setup ==="
echo "This script will help you quickly set up the CodexContinue environment in WSL."

# Verify WSL environment
log "Verifying WSL environment..."
./scripts/check-platform.sh

# Check Docker installation
log "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    error "Docker not found. Please install Docker in WSL following instructions in docs/WSL_SETUP.md"
fi

if ! command -v docker-compose &> /dev/null; then
    warn "docker-compose not found. Checking for Docker Compose plugin..."
    if ! docker compose version &> /dev/null; then
        error "Docker Compose not found. Please install Docker Compose in WSL following instructions in docs/WSL_SETUP.md"
    else
        log "Docker Compose plugin is installed."
    fi
else
    log "docker-compose is installed."
fi

# Check NVIDIA Container Toolkit
log "Checking NVIDIA Container Toolkit..."
if docker info 2>/dev/null | grep -q "Runtimes: nvidia"; then
    log "NVIDIA Container Toolkit is installed."
else
    warn "NVIDIA Container Toolkit may not be installed."
    info "To install NVIDIA Container Toolkit, follow the instructions in docs/WSL_SETUP.md"
    read -p "Would you like to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start services
log "Starting CodexContinue services..."
docker compose up -d

if [ $? -ne 0 ]; then
    error "Failed to start services. Check the error messages above."
fi

# Wait for services to be ready
log "Waiting for services to initialize..."
sleep 10

# Check Ollama model
log "Checking Ollama model..."
./scripts/check_ollama_model.sh

# Final instructions
log "Setup completed!"
log "Access the services at:"
info "- Frontend: http://localhost:8501"
info "- Backend API: http://localhost:8000"
info "- ML Service: http://localhost:5000"
info "- Jupyter Lab: http://localhost:8888"
info "- Ollama API: http://localhost:11434"

log "For more information, see:"
info "- docs/CROSS_PLATFORM_DEVELOPMENT.md"
info "- docs/WSL_SETUP.md"
info "- docs/OLLAMA_MODEL_TESTING.md"
