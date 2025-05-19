#!/bin/bash

# Script to synchronize models and config from the original CodexContinueGPT project
# to the new containerized CodexContinue project

set -e

# Configuration
SOURCE_DIR="/Users/msalsouri/Projects/CodexContinueGPT"
TARGET_DIR="/Users/msalsouri/Projects/CodexContinue"
SCRIPT_DIR="${TARGET_DIR}/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if source and target directories exist
if [ ! -d "$SOURCE_DIR" ]; then
    error "Source directory does not exist: $SOURCE_DIR"
fi

if [ ! -d "$TARGET_DIR" ]; then
    error "Target directory does not exist: $TARGET_DIR"
fi

# Sync Modelfile for Ollama
log "Syncing Modelfile..."
if [ -f "${SOURCE_DIR}/Modelfile" ]; then
    mkdir -p "${TARGET_DIR}/ml/models/ollama"
    cp "${SOURCE_DIR}/Modelfile" "${TARGET_DIR}/ml/models/ollama/"
    log "Copied Modelfile to ${TARGET_DIR}/ml/models/ollama/"
else
    warn "Modelfile not found in source directory"
fi

# Sync ML service related files
log "Syncing ML service files..."
if [ -d "${SOURCE_DIR}/app/services" ]; then
    mkdir -p "${TARGET_DIR}/ml/app/services"
    
    # Copy ML-related service files
    for file in ml_service.py ml_ollama_router.py ml_cache.py; do
        if [ -f "${SOURCE_DIR}/app/services/${file}" ]; then
            cp "${SOURCE_DIR}/app/services/${file}" "${TARGET_DIR}/ml/app/services/"
            log "Copied ${file} to ${TARGET_DIR}/ml/app/services/"
        else
            warn "${file} not found in source directory"
        fi
    done
else
    warn "Services directory not found in source directory"
fi

# Sync relevant scripts
log "Syncing scripts..."
mkdir -p "${TARGET_DIR}/ml/scripts"

# Copy scripts related to ML and Ollama
for script in create_model_in_container.sh test_ml_module.py test_ml_ollama_router.py test_ollama_connection.py; do
    if [ -f "${SOURCE_DIR}/scripts/${script}" ]; then
        cp "${SOURCE_DIR}/scripts/${script}" "${TARGET_DIR}/ml/scripts/"
        chmod +x "${TARGET_DIR}/ml/scripts/${script}"
        log "Copied and made executable: ${script}"
    else
        warn "${script} not found in source directory"
    fi
done

# Sync config files
log "Syncing configuration files..."
if [ -d "${SOURCE_DIR}/app/config" ]; then
    mkdir -p "${TARGET_DIR}/config"
    cp -r "${SOURCE_DIR}/app/config/"* "${TARGET_DIR}/config/"
    log "Copied configuration files to ${TARGET_DIR}/config/"
else
    warn "Config directory not found in source directory"
fi

# Copy requirements.txt and extract ML-related dependencies
log "Creating ML-specific requirements..."
if [ -f "${SOURCE_DIR}/requirements.txt" ]; then
    # Create a temporary file with only ML-related dependencies
    grep -E "torch|transformers|numpy|pandas|scikit|nltk|tensorflow|keras|flask|huggingface|sentence-transformers" "${SOURCE_DIR}/requirements.txt" > "${TARGET_DIR}/ml/requirements.txt"
    log "Created ML-specific requirements.txt"
else
    warn "requirements.txt not found in source directory"
fi

# Create a script to build the model in the Ollama container
log "Creating model build script..."
cat > "${TARGET_DIR}/ml/scripts/build_codexcontinue_model.sh" << EOF
#!/bin/bash

# Script to build the CodexContinue model in the Ollama container

set -e

# Configuration
OLLAMA_API_URL=\${OLLAMA_API_URL:-http://ollama:11434}
MODEL_NAME="codexcontinue"
MODELFILE_PATH="/app/models/ollama/Modelfile"

echo "Building the CodexContinue model using Modelfile at \${MODELFILE_PATH}..."
echo "Ollama API URL: \${OLLAMA_API_URL}"

# Check if Ollama is accessible
echo "Testing connection to Ollama..."
curl -s \${OLLAMA_API_URL}/api/tags > /dev/null || {
    echo "Error: Could not connect to Ollama at \${OLLAMA_API_URL}"
    exit 1
}

# Build the model
echo "Creating the model..."
curl -X POST -H "Content-Type: application/json" \${OLLAMA_API_URL}/api/create -d "{
  \"name\": \"\${MODEL_NAME}\",
  \"modelfile\": \"\$(cat \${MODELFILE_PATH})\"
}"

echo "Model \${MODEL_NAME} has been created successfully!"
EOF

chmod +x "${TARGET_DIR}/ml/scripts/build_codexcontinue_model.sh"
log "Created and made executable: build_codexcontinue_model.sh"

log "Synchronization complete!"
log "Next steps:"
log "1. Review the synchronized files and make any necessary adjustments"
log "2. Build and run the containerized project"
