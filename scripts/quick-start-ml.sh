#!/bin/bash

# A simplified script to start the ML service for testing

set -e

echo "Starting ML service with basic Flask app..."

# Stop any existing containers and rebuild
cd /home/msalsouri/Projects/CodexContinue
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build ml-service

# Start ml-service and ollama
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d ollama
sleep 5  # Wait for ollama to start

# Start the ml-service container but override the command
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run -d \
  --name codexcontinue-ml-service-test \
  --service-ports \
  ml-service \
  bash -c "pip install --no-cache-dir -r /app/ml/requirements.txt && python /app/ml/app.py"

# Check status
sleep 5
curl http://localhost:5000/health || echo "Service not responding to health check"
