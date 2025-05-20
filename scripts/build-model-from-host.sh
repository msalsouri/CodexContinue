#!/bin/bash

# Script to build the CodexContinue model directly from the host system
# For use when there are issues with the ml-service container

set -e

# Configuration
OLLAMA_API_URL=${OLLAMA_API_URL:-http://localhost:11434}
MODEL_NAME="codexcontinue"
MODELFILE_PATH="ml/models/ollama/Modelfile"

echo "Building the CodexContinue model from host system..."
echo "Using Modelfile at ${MODELFILE_PATH}"
echo "Ollama API URL: ${OLLAMA_API_URL}"

# Check if Ollama is accessible
echo "Testing connection to Ollama..."
curl -s ${OLLAMA_API_URL}/api/tags || {
    echo "Error: Could not connect to Ollama at ${OLLAMA_API_URL}"
    exit 1
}

# Build the model
echo "Creating the model..."
curl -X POST -H "Content-Type: application/json" ${OLLAMA_API_URL}/api/create -d "{
  \"name\": \"${MODEL_NAME}\",
  \"modelfile\": \"$(cat ${MODELFILE_PATH})\"
}"

echo
echo "Model build initiated. This may take several minutes to complete."
echo "You can check the status with: curl ${OLLAMA_API_URL}/api/tags"
