#!/bin/bash
# Script to verify GPU support for Ollama on Windows

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

# Check if running on Windows
if [[ "$(uname -s)" != *"MINGW"* ]] && [[ "$(uname -s)" != *"MSYS"* ]] && [[ "$(uname -s)" != "Linux" ]]; then
    warn "This script is designed to check GPU support on Windows. You appear to be running on a different platform."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "Checking GPU support for Ollama..."

# Test if nvidia-smi is available
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA SMI is installed. Checking GPU:"
    nvidia-smi
else
    error "NVIDIA SMI not found. Please ensure NVIDIA drivers are installed."
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running. Please start Docker and try again."
fi

# Test Docker GPU support
log "Testing GPU support in Docker..."
if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
    log "GPU is accessible from Docker containers."
    docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
else
    error "Failed to access GPU from Docker. Please ensure NVIDIA Docker support is properly set up."
fi

# Check Ollama container
log "Checking if Ollama container is running..."
if docker ps | grep -q "codexcontinue-ollama"; then
    log "Ollama container is running. Checking GPU access within container..."
    docker exec codexcontinue-ollama-1 nvidia-smi
    
    if [ $? -eq 0 ]; then
        log "Ollama container has access to GPU."
        
        # Test Ollama model with GPU
        log "Testing Ollama model performance..."
        START=$(date +%s)
        
        curl -s -X POST http://localhost:11434/api/generate -d '{
          "model": "codexcontinue",
          "prompt": "Write a simple function in Python.",
          "num_predict": 100
        }' > /dev/null
        
        END=$(date +%s)
        DIFF=$((END-START))
        
        log "Model response time: ${DIFF} seconds"
        
        if [ $DIFF -lt 5 ]; then
            log "Performance looks good! GPU acceleration is likely working."
        else
            warn "Response time seems high. GPU acceleration may not be fully utilized."
        fi
    else
        warn "Ollama container cannot access GPU. Check Docker configuration."
    fi
else
    warn "Ollama container is not running. Start it with: docker compose up -d ollama"
fi

log "GPU support check completed."
