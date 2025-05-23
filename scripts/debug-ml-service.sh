#!/bin/bash

# A simplified script to start the ML service for debugging purposes

echo "Starting a debugging session for the ML service..."

# Move to the project directory
cd "$(dirname "$0")/.."

# Stop any existing containers
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

# Start the ollama service
echo "Starting the ollama service..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d ollama
echo "Waiting for ollama to start..."
sleep 5

# Build and start the ML service
echo "Building and starting the ML service..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build ml-service

# Wait a moment for the container to start
echo "Waiting for the ML service to initialize..."
sleep 5

# Print container status
echo "Container status:"
docker ps

# Print logs from the ML service
echo "ML service logs:"
docker logs codexcontinue-ml-service-1

# Try to access the health endpoint
echo "Attempting to access the health endpoint..."
curl -v http://localhost:5000/health

echo "Debug session complete. Check the logs above for issues."
