#!/bin/bash

# Script to start the ML service with GPU support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================================"
echo "      Starting ML Service with GPU Support        "
echo "======================================================"

cd "$PROJECT_DIR"

# Check for NVIDIA GPU availability on host
if ! command -v nvidia-smi &> /dev/null; then
    echo "Warning: nvidia-smi command not found. NVIDIA drivers may not be installed."
    echo "GPU acceleration may not work properly."
else
    echo "NVIDIA GPU detected on host system:"
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
fi

# Stop any existing containers
echo "Stopping any existing containers..."
docker-compose down --remove-orphans

# Build the GPU-specific ML service image
echo "Building ML service with GPU support..."
docker-compose -f docker-compose.yml -f docker-compose.gpu.yml build ml-service

# Start the services with GPU configuration
echo "Starting services with GPU support..."
docker-compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# Wait for services to initialize
echo "Waiting for services to initialize (10 seconds)..."
sleep 10

# Check if Ollama has access to GPU
echo "Checking if Ollama has GPU access..."
docker-compose exec ollama nvidia-smi || echo "WARNING: GPU not detected in Ollama container!"

# Check if ML service is running
echo "Checking if ML service is running properly..."
curl -s http://localhost:5000/health | grep -q "healthy" && echo "ML service is healthy!" || echo "ML service may have issues!"

echo ""
echo "Services are now running!"
echo "ML Service is available at: http://localhost:5000"
echo "Ollama is available at: http://localhost:11434"
echo ""
echo "To verify GPU support, run: ./scripts/verify-gpu-ollama-wsl.sh"
