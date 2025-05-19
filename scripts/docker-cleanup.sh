#!/bin/bash
# Script to clean up Docker resources for this project

echo "=== Stopping and removing containers ==="
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml down -v

echo "=== Pruning Docker system ==="
docker system prune -f

echo "=== Docker status ==="
docker ps
docker volume ls

echo "=== Done ==="
