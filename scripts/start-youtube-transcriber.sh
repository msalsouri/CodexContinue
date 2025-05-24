#!/bin/bash
# YouTube Transcription Service Startup Script

# Set the base directory to the script's parent's parent directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Define the port for the ML service
ML_PORT=5060
STREAMLIT_PORT=8501

# Output colorization
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting YouTube Transcription Service${NC}"
echo "Base directory: $BASE_DIR"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}Warning: ffmpeg not found, trying to install...${NC}"
    sudo apt-get update && sudo apt-get install -y ffmpeg
fi

# Start the ML service
echo -e "${GREEN}Starting ML service on port $ML_PORT...${NC}"
cd "$BASE_DIR" && PYTHONPATH="$BASE_DIR" FFMPEG_LOCATION=/usr/bin python3 ml/app.py --port $ML_PORT &
ML_PID=$!
echo "ML service started with PID: $ML_PID"

# Wait for the ML service to start
echo "Waiting for ML service to initialize..."
sleep 5

# Verify the ML service is running
if curl -s http://localhost:$ML_PORT/health > /dev/null; then
    echo -e "${GREEN}ML service is running!${NC}"
else
    echo -e "${YELLOW}Warning: ML service may not be running correctly. Check logs.${NC}"
fi

# Start the Streamlit frontend
echo -e "${GREEN}Starting Streamlit frontend on port $STREAMLIT_PORT...${NC}"
cd "$BASE_DIR" && ML_SERVICE_URL=http://localhost:$ML_PORT PYTHONPATH="$BASE_DIR" streamlit run frontend/pages/youtube_transcriber.py --server.port $STREAMLIT_PORT &
STREAMLIT_PID=$!
echo "Streamlit frontend started with PID: $STREAMLIT_PID"

# Save PIDs for cleanup
echo "$ML_PID" > "$BASE_DIR/.ml_service.pid"
echo "$STREAMLIT_PID" > "$BASE_DIR/.streamlit.pid"

echo -e "${GREEN}Services started! Open your browser at http://localhost:$STREAMLIT_PORT${NC}"
echo "To stop the services, run: ./scripts/stop-youtube-transcriber.sh"
