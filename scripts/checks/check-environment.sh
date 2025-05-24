#!/bin/bash
# Script to verify that the dev environment is working correctly

echo "=== CodexContinue Environment Check ==="

# Set color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if containers are running
echo -e "\n${YELLOW}Checking running containers...${NC}"
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep codexcontinue)

if [ -z "$RUNNING_CONTAINERS" ]; then
  echo -e "${RED}No CodexContinue containers are running.${NC}"
  echo -e "Run ./scripts/start-dev-environment.sh to start the environment."
  exit 1
else
  echo -e "${GREEN}Found running containers:${NC}"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep codexcontinue
fi

# Check network connectivity between services
echo -e "\n${YELLOW}Checking network connectivity...${NC}"

# Get a container to test from
TEST_CONTAINER=$(docker ps --format "{{.Names}}" | grep codexcontinue | grep frontend | head -1)

if [ -z "$TEST_CONTAINER" ]; then
  TEST_CONTAINER=$(docker ps --format "{{.Names}}" | grep codexcontinue | head -1)
fi

if [ -n "$TEST_CONTAINER" ]; then
  echo "Testing from container: $TEST_CONTAINER"
  
  # Check connections to other services
  SERVICES=("backend" "ml-service" "redis" "ollama")
  
  for SERVICE in "${SERVICES[@]}"; do
    echo -n "Testing connection to $SERVICE: "
    if docker exec $TEST_CONTAINER ping -c 1 $SERVICE &>/dev/null; then
      echo -e "${GREEN}OK${NC}"
    else
      echo -e "${RED}FAILED${NC}"
    fi
  done
fi

# Check service endpoints
echo -e "\n${YELLOW}Checking service endpoints...${NC}"

check_endpoint() {
  local url=$1
  local name=$2
  echo -n "Testing $name endpoint ($url): "
  
  if curl -s --head --request GET $url | grep "200\|401\|302" > /dev/null; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}FAILED${NC}"
  fi
}

# Check the main service endpoints
check_endpoint "http://localhost:8501" "Frontend"
check_endpoint "http://localhost:8000" "Backend"
check_endpoint "http://localhost:5000" "ML Service"
check_endpoint "http://localhost:8888" "Jupyter"

# Check file mounting
echo -e "\n${YELLOW}Checking file mounting...${NC}"

if [ -n "$TEST_CONTAINER" ]; then
  echo -n "Checking if source code is properly mounted: "
  if docker exec $TEST_CONTAINER ls -la /app/frontend /app/backend /app/ml &>/dev/null; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}FAILED${NC}"
    echo "Checking mount details:"
    docker exec $TEST_CONTAINER ls -la /app
  fi
fi

echo -e "\n${YELLOW}Environment check complete${NC}"
