#!/bin/bash
# Check ffmpeg installation

echo "Checking ffmpeg installation..."
if command -v ffmpeg &> /dev/null; then
    echo "ffmpeg is installed:"
    ffmpeg -version | head -n 1
else
    echo "ffmpeg is NOT installed"
    echo "Please install ffmpeg with: sudo apt-get install -y ffmpeg"
fi

echo "Checking Python and dependencies..."
if command -v python3 &> /dev/null; then
    echo "Python is installed:"
    python3 --version
    
    echo "Checking for yt-dlp and whisper packages:"
    python3 -m pip list | grep -E "yt-dlp|whisper"
else
    echo "Python is NOT installed"
fi

echo "Checking environment variables..."
echo "PATH: $PATH"
echo "PYTHONPATH: $PYTHONPATH"
echo "FFMPEG_LOCATION: $FFMPEG_LOCATION"

echo "Done"
