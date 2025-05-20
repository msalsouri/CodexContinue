#!/bin/bash

# Script to initialize and start CodexContinue containers
# This ensures the Ollama model is properly created on startup

set -e

# Configuration
# Get the current script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

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

# Step 1: Check if the project has been initialized
if [ ! -d "$PROJECT_DIR/ml/models/ollama" ]; then
    log "Creating ML model directories..."
    mkdir -p "$PROJECT_DIR/ml/models/ollama"
fi

# Step 2: Ensure we have the Modelfile
if [ ! -f "$PROJECT_DIR/ml/models/ollama/Modelfile" ]; then
    if [ -f "$PROJECT_DIR/scripts/init-project.sh" ]; then
        log "Running project initialization to create Modelfile..."
        bash "$PROJECT_DIR/scripts/init-project.sh" || error "Failed to initialize project structure"
    elif [ -f "$PROJECT_DIR/scripts/sync-from-original.sh" ]; then
        log "Syncing files from original project..."
        bash "$PROJECT_DIR/scripts/sync-from-original.sh" || error "Failed to sync from original project"
    else
        error "Cannot find Modelfile or initialization scripts"
    fi
else
    log "Model files already exist"
fi

# Step 3: Build and start the containers
log "Building and starting containers..."
./scripts/docker-build.sh dev build || error "Failed to build containers"

# Step 4: Start the containers
log "Starting containers in development mode..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d || error "Failed to start containers"

# Step 5: Wait for Ollama to be ready
log "Waiting for Ollama service to be ready..."
attempts=0
max_attempts=30
until curl -s http://localhost:11434/api/tags > /dev/null; do
    attempts=$((attempts+1))
    if [ $attempts -ge $max_attempts ]; then
        error "Ollama service did not become ready in time"
    fi
    echo "Waiting for Ollama service... (attempt $attempts/$max_attempts)"
    sleep 2
done
log "Ollama service is ready!"

# Step 6: Build the CodexContinue model
log "Building the CodexContinue model..."
CONTAINER_ID=$(docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps -q ml-service)
if [ -z "$CONTAINER_ID" ]; then
    error "ML service container not found"
fi

# Ensure the build script exists
if [ ! -f "$PROJECT_DIR/ml/scripts/build_codexcontinue_model.sh" ]; then
    log "Creating model build script..."
    mkdir -p "$PROJECT_DIR/ml/scripts"
    cat > "$PROJECT_DIR/ml/scripts/build_codexcontinue_model.sh" << 'EOF'
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
EOF
    chmod +x "$PROJECT_DIR/ml/scripts/build_codexcontinue_model.sh"
fi

# Execute the model building script inside the ML service container
docker exec "$CONTAINER_ID" bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh" || warn "Failed to build model, but continuing"

# Step 7: Check the status of all services
log "Checking status of all services..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

log "CodexContinue has been initialized and started successfully!"
log "Frontend UI: http://localhost:8501"
log "Backend API: http://localhost:8000"
log "ML Service: http://localhost:5000"
log "Ollama API: http://localhost:11434"
