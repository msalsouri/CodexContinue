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
pip install yt-dlp==2023.3.4 openai-whisper==20230314 ffmpeg-python==0.2.0

# Create necessary directories
echo "Creating temporary directories..."
mkdir -p ~/.codexcontinue/temp/youtube

echo "Setup completed successfully!"
echo "You can now use the YouTube transcription feature in CodexContinue."
