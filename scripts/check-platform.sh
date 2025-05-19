#!/bin/bash
# Script to detect if running in WSL and verify GPU access

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

# Check if running in WSL
if grep -q Microsoft /proc/version 2>/dev/null || grep -q microsoft /proc/version 2>/dev/null; then
    log "Running in Windows Subsystem for Linux (WSL)"
    
    # Check WSL version
    if grep -q "WSL2" /proc/version 2>/dev/null; then
        log "WSL Version: 2 (Good)"
    else
        warn "WSL Version: 1"
        warn "WSL 2 is recommended for better performance and GPU support"
        info "To update to WSL 2, run the following in PowerShell as Administrator:"
        info "wsl --set-default-version 2"
        info "wsl --set-version Ubuntu 2"
    fi
    
    # Check GPU access in WSL
    if command -v nvidia-smi &> /dev/null; then
        log "NVIDIA drivers are installed in WSL"
        
        # Run nvidia-smi to check GPU status
        echo
        echo "GPU Information:"
        echo "================"
        nvidia-smi
        echo
        
        # Check Docker GPU access
        log "Checking Docker GPU access..."
        if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
            log "Docker has access to GPU in WSL (Excellent)"
        else
            error "Docker cannot access GPU in WSL"
            info "To enable GPU access in Docker, try:"
            info "1. Install NVIDIA Container Toolkit:"
            info "   distribution=\$(. /etc/os-release;echo \$ID\$VERSION_ID)"
            info "   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -"
            info "   curl -s -L https://nvidia.github.io/nvidia-docker/\$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list"
            info "   sudo apt-get update"
            info "   sudo apt-get install -y nvidia-docker2"
            info "2. Restart Docker:"
            info "   sudo systemctl restart docker"
        fi
    else
        warn "NVIDIA drivers are not installed in WSL"
        info "To install NVIDIA drivers in WSL, follow instructions in docs/WSL_SETUP.md"
    fi
    
    # Check WSL resource limits
    if [ -f /proc/meminfo ]; then
        total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_mem_gb=$((total_mem / 1024 / 1024))
        log "WSL Memory Allocation: ${total_mem_gb}GB"
        
        if [ $total_mem_gb -lt 4 ]; then
            warn "Memory allocation is low, consider increasing it in .wslconfig"
            info "See docs/WSL_SETUP.md for instructions on setting WSL resource limits"
        fi
    fi
else
    # Not running in WSL
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log "Running on native Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log "Running on macOS"
        info "For macOS, use the CPU-only configuration:"
        info "./scripts/start-ollama-macos.sh"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        log "Running on Windows (not WSL)"
        info "Consider using WSL for better Docker and GPU integration"
        info "See docs/WSL_SETUP.md for instructions"
    else
        log "Running on unknown platform: $OSTYPE"
    fi
fi

log "Platform check completed."
