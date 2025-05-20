#!/bin/bash
# Script to start the Ollama service on Windows WSL with GPU support

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

# Make sure we're in the project root
cd "$(dirname "$0")/.." || error "Failed to change to project root directory"

echo "=== Starting Ollama Service for Windows WSL with GPU Support ==="

# First, verify we're in WSL
if ! grep -q Microsoft /proc/version 2>/dev/null && ! grep -q microsoft /proc/version 2>/dev/null; then
    warn "This script is designed for Windows WSL. You don't seem to be running in WSL."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Docker is running
log "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
fi
log "Docker is running."

# Check if port 11434 is already in use
log "Checking if port 11434 is already in use..."
if lsof -i :11434 &> /dev/null; then
    warn "Port 11434 is already in use. This might be another Ollama instance."
    echo "Current processes using port 11434:"
    lsof -i :11434
    
    read -p "Do you want to stop the existing process? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to stop the process - first check if it's Ollama
        if lsof -i :11434 | grep -q ollama; then
            log "Stopping Ollama service..."
            # Try systemctl first
            if systemctl stop ollama &> /dev/null; then
                log "Stopped Ollama service"
            else
                # Try to kill the process
                ollama_pid=$(pgrep ollama)
                if [ -n "$ollama_pid" ]; then
                    log "Killing Ollama process with PID $ollama_pid"
                    sudo kill $ollama_pid
                    sleep 2
                    # Verify it's actually stopped
                    if lsof -i :11434 &> /dev/null; then
                        error "Failed to stop the process using port 11434. Please stop it manually and try again."
                    fi
                else
                    error "Could not find Ollama process ID. Please stop it manually and try again."
                fi
            fi
        else
            error "Unknown process using port 11434. Please stop it manually and try again."
        fi
    else
        error "Port 11434 is needed for Ollama. Please free up the port and try again."
    fi
fi
log "Port 11434 is available."

# Check GPU access
log "Checking GPU access..."
if ! nvidia-smi &> /dev/null; then
    warn "NVIDIA drivers don't appear to be installed or accessible in WSL."
    warn "Ollama will run but may not be able to use GPU acceleration."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log "NVIDIA drivers detected."
    nvidia-smi
fi

# Start the Ollama service with GPU support
log "Starting Ollama service with GPU support..."
docker compose up -d ollama

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
    
    # Verify GPU access in container
    log "Verifying GPU access in Ollama container..."
    if docker exec codexcontinue-ollama-1 nvidia-smi &> /dev/null; then
        log "GPU is accessible from Ollama container (Excellent!)"
    else
        warn "GPU is not accessible from Ollama container."
        warn "Performance will be limited to CPU only."
        log "To enable GPU access, please see docs/WSL_SETUP.md"
    fi
    
    log "To check if the CodexContinue model is available:"
    echo "  ./scripts/check_ollama_model.sh"
    
    log "To build the CodexContinue model if needed:"
    echo "  docker exec codexcontinue-ml-service-1 bash -c \"cd /app && ./ml/scripts/build_codexcontinue_model.sh\""
else
    error "Failed to start Ollama service."
fi
