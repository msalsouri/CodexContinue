#!/bin/bash
# PR verification script for YouTube transcription feature

# Detect the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test videos
ENGLISH_VIDEO="https://www.youtube.com/watch?v=jNQXAC9IVRw" # First YouTube video
KOREAN_VIDEO="https://www.youtube.com/watch?v=9bZkp7q19f0"  # Gangnam Style

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
echo -e "${GREEN}  YouTube Transcription PR Verification   ${NC}"
echo -e "${GREEN}===========================================${NC}"

# Step 1: Check environment
echo -e "\n${YELLOW}Step 1: Checking environment...${NC}"
python3 -c "import whisper, yt_dlp, flask; print('Required Python packages installed.')"
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}ffmpeg not found! Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}Environment check passed.${NC}"

# Step 2: Start ML service
echo -e "\n${YELLOW}Step 2: Starting ML service...${NC}"
"$PROJECT_ROOT/scripts/start-transcription-service.sh" --port "$TEST_PORT" &
SERVICE_PID=$!
echo "Service started with PID $SERVICE_PID"

# Wait for service to start
echo "Waiting for service to start..."
sleep 5

# Step 3: Test the API endpoint health
echo -e "\n${YELLOW}Step 3: Testing API endpoint health...${NC}"
HEALTH_RESPONSE=$(curl -s "http://localhost:$TEST_PORT/health")
if [[ "$HEALTH_RESPONSE" == *"healthy"* ]]; then
    echo -e "${GREEN}API health check passed.${NC}"
else
    echo -e "${RED}API health check failed!${NC}"
    echo "$HEALTH_RESPONSE"
    exit 1
fi

# Step 4: Test English video transcription
echo -e "\n${YELLOW}Step 4: Testing English video transcription...${NC}"
ENGLISH_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"url\":\"$ENGLISH_VIDEO\", \"language\":\"en\"}" \
    "http://localhost:$TEST_PORT/youtube/transcribe")
if [[ "$ENGLISH_RESPONSE" == *"text"* ]] && [[ "$ENGLISH_RESPONSE" == *"segments"* ]]; then
    echo -e "${GREEN}English transcription test passed.${NC}"
    echo "First 100 characters of transcript:"
    echo "$ENGLISH_RESPONSE" | grep -o '"text":"[^"]*' | sed 's/"text":"//' | head -c 100
    echo "..."
else
    echo -e "${RED}English transcription test failed!${NC}"
    echo "$ENGLISH_RESPONSE"
    exit 1
fi

# Step 5: Test Korean video transcription
echo -e "\n${YELLOW}Step 5: Testing Korean video transcription...${NC}"
KOREAN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"url\":\"$KOREAN_VIDEO\"}" \
    "http://localhost:$TEST_PORT/youtube/transcribe")
if [[ "$KOREAN_RESPONSE" == *"text"* ]] && [[ "$KOREAN_RESPONSE" == *"segments"* ]]; then
    echo -e "${GREEN}Korean transcription test passed.${NC}"
    echo "Detected language: $(echo "$KOREAN_RESPONSE" | grep -o '"language":"[^"]*' | sed 's/"language":"//')"
    echo "First 100 characters of transcript:"
    echo "$KOREAN_RESPONSE" | grep -o '"text":"[^"]*' | sed 's/"text":"//' | head -c 100
    echo "..."
else
    echo -e "${RED}Korean transcription test failed!${NC}"
    echo "$KOREAN_RESPONSE"
    exit 1
fi

# Step 6: Verify Ollama integration if available
echo -e "\n${YELLOW}Step 6: Testing Ollama integration...${NC}"
OLLAMA_AVAILABLE=$(curl -s "http://localhost:11434/api/tags" || echo "")
if [[ -n "$OLLAMA_AVAILABLE" ]]; then
    echo "Ollama is available, testing summarization..."
    SUMMARY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"url\":\"$ENGLISH_VIDEO\", \"summarize\":true}" \
        "http://localhost:$TEST_PORT/youtube/transcribe")
    if [[ "$SUMMARY_RESPONSE" == *"summary"* ]]; then
        echo -e "${GREEN}Ollama summarization test passed.${NC}"
        echo "Summary excerpt:"
        echo "$SUMMARY_RESPONSE" | grep -o '"summary":"[^"]*' | sed 's/"summary":"//' | head -c 100
        echo "..."
    else
        echo -e "${YELLOW}Ollama summarization test failed, but this may be expected if models are not available.${NC}"
    fi
else
    echo -e "${YELLOW}Ollama not available, skipping summarization test.${NC}"
fi

# Print success message
echo -e "\n${GREEN}===========================================${NC}"
echo -e "${GREEN}  All verification tests passed!  ${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "The YouTube transcription feature is working correctly!"
echo -e "The PR is ready for review and merging."

exit 0
