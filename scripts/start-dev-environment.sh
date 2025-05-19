#!/bin/bash
# Script to build and run the development environment

echo "=== Building CodexContinue Development Environment ==="

# Clean up any existing containers to avoid conflicts
echo "Cleaning up any existing containers..."
docker compose down --remove-orphans

# Build the containers
echo "Building containers..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml build

# Start the containers
echo "Starting containers..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Show the running containers
echo
echo "=== Running Containers ==="
docker compose ps

echo
echo "=== Environment Ready ==="
echo "Frontend: http://localhost:8501"
echo "Backend API: http://localhost:8000"
echo "ML Service: http://localhost:5000"
echo "Jupyter Lab: http://localhost:8888"
echo
echo "To stop the environment, run: docker compose down"
