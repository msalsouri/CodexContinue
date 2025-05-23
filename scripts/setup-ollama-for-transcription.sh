#!/bin/bash
# Setup Ollama for transcription feature

set -e

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

OLLAMA_API_URL=${OLLAMA_API_URL:-"http://localhost:11434"}
CONFIG_FILE="${HOME}/.codexcontinue/config/transcription.env"

# Make sure the config directory exists
mkdir -p "${HOME}/.codexcontinue/config"

# Check if Ollama is running
log "Checking if Ollama is accessible at ${OLLAMA_API_URL}..."
if ! curl -s "${OLLAMA_API_URL}/api/tags" > /dev/null; then
    error "Cannot access Ollama at ${OLLAMA_API_URL}. Make sure Ollama is running."
fi

# Get available models from Ollama
log "Checking available models in Ollama..."
MODELS_JSON=$(curl -s "${OLLAMA_API_URL}/api/tags")
MODELS=$(echo "${MODELS_JSON}" | grep -o '"name":"[^"]*' | sed 's/"name":"//g' | sort)

if [ -z "${MODELS}" ]; then
    warn "No models found in Ollama."
    exit 1
else
    log "Available models:"
    echo "${MODELS}" | while read -r model; do
        echo "- ${model}"
    done
fi

# Try to find a suitable model in this order of preference
PREFERRED_MODELS=("codexcontinue" "llama3" "llama2" "mistral" "codellama")
SELECTED_MODEL=""

for model in "${PREFERRED_MODELS[@]}"; do
    if echo "${MODELS}" | grep -q "${model}"; then
        SELECTED_MODEL="${model}"
        break
    fi
done

# If no preferred model found, use the first available model
if [ -z "${SELECTED_MODEL}" ] && [ -n "${MODELS}" ]; then
    SELECTED_MODEL=$(echo "${MODELS}" | head -n 1)
fi

if [ -z "${SELECTED_MODEL}" ]; then
    error "No suitable model found in Ollama."
fi

# Create or update config file
log "Configuring transcription to use model: ${SELECTED_MODEL}"
echo "OLLAMA_MODEL=${SELECTED_MODEL}" > "${CONFIG_FILE}"
echo "OLLAMA_API_URL=${OLLAMA_API_URL}" >> "${CONFIG_FILE}"

log "Transcription configuration saved to ${CONFIG_FILE}"
log "To use this configuration, run:"
echo "  source ${CONFIG_FILE}"

# Offer to create the codexcontinue model if it's not available
if ! echo "${MODELS}" | grep -q "codexcontinue"; then
    log "Would you like to build the optimized 'codexcontinue' model? (y/n)"
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Building codexcontinue model..."
        PROJECT_DIR=$(pwd)
        MODELFILE="${PROJECT_DIR}/ml/models/ollama/Modelfile"
        
        if [ -f "${MODELFILE}" ]; then
            curl -X POST "${OLLAMA_API_URL}/api/create" \
                -H "Content-Type: application/json" \
                -d "{\"name\": \"codexcontinue\", \"modelfile\": \"$(cat ${MODELFILE})\"}"
            
            log "Model build initiated. This may take a few minutes to complete."
            echo "OLLAMA_MODEL=codexcontinue" > "${CONFIG_FILE}"
            echo "OLLAMA_API_URL=${OLLAMA_API_URL}" >> "${CONFIG_FILE}"
            log "Updated configuration to use codexcontinue model"
        else
            warn "Modelfile not found at ${MODELFILE}. Skipping model creation."
        fi
    fi
fi

log "Ollama setup for transcription completed successfully."
