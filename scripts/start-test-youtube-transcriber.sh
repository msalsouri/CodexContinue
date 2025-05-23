#!/bin/bash
# Start and test the YouTube transcription feature

set -e
echo "Starting and testing YouTube transcription feature"

# Set environment variables
export PYTHONPATH=$(pwd)
export FFMPEG_LOCATION=/usr/bin
export PATH=/usr/bin:$PATH

# Kill any existing ML service
echo "Stopping any running ML service..."
kill $(ps aux | grep "python.*app.py" | grep -v grep | awk '{print $2}') 2>/dev/null || true

# Start the ML service
echo "Starting ML service..."
python3 ml/app.py > ml-service.log 2>&1 &
ML_PID=$!

# Wait for the service to start
echo "Waiting for ML service to start..."
sleep 5

# Check if the service is running
if ! ps -p $ML_PID > /dev/null; then
    echo "Error: ML service failed to start. Check ml-service.log for details."
    exit 1
fi

# Run the validation test
echo "Running validation test..."
python3 scripts/validate-youtube-transcriber.py

# Get the test status
TEST_STATUS=$?

echo "Test completed with status: $TEST_STATUS"

# Show ML service logs
echo "ML service logs:"
cat ml-service.log

# Return the test status
exit $TEST_STATUS
