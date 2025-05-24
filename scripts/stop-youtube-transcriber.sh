#!/bin/bash
# YouTube Transcription Service Stop Script

# Set the base directory to the script's parent's parent directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Output colorization
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Stopping YouTube Transcription Service${NC}"

# Check if the ML service PID file exists
if [ -f "$BASE_DIR/.ml_service.pid" ]; then
    ML_PID=$(cat "$BASE_DIR/.ml_service.pid")
    if kill -0 $ML_PID 2>/dev/null; then
        echo "Stopping ML service (PID: $ML_PID)..."
        kill $ML_PID
        echo "ML service stopped"
    else
        echo "ML service is not running"
    fi
    rm "$BASE_DIR/.ml_service.pid"
else
    echo "ML service PID file not found"
fi

# Check if the Streamlit frontend PID file exists
if [ -f "$BASE_DIR/.streamlit.pid" ]; then
    STREAMLIT_PID=$(cat "$BASE_DIR/.streamlit.pid")
    if kill -0 $STREAMLIT_PID 2>/dev/null; then
        echo "Stopping Streamlit frontend (PID: $STREAMLIT_PID)..."
        kill $STREAMLIT_PID
        echo "Streamlit frontend stopped"
    else
        echo "Streamlit frontend is not running"
    fi
    rm "$BASE_DIR/.streamlit.pid"
else
    echo "Streamlit frontend PID file not found"
fi

echo -e "${GREEN}All services stopped${NC}"
