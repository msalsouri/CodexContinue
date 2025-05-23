#!/bin/bash

# Script to initialize the ML service step by step

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "==== ML Service Initialization ===="

echo "Step 1: Stopping any existing containers"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
echo "✓ Containers stopped"

echo "Step 2: Creating necessary directories"
mkdir -p data/vectorstore data/knowledge_base
echo "✓ Data directories created"

echo "Step 3: Building the ML service container"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build ml-service
echo "✓ ML service built"

echo "Step 4: Starting Ollama service"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d ollama
echo "✓ Ollama service started"

echo "Step 5: Running ML service in interactive mode for debugging"
echo "Press Ctrl+C to exit when done testing"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run \
  --service-ports \
  --rm \
  -e PYTHONPATH=/app \
  -e FLASK_APP=ml/app.py \
  -e VECTOR_DB_PATH=/app/data/vectorstore \
  -e KNOWLEDGE_BASE_PATH=/app/data/knowledge_base \
  -e OLLAMA_API_URL=http://ollama:11434 \
  ml-service python ml/app.py

echo "==== ML Service shutdown ===="
