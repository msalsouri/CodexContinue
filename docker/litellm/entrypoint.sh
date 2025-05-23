#!/bin/bash

# Set default environment variables if not provided
export OLLAMA_API_BASE=${OLLAMA_API_BASE:-http://ollama:11434}
export MODEL_NAME=${MODEL_NAME:-codexcontinue}
export PORT=${PORT:-8000}
export HOST=${HOST:-0.0.0.0}

echo "Starting LiteLLM server with Ollama integration"
echo "API Base: $OLLAMA_API_BASE"
echo "Model: $MODEL_NAME"

# Start LiteLLM using gunicorn
# This provides a production-ready server with better performance
exec gunicorn litellm.proxy.proxy_server:app \
    --bind $HOST:$PORT \
    --workers 2 \
    --timeout 300 \
    --worker-class uvicorn.workers.UvicornWorker
