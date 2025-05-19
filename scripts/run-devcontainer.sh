#!/bin/bash
# Script to run the devcontainer directly from the command line

# Set color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Running CodexContinue in Dev Container ===${NC}"

# Check Docker
echo -e "${YELLOW}Checking Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}Docker is not running or not accessible. Please start Docker and try again.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker is running.${NC}"

# Clean up existing containers
echo -e "${YELLOW}Cleaning up existing containers...${NC}"
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml down --remove-orphans

# Start the containers
echo -e "${YELLOW}Starting containers...${NC}"
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml up -d

# Check if containers are running
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Containers started successfully.${NC}"
  echo -e "${YELLOW}Services:${NC}"
  echo -e "  - Frontend: http://localhost:8501"
  echo -e "  - Backend: http://localhost:8000"
  echo -e "  - ML Service: http://localhost:5000"
  echo -e "  - Jupyter: http://localhost:8888"
  echo -e "  - Redis: localhost:6379"
  echo -e "  - Ollama: http://localhost:11434"
  echo -e "${YELLOW}To stop containers, press Ctrl+C or run:${NC}"
  echo -e "  docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml down"
else
  echo -e "${RED}Failed to start containers.${NC}"
  exit 1
fi

# Keep the script running to show logs
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f .devcontainer/docker-compose.devcontainer.yml logs -f
