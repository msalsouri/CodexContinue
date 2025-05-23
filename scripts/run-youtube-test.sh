#!/bin/bash
# Run the YouTube transcriber test with the right environment settings

set -e  # Exit immediately if a command exits with a non-zero status

# Set up environment variables
export PYTHONPATH=/home/msalsouri/Projects/CodexContinue
export PATH=/usr/bin:$PATH
export FFMPEG_LOCATION=/usr/bin

# Configure Ollama model - check for available models and set an appropriate one
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "Checking available Ollama models..."
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
        echo "Using Ollama model: ${OLLAMA_MODEL}"
    else
        echo "No Ollama models available. Summarization may fail."
    fi
else
    echo "Ollama service not detected. Summarization will not work."
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
PYTHONPATH=/home/msalsouri/Projects/CodexContinue \
FFMPEG_LOCATION=/usr/bin \
PATH=/usr/bin:$PATH \
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3}" \
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
