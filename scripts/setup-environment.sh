#!/bin/bash
# Comprehensive cleanup and setup script for CodexContinue

# Set color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== CodexContinue Environment Setup ===${NC}"

# Check Docker
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker is installed.${NC}"

# Check Docker Compose
echo -e "${YELLOW}Checking Docker Compose installation...${NC}"
if ! command -v docker-compose >/dev/null 2>&1; then
  echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker Compose is installed.${NC}"

# Create directories if they don't exist
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p frontend/app
mkdir -p backend/app
mkdir -p ml/app
mkdir -p notebooks
echo -e "${GREEN}Directories created.${NC}"

# Create minimal app files if they don't exist
if [ ! -f frontend/app.py ]; then
  echo -e "${YELLOW}Creating minimal frontend app...${NC}"
  cat > frontend/app.py << 'EOF'
import streamlit as st

st.set_page_config(
    page_title="CodexContinue",
    page_icon="🧠",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.title("CodexContinue")
st.header("Welcome to the CodexContinue development environment!")

st.markdown("""
This is a placeholder frontend application. 
Replace this with your actual Streamlit application code.
""")

if __name__ == "__main__":
    pass
EOF
  echo -e "${GREEN}Created frontend app.${NC}"
fi

if [ ! -f backend/app/main.py ]; then
  echo -e "${YELLOW}Creating minimal backend app...${NC}"
  mkdir -p backend/app
  cat > backend/app/main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI(
    title="CodexContinue API",
    description="API for CodexContinue",
    version="0.1.0"
)

@app.get("/")
async def root():
    return {"message": "Welcome to CodexContinue API"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF
  echo -e "${GREEN}Created backend app.${NC}"
fi

if [ ! -f ml/app.py ]; then
  echo -e "${YELLOW}Creating minimal ML service app...${NC}"
  cat > ml/app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Welcome to CodexContinue ML Service"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF
  echo -e "${GREEN}Created ML service app.${NC}"
fi

# Create/update .gitignore
if [ ! -f .gitignore ]; then
  echo -e "${YELLOW}Creating .gitignore file...${NC}"
  cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# Jupyter Notebooks
.ipynb_checkpoints
*/.ipynb_checkpoints/*

# Docker
.docker-volumes/

# Local development
.DS_Store
.idea/
*.swp
*.swo
EOF
  echo -e "${GREEN}Created .gitignore file.${NC}"
fi

echo -e "${BLUE}=== Setup Complete ===${NC}"
echo -e "${GREEN}You can now start the development environment with:${NC}"
echo -e "${YELLOW}   VS Code > Reopen in Container${NC}"
echo -e "${GREEN}or run:${NC}"
echo -e "${YELLOW}   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up${NC}"
