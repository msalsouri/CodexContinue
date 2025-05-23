#!/bin/bash

# Script to start the ML service with MCP and RAG capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
CONTAINER_NAME="codexcontinue-ml-service-1"
ML_PORT=5000
MAX_RETRIES=10

echo "Starting ML service with MCP and RAG capabilities..."

# Start services with docker-compose
cd "$PROJECT_DIR"
echo "Starting ml-service and dependencies..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d ml-service

# Wait for the container to be fully started
echo "Waiting for ML service container to start..."
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "ML service container is running."
        break
    fi
    echo "Waiting for container to start... (${retry_count}/${MAX_RETRIES})"
    sleep 3
    retry_count=$((retry_count + 1))
done

if [ $retry_count -eq $MAX_RETRIES ]; then
    echo "Error: ML service container failed to start after multiple attempts."
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Give the container a moment to fully initialize
sleep 5

# Ensure requirements are installed
echo "Installing required packages in the container..."
if ! docker exec "$CONTAINER_NAME" pip install --no-cache-dir -r /app/ml/requirements.txt; then
    echo "Error: Failed to install requirements. Container might not be ready."
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Create data directories
echo "Creating necessary directories..."
docker exec "$CONTAINER_NAME" mkdir -p /app/data/vectorstore
docker exec "$CONTAINER_NAME" mkdir -p /app/data/knowledge_base
docker exec "$CONTAINER_NAME" mkdir -p /app/ml/scripts/test_data

# Run the ML service with the updated app.py
echo "Starting the ML service with MCP..."
docker exec -d "$CONTAINER_NAME" python /app/ml/app.py

# Wait for the service to initialize
echo "Waiting for the ML service to initialize..."
sleep 8

# Check if the service is healthy
echo "Checking ML service health..."
for i in {1..5}; do
    if curl -s http://localhost:$ML_PORT/health | grep -q "healthy"; then
        echo "ML service is healthy!"
        echo "MCP endpoints available at:"
        echo "  - http://localhost:$ML_PORT/v1/completions"
        echo "  - http://localhost:$ML_PORT/v1/chat/completions"
        echo "  - http://localhost:$ML_PORT/v1/models"
        echo "RAG endpoints available at:"
        echo "  - http://localhost:$ML_PORT/rag/import"
        echo "  - http://localhost:$ML_PORT/rag/query"
        echo
        echo "To test the service, run:"
        echo "  python ml/scripts/test_mcp_rag.py"
        exit 0
    fi
    echo "Service not ready yet, retrying... ($i/5)"
    sleep 5
done

echo "ML service is not responding correctly. Check logs for errors."
docker logs "$CONTAINER_NAME"
