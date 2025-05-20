#!/bin/bash
# test-codexcontinue-ports.sh - Test all CodexContinue service ports

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Make sure we're in the project root
cd "$(dirname "$0")/.."

echo "==============================================="
echo "CodexContinue Service Port Test"
echo "==============================================="
echo "This script tests all service ports used by CodexContinue"
echo

# Define the services and their ports
declare -A services=(
    ["Ollama API"]=11434
    ["Backend API"]=8000
    ["Streamlit Frontend"]=8501
    ["ML Service"]=5000
)

# Function to check if a port is in use
check_port_in_use() {
    local port=$1
    local service_name=$2
    
    # Use curl to check if the service is responding, which is more reliable than lsof in Docker
    if curl -s --head --max-time 2 http://localhost:$port >/dev/null; then
        log "Port $port ($service_name) is in use and responding"
        return 0 # true, port is in use
    else
        warn "Port $port ($service_name) is not responding - service may not be running"
        return 1 # false, port is not in use
    fi
}

# Function to check if a service is responding
check_service_responding() {
    local port=$1
    local service_name=$2
    local endpoint=$3
    
    # Create URL from port and endpoint
    local url="http://localhost:${port}${endpoint}"
    
    echo -n "  Testing $service_name at $url: "
    
    # Try to connect to the service
    if curl -s --head --request GET "$url" -m 2 | grep -q "HTTP/";
    then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}Failed${NC}"
        return 1
    fi
}

# Check all port usage first
section "Checking Port Usage"
for service in "${!services[@]}"; do
    port=${services[$service]}
    check_port_in_use "$port" "$service"
done

# Now check service responses
section "Testing Service Responses"

# Ollama API
if check_port_in_use "${services['Ollama API']}" "Ollama API"; then
    check_service_responding "${services['Ollama API']}" "Ollama API" "/api/tags"
    
    # Try a quick model query if available
    echo "  Testing Ollama model response..."
    if curl -s -X POST http://localhost:11434/api/generate -d '{"model":"llama3","prompt":"hello","stream":false}' | grep -q 'response'; then
        log "Ollama model response: OK"
    else
        warn "Ollama model response failed - models may not be loaded"
    fi
fi

# Backend API
if check_port_in_use "${services['Backend API']}" "Backend API"; then
    check_service_responding "${services['Backend API']}" "Backend API" "/docs"
fi

# Streamlit Frontend
if check_port_in_use "${services['Streamlit Frontend']}" "Streamlit Frontend"; then
    check_service_responding "${services['Streamlit Frontend']}" "Streamlit Frontend" "/"
fi

# ML Service
if check_port_in_use "${services['ML Service']}" "ML Service"; then
    check_service_responding "${services['ML Service']}" "ML Service" "/health"
fi

# Final summary and tips
section "Summary and Tips"
echo "If any services are not running, try the following:"
echo
echo "1. To start all CodexContinue services:"
echo "   ./scripts/start-codexcontinue.sh"
echo
echo "2. To manage Ollama separately:"
echo "   ./scripts/manage-ollama-process.sh stop    # Stop Ollama"
echo "   ./scripts/manage-ollama-process.sh start   # Start Ollama"
echo "   ./scripts/manage-ollama-process.sh status  # Check Ollama status"
echo
echo "3. For port conflicts, check what processes are using the ports:"
echo "   sudo lsof -i :PORT_NUMBER  # Replace PORT_NUMBER with the port"
echo
echo "4. Modify ports in docker-compose.yml if needed (change first number):"
echo "   ports:"
echo "     - \"NEW_PORT:ORIGINAL_PORT\""
echo
echo "For more information, see docs/troubleshooting/"
