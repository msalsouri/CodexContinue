#!/bin/bash
# Set up and test YouTube transcription in Docker environment

# Detect if we're running in a Docker container
if [ -f /.dockerenv ]; then
    echo "Running in Docker environment"
    IS_DOCKER=true
else
    echo "Running in non-Docker environment"
    IS_DOCKER=false
fi

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    
    if [ "$IS_DOCKER" = true ]; then
        # In Docker, we need to use apt-get
        apt-get update
        apt-get install -y ffmpeg curl python3-pip
    else
        # On host, use the package manager based on distro
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y ffmpeg curl python3-pip
        elif command -v yum &> /dev/null; then
            sudo yum install -y ffmpeg curl python3-pip
        elif command -v brew &> /dev/null; then
            brew install ffmpeg curl python3-pip
        else
            echo "Unsupported package manager. Please install ffmpeg, curl, and python3-pip manually."
            exit 1
        fi
    fi
    
    # Install Python packages
    pip install yt-dlp openai-whisper flask flask-cors requests
    
    echo "Dependencies installed successfully"
}

# Function to setup directories
setup_directories() {
    echo "Setting up directories..."
    
    # Create necessary directories
    mkdir -p ~/.codexcontinue/temp/youtube
    mkdir -p ~/.codexcontinue/config
    
    echo "Directories created successfully"
}

# Function to test the setup
test_setup() {
    echo "Testing setup..."
    
    # Check if ffmpeg is installed
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is not installed"
        return 1
    fi
    
    # Check if yt-dlp can be imported
    if ! python3 -c "import yt_dlp" &> /dev/null; then
        echo "Error: yt-dlp is not installed"
        return 1
    fi
    
    # Check if whisper can be imported
    if ! python3 -c "import whisper" &> /dev/null; then
        echo "Error: whisper is not installed"
        return 1
    fi
    
    echo "Setup test successful"
    return 0
}

# Function to run a simple transcription test
run_transcription_test() {
    echo "Running transcription test..."
    
    # Set environment variables
    export PYTHONPATH="${PYTHONPATH:-.}"
    
    # Run the test
    python3 -c "
import os
import sys
from ml.services.youtube_transcriber import YouTubeTranscriber

def test():
    # Create transcriber with tiny model for quick testing
    print('Creating YouTubeTranscriber...')
    transcriber = YouTubeTranscriber(whisper_model_size='tiny')
    
    # Print settings
    print(f'ffmpeg_location: {transcriber.ffmpeg_location}')
    print(f'ollama_api_url: {transcriber.ollama_api_url}')
    print(f'ollama_model: {transcriber.ollama_model}')
    
    # Test with a short video
    url = 'https://www.youtube.com/watch?v=9bZkp7q19f0'
    print(f'Testing with URL: {url}')
    
    # Download audio
    audio_file = transcriber.download_audio(url)
    print(f'Audio downloaded: {audio_file}')
    
    # Transcribe
    print('Transcribing...')
    result = transcriber.transcribe(audio_file)
    
    # Print result
    text = result.get('text', '')
    segments = result.get('segments', [])
    print(f'Transcription successful:')
    print(f'  Characters: {len(text)}')
    print(f'  Segments: {len(segments)}')
    print(f'  Preview: {text[:100]}...')
    
    # Save transcript
    with open('docker_test_transcript.txt', 'w') as f:
        f.write(text)
    print('Transcript saved to docker_test_transcript.txt')
    
    return True

if __name__ == '__main__':
    try:
        success = test()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f'Error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)
"
    
    if [ $? -eq 0 ]; then
        echo "Transcription test successful"
        return 0
    else
        echo "Transcription test failed"
        return 1
    fi
}

# Main function
main() {
    echo "===== YouTube Transcription Setup ====="
    
    # Install dependencies
    install_dependencies
    
    # Setup directories
    setup_directories
    
    # Test the setup
    if ! test_setup; then
        echo "Setup test failed. Please check the error messages above."
        exit 1
    fi
    
    # Run transcription test
    if ! run_transcription_test; then
        echo "Transcription test failed. Please check the error messages above."
        exit 1
    fi
    
    echo "===== YouTube Transcription Setup Complete ====="
    echo "The YouTube transcription feature is now set up and ready to use."
    
    return 0
}

# Run the main function
main
