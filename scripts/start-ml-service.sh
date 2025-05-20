#!/bin/bash

# Script to build and start the ML service container with proper dependencies
set -e

echo "Building and starting ML service..."

# Define variables
ML_IMAGE_NAME="codexcontinue-ml"
ML_CONTAINER_NAME="codexcontinue-ml-service"
ML_PORT=5000

# Check if the container is already running
if docker ps -q --filter "name=${ML_CONTAINER_NAME}" | grep -q .; then
    echo "Stopping existing ML service container..."
    docker stop ${ML_CONTAINER_NAME} || true
    docker rm ${ML_CONTAINER_NAME} || true
fi

# Build a custom Docker image for the ML service
echo "Building custom ML service Docker image..."
cat > Dockerfile.ml-custom << EOF
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy ML service requirements and install dependencies
COPY ml/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy ML service code
COPY ml/ /app/ml/

# Set environment variables
ENV PYTHONPATH=/app
ENV OLLAMA_API_URL=http://host.docker.internal:11434

# Expose port
EXPOSE ${ML_PORT}

# Run the Flask application
CMD ["python", "ml/app.py"]
EOF

# Build the image
docker build -t ${ML_IMAGE_NAME} -f Dockerfile.ml-custom .

# Run the container
echo "Starting ML service container..."
docker run -d \
    --name ${ML_CONTAINER_NAME} \
    -p ${ML_PORT}:${ML_PORT} \
    --network codexcontinue_codexcontinue-network \
    ${ML_IMAGE_NAME}

echo "ML service is now running at http://localhost:${ML_PORT}"
echo "To check logs, run: docker logs ${ML_CONTAINER_NAME}"
