#!/bin/bash
# Run the YouTube transcriber test with the right environment settings

set -e  # Exit immediately if a command exits with a non-zero status

# Set up environment variables
export PYTHONPATH=/home/msalsouri/Projects/CodexContinue
export PATH=/usr/bin:$PATH
export FFMPEG_LOCATION=/usr/bin

# Run standalone test first to verify components
echo "Running component test..."
python3 scripts/test-ytdlp-direct.py

# Kill any running ML service
echo "Stopping any existing ML service..."
pkill -f "python3.*ml/app.py" || true
sleep 2

# Start the ML service in the background with explicit environment variables
echo "Starting ML service..."
PYTHONPATH=/home/msalsouri/Projects/CodexContinue FFMPEG_LOCATION=/usr/bin python3 ml/app.py > ml-service.log 2>&1 &
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
