#!/bin/bash
# Start the ML service with proper environment setup

# Detect the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default port
PORT=5000

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
      PORT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--port PORT]"
      echo "  --port PORT  Port to run the ML service on (default: 5000)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo "Starting YouTube Transcription ML Service"
echo "========================================"
echo "Project root: $PROJECT_ROOT"
echo "Port: $PORT"

# Make sure PYTHONPATH is set correctly
export PYTHONPATH="$PROJECT_ROOT"
echo "PYTHONPATH: $PYTHONPATH"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ ERROR: ffmpeg is not installed"
    echo "Please install ffmpeg first:"
    echo "  sudo apt-get update && sudo apt-get install -y ffmpeg"
    exit 1
else
    FFMPEG_PATH=$(which ffmpeg)
    echo "✅ ffmpeg found at: $FFMPEG_PATH"
    
    # Set FFMPEG_LOCATION environment variable
    export FFMPEG_LOCATION=$(dirname "$FFMPEG_PATH")
    echo "FFMPEG_LOCATION: $FFMPEG_LOCATION"
fi

# Check if whisper is installed
if ! python3 -c "import whisper" &> /dev/null; then
    echo "❌ ERROR: whisper is not installed"
    echo "Please install whisper first:"
    echo "  pip install openai-whisper"
    exit 1
else
    echo "✅ whisper is installed"
fi

# Check if yt-dlp is installed
if ! python3 -c "import yt_dlp" &> /dev/null; then
    echo "❌ ERROR: yt-dlp is not installed"
    echo "Please install yt-dlp first:"
    echo "  pip install yt-dlp"
    exit 1
else
    echo "✅ yt-dlp is installed"
fi

# Create necessary directories
mkdir -p "$HOME/.codexcontinue/temp/youtube"
mkdir -p "$HOME/.codexcontinue/config"
echo "✅ Directories created"

# Log file
LOG_FILE="$PROJECT_ROOT/ml-service-$(date +%Y%m%d-%H%M%S).log"

echo "Starting ML service..."
echo "Log file: $LOG_FILE"
echo "Use Ctrl+C to stop the service"
echo

# Start the ML service
python3 "$PROJECT_ROOT/ml/app.py" --port "$PORT" 2>&1 | tee "$LOG_FILE"
