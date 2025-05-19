#!/bin/bash
# This script helps diagnose and resolve devcontainer setup issues

echo "=== CodexContinue DevContainer Setup Diagnostic Tool ==="
echo

# Check Docker is running
echo "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker and try again."
  exit 1
else
  echo "✅ Docker is running"
fi

# Check Docker Compose version
echo "Checking Docker Compose..."
if docker compose version > /dev/null 2>&1; then
  echo "✅ Docker Compose is installed"
else
  echo "❌ Docker Compose not found or not working properly"
  exit 1
fi

# Check for required files
echo "Checking for required configuration files..."
required_files=(
  ".devcontainer/devcontainer.json"
  ".devcontainer/docker-compose.devcontainer.yml"
  "docker-compose.yml"
  "docker-compose.dev.yml"
  "docker/frontend/Dockerfile"
  "docker/backend/Dockerfile"
  "docker/ml/Dockerfile"
  "docker/ml/Dockerfile.jupyter"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file is missing"
  fi
done

# Check if requirements files exist
echo "Checking for requirements files..."
requirements_files=(
  "frontend/requirements.txt"
  "backend/requirements.txt"
  "ml/requirements.txt"
  "ml/requirements-jupyter.txt"
)

for file in "${requirements_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file is missing"
    echo "   Creating empty $file file..."
    mkdir -p "$(dirname "$file")"
    touch "$file"
  fi
done

# Validate docker-compose files
echo "Validating docker-compose configuration..."
if docker compose config > /dev/null 2>&1; then
  echo "✅ docker-compose configuration is valid"
else
  echo "❌ docker-compose configuration has errors"
  echo "Running docker compose config to show errors:"
  docker compose config
fi

# Check Docker build process
echo "Attempting to build containers..."
docker compose build

echo
echo "=== Diagnostic Summary ==="
echo "If all checks passed, try using VS Code's 'Reopen in Container' option."
echo "If issues persist, check the error messages above and fix any identified problems."
echo "You may also want to run 'docker system prune' to clean up any stale resources."
