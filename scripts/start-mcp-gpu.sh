#!/bin/bash

# Script to start the MCP server with GPU support, avoiding gunicorn issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================================"
echo "      Starting MCP Server with GPU Support        "
echo "======================================================"

cd "$PROJECT_DIR"

# Stop any existing containers
echo "Stopping any existing containers..."
docker-compose down --remove-orphans

# Start only the basic services
echo "Starting core services with GPU setup..."
docker-compose -f docker-compose.yml -f docker-compose.gpu.yml up -d ollama redis

# Wait for services to initialize
echo "Waiting for services to initialize (10 seconds)..."
sleep 10

# Check if Ollama has access to GPU
echo "Checking if Ollama has GPU access..."
docker-compose exec ollama nvidia-smi || echo "WARNING: GPU not detected in Ollama container!"

# Check if services are running
echo "Services are now running!"
echo "Ollama is available at: http://localhost:11434"
echo "Backend API is available at: http://localhost:8000"
echo "Frontend UI is available at: http://localhost:8501"

echo ""
echo "To check GPU support:"
echo "1. Visit the frontend at http://localhost:8501"
echo "2. Run: ./scripts/verify-gpu-ollama-wsl.sh"
echo ""
