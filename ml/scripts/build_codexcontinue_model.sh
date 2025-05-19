#!/bin/bash

# Script to build the CodexContinue model in the Ollama container

set -e

# Configuration
OLLAMA_API_URL=${OLLAMA_API_URL:-http://ollama:11434}
MODEL_NAME="codexcontinue"
MODELFILE_PATH="/app/ml/models/ollama/Modelfile"

echo "Building the CodexContinue model using Modelfile at ${MODELFILE_PATH}..."
echo "Ollama API URL: ${OLLAMA_API_URL}"

# Check if Ollama is accessible
echo "Testing connection to Ollama..."
curl -s ${OLLAMA_API_URL}/api/tags > /dev/null || {
    echo "Error: Could not connect to Ollama at ${OLLAMA_API_URL}"
    exit 1
}

# Build the model
echo "Creating the model..."
curl -X POST -H "Content-Type: application/json" ${OLLAMA_API_URL}/api/create -d "{
  \"name\": \"${MODEL_NAME}\",
  \"modelfile\": \"$(cat ${MODELFILE_PATH})\"
}"

echo "Model ${MODEL_NAME} has been created successfully!"
