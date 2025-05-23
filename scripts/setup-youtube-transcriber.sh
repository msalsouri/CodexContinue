#!/bin/bash
# Setup script for YouTube transcription feature

echo "Setting up YouTube Transcription feature for CodexContinue..."

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Installing ffmpeg..."
    sudo apt-get update
    sudo apt-get install -y ffmpeg
else
    echo "ffmpeg is already installed."
fi

# Install Python dependencies
echo "Installing Python dependencies..."
python3 -m pip install yt-dlp openai-whisper ffmpeg-python

# Create necessary directories
echo "Creating temporary directories..."
mkdir -p ~/.codexcontinue/temp/youtube
mkdir -p ~/.codexcontinue/config

# Check if Ollama is running and configure it
echo "Checking Ollama for summarization capability..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "Ollama is running. Setting up transcription configuration..."
    bash "$(dirname "$0")/setup-ollama-for-transcription.sh"
else
    echo "Ollama is not running. Summarization will not be available."
    echo "To enable summarization, start Ollama with:"
    echo "  ./scripts/start-ollama-wsl.sh"
    echo "Then run:"
    echo "  ./scripts/setup-ollama-for-transcription.sh"
fi

echo "Setup completed successfully!"
echo "You can now use the YouTube transcription feature in CodexContinue."
