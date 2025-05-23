#!/bin/bash
# Comprehensive test script for YouTube transcription feature

# Detect the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Port for testing
TEST_PORT=5065

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Kill any running ML service on the test port
    pkill -f "python3.*app.py.*--port $TEST_PORT" || true
    
    echo "Done."
}

# Set up error handling and cleanup
trap cleanup EXIT

# Print header
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}YouTube Transcription Feature Test Summary${NC}"
echo -e "${GREEN}===========================================${NC}"
echo "Date: $(date)"
echo "Project root: $PROJECT_ROOT"
echo

# Check environment
echo -e "${GREEN}Checking environment...${NC}"
export PYTHONPATH="$PROJECT_ROOT"
echo "PYTHONPATH: $PYTHONPATH"

# Check if required commands exist
echo -e "${GREEN}Checking dependencies...${NC}"
commands=("python3" "ffmpeg" "curl")
all_commands_ok=true

for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "✅ $cmd: $(command -v "$cmd")"
    else
        echo -e "${RED}❌ $cmd not found${NC}"
        all_commands_ok=false
    fi
done

if [ "$all_commands_ok" = false ]; then
    echo -e "${RED}Required dependencies missing. Please install them first.${NC}"
    exit 1
fi

# Check Python packages
echo -e "\n${GREEN}Checking Python packages...${NC}"
packages=("flask" "yt_dlp" "whisper" "requests")
all_packages_ok=true

for package in "${packages[@]}"; do
    if python3 -c "import $package" &> /dev/null; then
        echo -e "✅ $package"
    else
        echo -e "${RED}❌ $package not installed${NC}"
        all_packages_ok=false
    fi
done

if [ "$all_packages_ok" = false ]; then
    echo -e "${RED}Required Python packages missing. Please install them first:${NC}"
    echo "pip install yt_dlp openai-whisper flask requests"
    exit 1
fi

# Run component test
echo -e "\n${GREEN}Running direct component test...${NC}"
python3 "$SCRIPT_DIR/test-transcriber-component.py"
component_result=$?

if [ $component_result -eq 0 ]; then
    echo -e "${GREEN}✅ Component test passed${NC}"
else
    echo -e "${RED}❌ Component test failed${NC}"
fi

# Start the ML service for API testing
echo -e "\n${GREEN}Starting ML service for API testing on port $TEST_PORT...${NC}"
python3 "$PROJECT_ROOT/ml/app.py" --port "$TEST_PORT" > /tmp/ml-service-test.log 2>&1 &
ML_SERVICE_PID=$!

# Wait for the service to start
echo "Waiting for ML service to start..."
sleep 5

# Check if the service is running
if kill -0 $ML_SERVICE_PID 2>/dev/null; then
    echo -e "${GREEN}✅ ML service started successfully${NC}"
else
    echo -e "${RED}❌ ML service failed to start${NC}"
    echo "Log:"
    cat /tmp/ml-service-test.log
    exit 1
fi

# Test the API
echo -e "\n${GREEN}Testing API endpoint...${NC}"
python3 "$SCRIPT_DIR/simple-api-test.py"
api_result=$?

if [ $api_result -eq 0 ]; then
    echo -e "${GREEN}✅ API test passed${NC}"
else
    echo -e "${RED}❌ API test failed${NC}"
    # Show the log if the test failed
    echo "ML service log:"
    cat /tmp/ml-service-test.log
fi

# Test Ollama integration
echo -e "\n${GREEN}Testing Ollama integration...${NC}"
if python3 -c "import requests; requests.get('http://localhost:11434/api/tags', timeout=2)" &> /dev/null; then
    echo "Ollama service is running, testing summarization..."
    python3 "$SCRIPT_DIR/test-ollama-integration.py"
    ollama_result=$?
    
    if [ $ollama_result -eq 0 ]; then
        echo -e "${GREEN}✅ Ollama integration test passed${NC}"
    else
        echo -e "${YELLOW}⚠️ Ollama integration test had issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Ollama service not running, skipping summarization tests${NC}"
    ollama_result=0  # Don't fail the entire test if Ollama is not available
fi

# Stop the ML service
echo -e "\n${GREEN}Stopping ML service...${NC}"
kill $ML_SERVICE_PID || true
sleep 2

# Print summary
echo -e "\n${GREEN}===================${NC}"
echo -e "${GREEN}Test Summary Results${NC}"
echo -e "${GREEN}===================${NC}"
echo -e "Component test: $([ $component_result -eq 0 ] && echo -e "${GREEN}✅ PASSED${NC}" || echo -e "${RED}❌ FAILED${NC}")"
echo -e "API test: $([ $api_result -eq 0 ] && echo -e "${GREEN}✅ PASSED${NC}" || echo -e "${RED}❌ FAILED${NC}")"
echo -e "Ollama integration: $([ $ollama_result -eq 0 ] && echo -e "${GREEN}✅ PASSED${NC}" || echo -e "${YELLOW}⚠️ ISSUES${NC}")"

# Overall result
if [ $component_result -eq 0 ] && [ $api_result -eq 0 ]; then
    echo -e "\n${GREEN}✅ Overall: PASSED${NC}"
    echo -e "YouTube transcription feature is working correctly."
    exit 0
else
    echo -e "\n${RED}❌ Overall: FAILED${NC}"
    echo -e "Some tests failed. Please check the output above for details."
    exit 1
fi
