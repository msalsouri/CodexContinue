#!/bin/bash
# GPU Troubleshooting script for Windows WSL
# Helps diagnose and fix common GPU issues in WSL environments

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
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "=== CodexContinue GPU Troubleshooting Tool for WSL ==="
echo "This script will help diagnose and fix common GPU issues in WSL."

# Check if running in WSL
if ! grep -q Microsoft /proc/version 2>/dev/null && ! grep -q microsoft /proc/version 2>/dev/null; then
    error "This script is designed for Windows WSL environments only."
    exit 1
fi

log "Running in WSL environment. Proceeding with diagnostics..."

# Check WSL version
if grep -q "WSL2" /proc/version 2>/dev/null; then
    log "WSL Version: 2 (Good)"
else
    error "WSL Version: 1"
    error "GPU passthrough requires WSL 2. Please upgrade to WSL 2:"
    info "In PowerShell (as Administrator):"
    info "wsl --set-default-version 2"
    info "wsl --set-version Ubuntu 2"
    exit 1
fi

# Step 1: Check NVIDIA drivers in Windows
log "Step 1: Checking NVIDIA drivers..."
if ! command -v nvidia-smi &> /dev/null; then
    error "nvidia-smi command not found."
    info "Please make sure you have:"
    info "1. NVIDIA GPU drivers installed in Windows"
    info "2. NVIDIA driver for WSL installed"
    info "   Download from: https://developer.nvidia.com/cuda/wsl"
    info "3. CUDA installed in WSL"
    exit 1
else
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    log "NVIDIA driver version: $DRIVER_VERSION"
    if [[ $(echo "$DRIVER_VERSION" | cut -d. -f1) -lt 470 ]]; then
        warn "Driver version may be too old for WSL 2 GPU support."
        info "Consider updating to version 470.76 or higher."
    else
        log "Driver version is compatible with WSL 2 GPU support."
    fi
    
    # Display GPU info
    echo
    log "GPU information:"
    nvidia-smi
    echo
fi

# Step 2: Check NVIDIA Container Toolkit
log "Step 2: Checking NVIDIA Container Toolkit..."
if ! grep -q "nvidia" /etc/docker/daemon.json 2>/dev/null; then
    warn "NVIDIA Container Toolkit may not be properly configured."
    info "Would you like to install/configure NVIDIA Container Toolkit? (y/n)"
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Installing NVIDIA Container Toolkit..."
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt-get update
        sudo apt-get install -y nvidia-docker2
        
        # Configure Docker
        if [ ! -f /etc/docker/daemon.json ]; then
            echo '{"runtimes": {"nvidia": {"path": "nvidia-container-runtime", "runtimeArgs": []}}}' | sudo tee /etc/docker/daemon.json
        else
            # Backup existing daemon.json
            sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
            # Add nvidia runtime if not present
            if ! grep -q "nvidia" /etc/docker/daemon.json; then
                sudo sed -i 's/\({.*\)\}/\1, "runtimes": {"nvidia": {"path": "nvidia-container-runtime", "runtimeArgs": []}}}/g' /etc/docker/daemon.json
            fi
        fi
        
        # Restart Docker
        log "Restarting Docker service..."
        sudo systemctl restart docker
        sleep 5
    else
        info "Skipping NVIDIA Container Toolkit installation."
    fi
else
    log "NVIDIA Container Toolkit appears to be configured."
fi

# Step 3: Test Docker GPU access
log "Step 3: Testing Docker GPU access..."
if ! docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
    error "Docker cannot access GPU."
    info "Troubleshooting steps:"
    info "1. Make sure Docker is running: sudo service docker start"
    info "2. Check Docker's nvidia runtime configuration: cat /etc/docker/daemon.json"
    info "3. Restart Docker: sudo systemctl restart docker"
    info "4. If issue persists, restart WSL: wsl --shutdown (from PowerShell)"
else
    log "Docker has access to GPU. Testing with nvidia-smi:"
    docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
fi

# Step 4: Check Ollama container
log "Step 4: Checking Ollama container..."
if ! docker ps | grep -q "codexcontinue-ollama"; then
    warn "Ollama container is not running."
    info "Would you like to start it now? (y/n)"
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Starting Ollama container with GPU support..."
        cd "$(dirname "$0")/.." || exit 1
        ./scripts/start-ollama-wsl.sh
    else
        info "Skipping Ollama container start."
    fi
elif ! docker exec codexcontinue-ollama-1 nvidia-smi &> /dev/null; then
    warn "Ollama container cannot access GPU."
    info "Would you like to restart the Ollama container with GPU support? (y/n)"
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Stopping current Ollama container..."
        docker stop codexcontinue-ollama-1
        docker rm codexcontinue-ollama-1
        
        log "Starting Ollama container with GPU support..."
        cd "$(dirname "$0")/.." || exit 1
        ./scripts/start-ollama-wsl.sh
    else
        info "Skipping Ollama container restart."
    fi
else
    log "Ollama container has access to GPU."
fi

# Final summary
echo
log "====== GPU Troubleshooting Summary ======"
if command -v nvidia-smi &> /dev/null && \
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null && \
   (docker ps | grep -q "codexcontinue-ollama" && docker exec codexcontinue-ollama-1 nvidia-smi &> /dev/null)
then
    log "All checks passed! GPU is properly configured for CodexContinue in WSL."
    info "You can now use CodexContinue with GPU acceleration."
else
    warn "Some GPU checks failed. Review the messages above for specific issues."
    info "For more help, see the WSL Setup guide: docs/WSL_SETUP.md"
fi
