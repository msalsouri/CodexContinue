#!/bin/bash

# Script to verify GPU integration with Ollama in WSL environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  Verifying GPU Integration with Ollama in WSL"
echo "============================================"

cd "$PROJECT_DIR"

# Check if Docker GPU is working 
echo "Checking Docker GPU support..."
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# Check if Ollama container is running
echo "Checking Ollama container status..."
if ! docker-compose ps | grep -q "ollama"; then
    echo "Ollama container is not running. Starting containers..."
    docker-compose -f docker-compose.yml up -d ollama
    echo "Waiting for Ollama to start up..."
    sleep 10
else
    echo "Ollama container is already running."
fi

# Check if Ollama has access to GPU in container
echo "Verifying Ollama GPU access..."
docker-compose exec ollama nvidia-smi

# Check Ollama's API for GPU information
echo "Checking GPU support via Ollama API..."
curl -s http://localhost:11434/api/info | jq '.'

echo "============================================"
echo "Ollama GPU verification completed."
echo "If you see GPU information above, GPU integration is working!"
echo "If you don't see GPU information, check troubleshooting in docs/WSL_GPU_STATUS.md"
echo "============================================"
