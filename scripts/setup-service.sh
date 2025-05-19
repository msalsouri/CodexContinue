#!/bin/bash

# Script to set up the initial directory structure for a new service in the CodexContinue project
# Usage: ./setup-service.sh <service-name> [template]

set -e

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

# Check if service name is provided
if [ -z "$1" ]; then
    error "Service name is required. Usage: ./setup-service.sh <service-name> [template]"
fi

SERVICE_NAME=$1
TEMPLATE=${2:-basic}  # Default to basic template if not specified
PROJECT_DIR="/Users/msalsouri/Projects/CodexContinue"
SERVICE_DIR="${PROJECT_DIR}/${SERVICE_NAME}"

# Check if service directory already exists
if [ -d "$SERVICE_DIR" ]; then
    warn "Service directory already exists: $SERVICE_DIR"
    read -p "Do you want to continue and potentially overwrite files? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Operation cancelled."
        exit 0
    fi
fi

# Create service directory if it doesn't exist
mkdir -p "$SERVICE_DIR"

# Create directory structure based on template
case "$TEMPLATE" in
    basic)
        log "Creating basic directory structure for $SERVICE_NAME..."
        mkdir -p "${SERVICE_DIR}/src"
        mkdir -p "${SERVICE_DIR}/tests"
        mkdir -p "${SERVICE_DIR}/config"
        mkdir -p "${SERVICE_DIR}/docs"
        
        # Create basic files
        touch "${SERVICE_DIR}/README.md"
        touch "${SERVICE_DIR}/requirements.txt"
        touch "${SERVICE_DIR}/src/__init__.py"
        touch "${SERVICE_DIR}/tests/__init__.py"
        
        # Create template README
        cat > "${SERVICE_DIR}/README.md" << EOF
# CodexContinue ${SERVICE_NAME^} Service

This is the ${SERVICE_NAME} service for the CodexContinue project.

## Overview

Briefly describe what this service does and its role in the overall architecture.

## Development

### Prerequisites

- Docker and Docker Compose
- Python 3.10+

### Local Setup

1. Build the service:
   \`\`\`
   cd ${PROJECT_DIR}
   ./scripts/docker-build.sh dev build:${SERVICE_NAME}
   \`\`\`

2. Run the service:
   \`\`\`
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up ${SERVICE_NAME}
   \`\`\`

## API Documentation

Describe the service API endpoints and usage.

## Configuration

Explain configuration options and environment variables.
EOF

        # Create sample requirements.txt
        cat > "${SERVICE_DIR}/requirements.txt" << EOF
# Core dependencies
fastapi>=0.103.2
pydantic>=2.6.4
starlette>=0.27.0
uvicorn>=0.27.1

# Utilities
python-dotenv>=1.0.1
pyyaml>=6.0.1
requests>=2.31.0

# Testing
pytest>=8.0.0
pytest-cov>=4.1.0
EOF
        ;;
        
    fastapi)
        log "Creating FastAPI directory structure for $SERVICE_NAME..."
        mkdir -p "${SERVICE_DIR}/app/api/endpoints"
        mkdir -p "${SERVICE_DIR}/app/core"
        mkdir -p "${SERVICE_DIR}/app/db"
        mkdir -p "${SERVICE_DIR}/app/models"
        mkdir -p "${SERVICE_DIR}/app/schemas"
        mkdir -p "${SERVICE_DIR}/app/services"
        mkdir -p "${SERVICE_DIR}/tests"
        mkdir -p "${SERVICE_DIR}/docs"
        
        # Create basic files
        touch "${SERVICE_DIR}/README.md"
        touch "${SERVICE_DIR}/requirements.txt"
        touch "${SERVICE_DIR}/app/__init__.py"
        touch "${SERVICE_DIR}/app/main.py"
        touch "${SERVICE_DIR}/app/api/__init__.py"
        touch "${SERVICE_DIR}/app/api/endpoints/__init__.py"
        touch "${SERVICE_DIR}/app/core/__init__.py"
        touch "${SERVICE_DIR}/app/db/__init__.py"
        touch "${SERVICE_DIR}/app/models/__init__.py"
        touch "${SERVICE_DIR}/app/schemas/__init__.py"
        touch "${SERVICE_DIR}/app/services/__init__.py"
        touch "${SERVICE_DIR}/tests/__init__.py"
        
        # Create sample main.py for FastAPI
        cat > "${SERVICE_DIR}/app/main.py" << EOF
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="CodexContinue ${SERVICE_NAME^} API",
    description="API for the ${SERVICE_NAME} service",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

@app.get("/")
async def root():
    return {"message": "Welcome to the ${SERVICE_NAME^} API"}
EOF

        # Create requirements.txt for FastAPI
        cat > "${SERVICE_DIR}/requirements.txt" << EOF
# Core dependencies
fastapi>=0.103.2
pydantic>=2.6.4
starlette>=0.27.0
uvicorn>=0.27.1

# Middleware and extensions
python-multipart>=0.0.9
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4

# Database
sqlalchemy>=2.0.27
alembic>=1.13.1
asyncpg>=0.29.0

# Utilities
python-dotenv>=1.0.1
pyyaml>=6.0.1
requests>=2.31.0
httpx>=0.27.0

# Testing
pytest>=8.0.0
pytest-cov>=4.1.0
pytest-asyncio>=0.23.5
EOF
        ;;
        
    ml)
        log "Creating ML service directory structure for $SERVICE_NAME..."
        mkdir -p "${SERVICE_DIR}/app/api"
        mkdir -p "${SERVICE_DIR}/app/core"
        mkdir -p "${SERVICE_DIR}/app/models"
        mkdir -p "${SERVICE_DIR}/app/services"
        mkdir -p "${SERVICE_DIR}/app/schemas"
        mkdir -p "${SERVICE_DIR}/tests"
        mkdir -p "${SERVICE_DIR}/notebooks"
        mkdir -p "${SERVICE_DIR}/data/raw"
        mkdir -p "${SERVICE_DIR}/data/processed"
        mkdir -p "${SERVICE_DIR}/models"
        
        # Create basic files
        touch "${SERVICE_DIR}/README.md"
        touch "${SERVICE_DIR}/requirements.txt"
        touch "${SERVICE_DIR}/requirements-jupyter.txt"
        touch "${SERVICE_DIR}/app/__init__.py"
        touch "${SERVICE_DIR}/app/main.py"
        touch "${SERVICE_DIR}/app/api/__init__.py"
        touch "${SERVICE_DIR}/app/core/__init__.py"
        touch "${SERVICE_DIR}/app/models/__init__.py"
        touch "${SERVICE_DIR}/app/services/__init__.py"
        touch "${SERVICE_DIR}/app/schemas/__init__.py"
        touch "${SERVICE_DIR}/tests/__init__.py"
        
        # Create Flask app.py for ML service
        cat > "${SERVICE_DIR}/app/main.py" << EOF
from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health')
def health_check():
    return jsonify({"status": "ok"})

@app.route('/')
def home():
    return jsonify({"message": "Welcome to the ${SERVICE_NAME^} ML Service"})

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json
        # TODO: Implement prediction logic
        result = {"prediction": "example", "confidence": 0.95}
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=os.environ.get("DEBUG", "False").lower() == "true")
EOF

        # Create requirements.txt for ML service
        cat > "${SERVICE_DIR}/requirements.txt" << EOF
# Core dependencies
flask>=3.0.2
gunicorn>=21.2.0
pydantic>=2.6.4

# ML/Data Science
numpy>=1.26.4
pandas>=2.2.1
scikit-learn>=1.4.1.post1
torch>=2.2.1
transformers>=4.38.2

# API and networking
requests>=2.31.0
httpx>=0.27.0

# Utilities
python-dotenv>=1.0.1
pyyaml>=6.0.1

# Testing
pytest>=8.0.0
pytest-cov>=4.1.0
EOF

        # Create requirements-jupyter.txt for ML service notebooks
        cat > "${SERVICE_DIR}/requirements-jupyter.txt" << EOF
# Jupyter
jupyterlab>=4.1.2
ipywidgets>=8.1.2

# Visualization
matplotlib>=3.8.3
seaborn>=0.13.2
plotly>=5.19.0

# Extended ML libraries
scikit-image>=0.22.0
pytorch-lightning>=2.2.1
optuna>=3.5.0
EOF
        ;;
        
    *)
        error "Unknown template: $TEMPLATE. Available templates: basic, fastapi, ml"
        ;;
esac

log "Successfully created $SERVICE_NAME service with $TEMPLATE template in $SERVICE_DIR"
