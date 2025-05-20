#!/bin/bash

echo "=== CodexContinue WSL NVIDIA Docker Fix ==="
echo "This script configures Docker to work with NVIDIA GPUs in WSL"
echo

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "Please install Docker before running this script:"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "sudo sh get-docker.sh"
    exit 1
fi

# Check if the NVIDIA Container Toolkit is installed
if ! command -v nvidia-container-toolkit &> /dev/null; then
    echo "Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    
    echo "✅ NVIDIA Container Toolkit installed"
else
    echo "✅ NVIDIA Container Toolkit already installed"
fi

# Configure Docker to use NVIDIA runtime
echo "Configuring Docker for NVIDIA GPUs..."
sudo nvidia-ctk runtime configure --runtime=docker
echo "✅ Docker configured"

# Restart Docker
echo "Restarting Docker service..."
sudo systemctl restart docker
echo "✅ Docker restarted"

# Verify configuration
echo
echo "Verifying Docker NVIDIA configuration..."
if docker info | grep -q "nvidia"; then
    echo "✅ Docker is configured with NVIDIA runtime"
else
    echo "❌ Docker is not properly configured with NVIDIA runtime"
    echo "Please check the Docker daemon configuration in /etc/docker/daemon.json"
    exit 1
fi

echo
echo "=== Fix Completed ==="
echo "Testing NVIDIA GPU support in Docker..."
echo
echo "Running test container with GPU access:"
docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi

echo
echo "If you see the GPU information above, your setup is working correctly!"
echo "You can now run Ollama with GPU support in WSL:"
echo "docker compose -f docker-compose.yml up"