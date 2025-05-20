#!/bin/bash

# Script to initialize the CodexContinue project structure with services
# This creates a basic structure for all required services

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# Ensure the setup-service.sh script exists and is executable
if [ ! -f "${SCRIPT_DIR}/setup-service.sh" ]; then
    error "setup-service.sh script not found. Please ensure it exists in ${SCRIPT_DIR}"
fi

if [ ! -x "${SCRIPT_DIR}/setup-service.sh" ]; then
    warn "setup-service.sh is not executable. Making it executable..."
    chmod +x "${SCRIPT_DIR}/setup-service.sh"
fi

# Set up the directories
log "Creating project directories..."
mkdir -p "${PROJECT_DIR}/config"
mkdir -p "${PROJECT_DIR}/docs"
mkdir -p "${PROJECT_DIR}/docker"

# Create each service with the appropriate template
log "Setting up backend service..."
"${SCRIPT_DIR}/setup-service.sh" backend fastapi

log "Setting up frontend service..."
"${SCRIPT_DIR}/setup-service.sh" frontend basic

log "Setting up ML service..."
"${SCRIPT_DIR}/setup-service.sh" ml ml

# Create directories for ML models
mkdir -p "${PROJECT_DIR}/ml/models/ollama"
touch "${PROJECT_DIR}/ml/models/ollama/.gitkeep"
log "Created ML model directories"

# Create Modelfile for CodexContinue in Ollama
cat > "${PROJECT_DIR}/ml/models/ollama/Modelfile" << EOF
FROM llama3
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 8192

# Model metadata
SYSTEM """
You are CodexContinue, an AI assistant specialized in software development, code generation, and technical problem-solving.

Focus areas:
- Programming language expertise across Python, JavaScript, TypeScript, and other common languages
- Code generation, debugging, and optimization
- Software architecture design and best practices
- Technical documentation and explanation
- Integration with ML capabilities for enhanced reasoning

Key capabilities:
1. Generate complete, functional code solutions
2. Explain complex technical concepts clearly
3. Debug issues in existing code
4. Suggest architectural improvements
5. Integrate with local ML models for enhanced capabilities

Always provide practical, working solutions with proper error handling, and explain your reasoning when appropriate.
"""

# Template for consistent responses
TEMPLATE """
{{- if .System }}
SYSTEM: {{ .System }}
{{- end }}

{{- range .Messages }}
{{ .Role }}: {{ .Content }}
{{- end }}

A: 
"""
EOF
log "Created Modelfile for CodexContinue in Ollama"

# Create ML scripts directory and build script
mkdir -p "${PROJECT_DIR}/ml/scripts"
cat > "${PROJECT_DIR}/ml/scripts/build_codexcontinue_model.sh" << EOF
#!/bin/bash

# Script to build the CodexContinue model in the Ollama container

set -e

# Configuration
OLLAMA_API_URL=\${OLLAMA_API_URL:-http://ollama:11434}
MODEL_NAME="codexcontinue"
MODELFILE_PATH="/app/ml/models/ollama/Modelfile"

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
  \\\"name\\\": \\\"\${MODEL_NAME}\\\",
  \\\"modelfile\\\": \\\"\$(cat \${MODELFILE_PATH})\\\"
}"

echo "Model \${MODEL_NAME} has been created successfully!"
EOF
chmod +x "${PROJECT_DIR}/ml/scripts/build_codexcontinue_model.sh"
log "Created model build script"

# Create a top-level app directory for shared code
mkdir -p "${PROJECT_DIR}/app/common"
touch "${PROJECT_DIR}/app/__init__.py"
touch "${PROJECT_DIR}/app/common/__init__.py"

# Create a sample common utilities file
cat > "${PROJECT_DIR}/app/common/utils.py" << EOF
"""
Common utilities shared across services in the CodexContinue project.
"""

import json
import logging
import os
from datetime import datetime
from typing import Any, Dict, Optional

# Configure logging
def setup_logging(service_name: str, log_level: str = "INFO") -> logging.Logger:
    """Set up logging for the given service."""
    numeric_level = getattr(logging, log_level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f"Invalid log level: {log_level}")
    
    logging.basicConfig(
        level=numeric_level,
        format=f"%(asctime)s - {service_name} - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    
    return logging.getLogger(service_name)

# Environment helpers
def get_env_var(name: str, default: Any = None, required: bool = False) -> Any:
    """Get an environment variable with fallback to default."""
    value = os.environ.get(name, default)
    if required and value is None:
        raise EnvironmentError(f"Required environment variable {name} is not set")
    return value

# Common data structures
class BaseResponse:
    """Base response structure for API endpoints."""
    def __init__(
        self, 
        success: bool = True, 
        message: str = "", 
        data: Optional[Dict[str, Any]] = None, 
        error: Optional[str] = None
    ):
        self.success = success
        self.message = message
        self.data = data or {}
        self.error = error
        self.timestamp = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert response to dictionary."""
        result = {
            "success": self.success,
            "message": self.message,
            "timestamp": self.timestamp
        }
        if self.data:
            result["data"] = self.data
        if self.error:
            result["error"] = self.error
        return result
    
    def to_json(self) -> str:
        """Convert response to JSON string."""
        return json.dumps(self.to_dict())
EOF

log "Creating a sample .env file..."
cat > "${PROJECT_DIR}/.env.example" << EOF
# Environment settings (development, production, test)
ENVIRONMENT=development
LOG_LEVEL=INFO

# Backend API settings
API_PORT=8000
API_HOST=0.0.0.0

# Frontend settings
FRONTEND_PORT=8501
FRONTEND_HOST=0.0.0.0
BACKEND_URL=http://backend:8000

# ML Service settings
ML_PORT=5000
ML_HOST=0.0.0.0

# Redis settings
REDIS_URL=redis://redis:6379

# Ollama settings
OLLAMA_API_URL=http://ollama:11434

# Authentication
SECRET_KEY=changethissecretkey
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF

log "Initialization complete! Project structure has been set up at ${PROJECT_DIR}"
log "Next steps:"
log "1. Customize each service according to your requirements"
log "2. Start the development environment with docker-compose -f docker-compose.yml -f docker-compose.dev.yml up"
