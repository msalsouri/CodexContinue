#!/bin/bash
# Run the YouTube transcriber test with the right environment settings

set -e  # Exit immediately if a command exits with a non-zero status

# Set up environment variables
export PYTHONPATH=/home/msalsouri/Projects/CodexContinue
export PATH=/usr/bin:$PATH
export FFMPEG_LOCATION=/usr/bin

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing YouTube Transcription Feature${NC}"

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"
MISSING_DEPS=()

# Check for yt-dlp
if ! pip show yt-dlp &>/dev/null; then
    MISSING_DEPS+=("yt-dlp")
fi

# Check for whisper
if ! pip show openai-whisper &>/dev/null; then
    MISSING_DEPS+=("openai-whisper")
fi

# Check for ffmpeg
if ! which ffmpeg &>/dev/null; then
    MISSING_DEPS+=("ffmpeg")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Installing missing dependencies...${NC}"
    pip install ${MISSING_DEPS[*]}
fi

# Configure Ollama model - check for available models and set an appropriate one
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo -e "${GREEN}Ollama service is running${NC}"
    echo -e "${YELLOW}Checking available Ollama models...${NC}"
    MODELS_JSON=$(curl -s http://localhost:11434/api/tags)
    MODELS=$(echo "${MODELS_JSON}" | grep -o '"name":"[^"]*' | sed 's/"name":"//g')
    
    if [ -n "${MODELS}" ]; then
        # Try to find a suitable model
        if echo "${MODELS}" | grep -q "codexcontinue"; then
            export OLLAMA_MODEL="codexcontinue"
        elif echo "${MODELS}" | grep -q "llama3"; then
            export OLLAMA_MODEL="llama3"
        elif echo "${MODELS}" | grep -q "mistral"; then
            export OLLAMA_MODEL="mistral"
        elif echo "${MODELS}" | grep -q "llama2"; then
            export OLLAMA_MODEL="llama2"
        else
            # Use first available model
            export OLLAMA_MODEL=$(echo "${MODELS}" | head -n 1)
        fi
        echo -e "${GREEN}Using Ollama model: ${OLLAMA_MODEL}${NC}"
    else
        echo -e "${RED}No Ollama models available. Summarization may fail.${NC}"
    fi
else
    echo -e "${RED}Ollama service not detected. Summarization will not work.${NC}"
fi

# Clean up old temporary files
TEMP_DIR="${HOME}/.codexcontinue/temp/youtube"
if [ -d "${TEMP_DIR}" ]; then
    echo -e "${YELLOW}Cleaning up old temporary files...${NC}"
    find "${TEMP_DIR}" -type f -mtime +7 -delete
    echo -e "${GREEN}Cleaned up temporary files older than 7 days${NC}"
fi

# Run standalone test first to verify components
echo "Running component test..."
python3 scripts/test-ytdlp-direct.py

# Kill any running ML service
echo "Stopping any existing ML service..."
pkill -f "python3.*ml/app.py" || true
sleep 2

# Start the ML service in the background with explicit environment variables
echo "Starting ML service..."
export PYTHONPATH=/home/msalsouri/Projects/CodexContinue
export FFMPEG_LOCATION=/usr/bin
export PATH=/usr/bin:$PATH
export OLLAMA_MODEL="${OLLAMA_MODEL:-llama3}"

# Verify ffmpeg is installed and accessible
if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg command not found. Please install ffmpeg."
    echo "Try: sudo apt-get install -y ffmpeg"
    exit 1
else
    echo "ffmpeg found at: $(which ffmpeg)"
fi

# Run with proper environment variables
python3 ml/app.py > ml-service.log 2>&1 &
ML_PID=$!

# Wait for the service to start
echo "Waiting for ML service to start..."
sleep 10  # Wait longer to ensure the service is fully initialized

# Check if service is running
if ! curl -s http://localhost:5000/health > /dev/null; then
    echo "Error: ML service failed to start"
    cat ml-service.log
    exit 1
fi

# Run the transcription test
echo "Running transcription test..."
python3 scripts/test-youtube-transcriber.py --url "https://www.youtube.com/watch?v=9bZkp7q19f0" --summarize

# Clean up
echo "Stopping ML service..."
kill $ML_PID
