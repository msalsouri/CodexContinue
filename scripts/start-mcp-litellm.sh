#!/bin/bash

# Script to start the MCP server with RAG capabilities using LiteLLM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================================"
echo "      Starting MCP Server with RAG via LiteLLM        "
echo "======================================================"

cd "$PROJECT_DIR"

# Stop any existing services
echo "Stopping any existing containers..."
docker-compose down

# Start the services with LiteLLM configuration
echo "Starting services with LiteLLM integration..."
# Add platform flag to ensure correct architecture is used
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker-compose -f docker-compose.yml -f docker-compose.litellm.yml up -d

# Wait for services to initialize
echo "Waiting for services to initialize (15 seconds)..."
sleep 15

# Check if services are running
echo "Checking service status..."
docker-compose -f docker-compose.yml -f docker-compose.litellm.yml ps

# Check if rag-proxy is healthy
echo "Checking RAG proxy health..."
if curl -s http://localhost:5001/health | grep -q "healthy"; then
    echo "✅ RAG proxy is healthy!"
    echo ""
    echo "RAG-enabled MCP server is now running!"
    echo ""
    echo "Available endpoints:"
    echo "  - MCP API: http://localhost:5001/v1/completions"
    echo "  - MCP Chat API: http://localhost:5001/v1/chat/completions"
    echo "  - MCP Models: http://localhost:5001/v1/models"
    echo "  - RAG Import: http://localhost:5001/rag/import"
    echo "  - RAG Query: http://localhost:5001/rag/query"
    echo ""
    echo "To import documents into the knowledge base:"
    echo 'curl -X POST http://localhost:5001/rag/import -H "Content-Type: application/json" -d '\''{"directory_path": "/app/data/knowledge_base"}'\'''
    echo ""
    echo "To test the RAG capabilities:"
    echo 'curl -X POST http://localhost:5001/v1/chat/completions -H "Content-Type: application/json" -d '\''{"model": "codexcontinue", "messages": [{"role": "user", "content": "What concepts do you know from the documents?"}], "use_rag": true}'\'''
else
    echo "❌ RAG proxy is not responding correctly."
    echo "Checking logs:"
    docker-compose -f docker-compose.yml -f docker-compose.litellm.yml logs rag-proxy
fi
