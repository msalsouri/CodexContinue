#!/bin/bash
# Script to debug devcontainer startup

echo "=== Cleaning up any existing containers ==="
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml down -v

echo "=== Checking Docker Compose configuration ==="
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml config

echo "=== Starting containers in debug mode ==="
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml up --build
