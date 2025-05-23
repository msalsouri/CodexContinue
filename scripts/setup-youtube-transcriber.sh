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

echo "Setup completed successfully!"
echo "You can now use the YouTube transcription feature in CodexContinue."
