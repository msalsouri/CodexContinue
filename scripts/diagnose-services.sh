#!/bin/bash
# CodexContinue Services Connectivity Diagnostic Tool
# Usage: ./diagnose-services.sh

# Terminal colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== CodexContinue Services Connectivity Diagnostic Tool ===${NC}"
echo -e "This script will check connectivity between all services in the CodexContinue application."
echo ""

# Check if Docker is running
echo -e "${BLUE}Checking if Docker is running...${NC}"
if ! docker info &>/dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
else
    echo -e "${GREEN}Docker is running.${NC}"
fi

# Check if Docker Compose project is running
echo -e "\n${BLUE}Checking CodexContinue containers...${NC}"
CONTAINERS=$(docker compose ps --services 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error running docker compose. Are you in the CodexContinue project directory?${NC}"
    exit 1
fi

# Check each required service
REQUIRED_SERVICES=("frontend" "backend" "ml-service" "ollama" "redis")
MISSING_SERVICES=()

for service in "${REQUIRED_SERVICES[@]}"; do
    if echo "$CONTAINERS" | grep -q "$service"; then
        CONTAINER_ID=$(docker compose ps -q $service)
        CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)
        
        if [ "$CONTAINER_STATUS" == "running" ]; then
            echo -e "${GREEN}✓ $service is running (Container ID: $CONTAINER_ID)${NC}"
        else
            echo -e "${RED}✗ $service is not running (Status: $CONTAINER_STATUS)${NC}"
            MISSING_SERVICES+=("$service")
        fi
    else
        echo -e "${RED}✗ $service is not found in the running services${NC}"
        MISSING_SERVICES+=("$service")
    fi
done

if [ ${#MISSING_SERVICES[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Some required services are missing or not running. Please start them:${NC}"
    echo -e "${YELLOW}docker compose up -d ${MISSING_SERVICES[*]}${NC}"
    echo ""
fi

# Check for environment variables in the frontend container
echo -e "\n${BLUE}Checking environment variables in frontend container...${NC}"
if echo "$CONTAINERS" | grep -q "frontend"; then
    FRONTEND_CONTAINER_ID=$(docker compose ps -q frontend)
    
    echo -e "${YELLOW}Checking OLLAMA_API_URL...${NC}"
    OLLAMA_API_URL=$(docker exec $FRONTEND_CONTAINER_ID env | grep OLLAMA_API_URL || echo "Not set")
    echo "$OLLAMA_API_URL"
    
    echo -e "${YELLOW}Checking ML_SERVICE_URL...${NC}"
    ML_SERVICE_URL=$(docker exec $FRONTEND_CONTAINER_ID env | grep ML_SERVICE_URL || echo "Not set")
    echo "$ML_SERVICE_URL"
    
    if [[ "$OLLAMA_API_URL" == "Not set" || "$ML_SERVICE_URL" == "Not set" ]]; then
        echo -e "\n${RED}Missing required environment variables in frontend container.${NC}"
        echo -e "${YELLOW}Please ensure these are set in docker-compose.yml or docker-compose.override.yml:${NC}"
        echo -e "- OLLAMA_API_URL=http://ollama:11434"
        echo -e "- ML_SERVICE_URL=http://ml-service:5000"
    fi
fi

# Test ML service health endpoint
echo -e "\n${BLUE}Testing ML service health endpoint...${NC}"
ML_HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null)
if [ "$ML_HEALTH_STATUS" == "200" ]; then
    echo -e "${GREEN}✓ ML service health endpoint is responding (HTTP 200)${NC}"
else
    echo -e "${RED}✗ ML service health endpoint is not responding (HTTP $ML_HEALTH_STATUS)${NC}"
    echo -e "${YELLOW}Try: curl http://localhost:5000/health${NC}"
fi

# Test Ollama API
echo -e "\n${BLUE}Testing Ollama API...${NC}"
OLLAMA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags 2>/dev/null)
if [ "$OLLAMA_STATUS" == "200" ]; then
    echo -e "${GREEN}✓ Ollama API is responding (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Ollama API is not responding (HTTP $OLLAMA_STATUS)${NC}"
    echo -e "${YELLOW}Try: curl http://localhost:11434/api/tags${NC}"
fi

# Test connectivity between containers
echo -e "\n${BLUE}Testing inter-container connectivity...${NC}"

if echo "$CONTAINERS" | grep -q "ml-service"; then
    echo -e "\n${YELLOW}Testing ML service -> Ollama connectivity:${NC}"
    ML_TO_OLLAMA=$(docker exec $(docker compose ps -q ml-service) curl -s -o /dev/null -w "%{http_code}" http://ollama:11434/api/tags 2>/dev/null)
    if [ "$ML_TO_OLLAMA" == "200" ]; then
        echo -e "${GREEN}✓ ML service can connect to Ollama${NC}"
    else
        echo -e "${RED}✗ ML service cannot connect to Ollama (HTTP $ML_TO_OLLAMA)${NC}"
    fi
fi

if echo "$CONTAINERS" | grep -q "frontend"; then
    echo -e "\n${YELLOW}Testing Frontend -> ML service connectivity:${NC}"
    FRONTEND_TO_ML=$(docker exec $(docker compose ps -q frontend) curl -s -o /dev/null -w "%{http_code}" http://ml-service:5000/health 2>/dev/null)
    if [ "$FRONTEND_TO_ML" == "200" ]; then
        echo -e "${GREEN}✓ Frontend can connect to ML service${NC}"
    else
        echo -e "${RED}✗ Frontend cannot connect to ML service (HTTP $FRONTEND_TO_ML)${NC}"
    fi
fi

echo -e "\n${BLUE}=== Diagnostics Complete ===${NC}"

if [ ${#MISSING_SERVICES[@]} -gt 0 ] || [ "$ML_HEALTH_STATUS" != "200" ] || [ "$OLLAMA_STATUS" != "200" ]; then
    echo -e "${RED}Issues were detected. Please refer to the troubleshooting guide in /docs/troubleshooting-guide.md${NC}"
else
    echo -e "${GREEN}All services appear to be running and connected properly.${NC}"
fi
