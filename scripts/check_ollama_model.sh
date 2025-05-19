#!/bin/bash
# check_ollama_model.sh - Check if the CodexContinue model is properly built in Ollama

set -e

# Get project directory dynamically (works across platforms)
PROJECT_DIR=$(pwd)
OLLAMA_URL=${1:-"http://localhost:11434"}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if Ollama is running
log "Checking if Ollama is accessible at ${OLLAMA_URL}..."
if ! curl -s "${OLLAMA_URL}/api/tags" > /dev/null; then
    error "Cannot access Ollama at ${OLLAMA_URL}. Make sure Ollama is running."
fi

# Check for available models
log "Checking available models in Ollama..."
MODELS_JSON=$(curl -s "${OLLAMA_URL}/api/tags")
MODELS=$(echo "${MODELS_JSON}" | grep -o '"name":"[^"]*' | sed 's/"name":"//g' | sort)

if [ -z "${MODELS}" ]; then
    warn "No models found in Ollama."
else
    log "Available models:"
    echo "${MODELS}" | while read -r model; do
        echo "- ${model}"
    done
fi

# Check specifically for CodexContinue model
if echo "${MODELS}" | grep -q "codexcontinue"; then
    log "CodexContinue model is available."
    
    # Get model details
    MODEL_INFO=$(curl -s "${OLLAMA_URL}/api/show" -d '{"name":"codexcontinue"}')
    MODEL_SIZE=$(echo "${MODEL_INFO}" | grep -o '"size":[0-9]*' | sed 's/"size"://g')
    MODEL_SIZE_MB=$((MODEL_SIZE / 1024 / 1024))
    
    log "Model size: ${MODEL_SIZE_MB} MB"
    log "CodexContinue model is properly set up."
else
    warn "CodexContinue model is not available. Would you like to build it now? (y/n)"
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Building CodexContinue model..."
        
        # Check if Modelfile exists
        MODELFILE="${PROJECT_DIR}/ml/models/ollama/Modelfile"
        if [ ! -f "${MODELFILE}" ]; then
            error "Modelfile not found at ${MODELFILE}. Please run the initialization script first."
        fi
        
        # Build the model manually
        log "Creating model from Modelfile..."
        curl -X POST "${OLLAMA_URL}/api/create" \
            -H "Content-Type: application/json" \
            -d "{\"name\": \"codexcontinue\", \"modelfile\": \"$(cat ${MODELFILE})\"}"
            
        log "Model build initiated. This may take a few minutes to complete."
        log "Check the status with: curl ${OLLAMA_URL}/api/tags"
    else
        log "Skipped model building."
    fi
fi

# Test the model with a simple question if available
if echo "${MODELS}" | grep -q "codexcontinue"; then
    log "Testing the CodexContinue model with a simple question..."
    RESPONSE=$(curl -s "${OLLAMA_URL}/api/generate" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "codexcontinue",
            "prompt": "Write a simple hello world function in Python."
        }')
    
    GENERATED_TEXT=$(echo "${RESPONSE}" | grep -o '"response":"[^"]*' | sed 's/"response":"//g')
    
    if [ -n "${GENERATED_TEXT}" ]; then
        log "Model is responding properly."
        log "Sample response: ${GENERATED_TEXT:0:100}..."
    else
        warn "Model did not generate a proper response. There might be an issue with the model."
    fi
fi

log "Ollama model check completed."
