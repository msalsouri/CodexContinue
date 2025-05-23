# YouTube Transcription Feature

This feature allows you to transcribe YouTube videos to text and optionally summarize the content using Ollama.

## Overview

The YouTube Transcription feature in CodexContinue combines:

1. **yt-dlp**: To download audio from YouTube videos
2. **OpenAI Whisper**: For high-quality speech-to-text transcription
3. **Ollama**: For summarizing the transcribed content

## Setup

To set up the YouTube Transcription feature, run:

```bash
./scripts/setup-youtube-transcriber.sh
```

This script will:
- Install ffmpeg if not already installed
- Install required Python packages
- Create necessary directories

## Usage

1. Start the CodexContinue services:
   ```bash
   ./scripts/start-mcp-litellm.sh
   ```

2. Navigate to the YouTube Transcriber page in the Streamlit UI:
   - Open your browser to `http://localhost:8501`
   - Click on "YouTube Transcriber" in the sidebar

3. Enter a YouTube URL and configure options:
   - Select the language (optional, improves accuracy)
   - Choose a Whisper model size (larger models are more accurate but slower)
   - Click "Transcribe" to get just the transcript
   - Click "Transcribe & Summarize" to also get an AI-generated summary

4. View the results in the tabbed interface:
   - **Video**: Watch the original YouTube video
   - **Transcript**: Read and download the full transcript
   - **Summary**: Read and download the AI-generated summary (if requested)

5. Download the results as text files if needed

## Command Line Usage

You can also test the feature from the command line:

```bash
# Basic transcription
python3 scripts/test-youtube-transcriber.py --url "https://www.youtube.com/watch?v=YourVideoID"

# Transcription with summarization
python3 scripts/test-youtube-transcriber.py --url "https://www.youtube.com/watch?v=YourVideoID" --summarize
```

### Advanced Testing

For more detailed testing and troubleshooting, we provide additional test scripts:

```bash
# Run the complete test suite (component test + end-to-end test)
./scripts/run-youtube-test.sh

# Test the transcriber directly without Flask
python3 scripts/test-transcriber-direct.py

# Comprehensive validation of ffmpeg integration and transcription
python3 scripts/test-transcriber-full.py
```

These scripts include detailed logging and environment setup to ensure ffmpeg is properly configured.

## Technical Implementation

The feature consists of three main components:

1. **Backend Service**: A Python class that handles downloading and transcription
   - Located at `ml/services/youtube_transcriber.py`
   - Supports multiple Whisper model sizes (tiny, base, small, medium, large)
   - Integrated with Ollama for summarization

2. **API Endpoint**: A Flask endpoint for the ML service
   - Added to `ml/app.py`
   - Supports both transcription-only and transcription+summarization modes

3. **Frontend UI**: A Streamlit page for user interaction
   - Located at `frontend/pages/youtube_transcriber.py`
   - Tabbed interface for better organization of content
   - Support for different Whisper model sizes
   - Enhanced with metadata and segment viewing

## Environment Variables

The feature supports the following environment variables:

- `OLLAMA_API_URL`: URL for the Ollama API (default: `http://localhost:11434`)
- `OLLAMA_MODEL`: Model to use for summarization (default: `codexcontinue`)
- `ML_SERVICE_URL`: URL for the ML service API (default: `http://localhost:5000`)

## Troubleshooting

If you encounter issues:

- Ensure ffmpeg is properly installed: `ffmpeg -version`
- Check if Whisper is installed: `pip show openai-whisper`
- Verify the Ollama service is running: `curl http://localhost:11434/api/tags`
- Run the setup script: `./scripts/setup-ollama-for-transcription.sh` to configure Ollama
- Check the ML service logs for detailed error messages
- Try with a shorter video if processing is taking too long
- Use the CPU-only mode if GPU integration is causing issues

### FFmpeg Troubleshooting

If you encounter errors related to ffmpeg not being found:

1. Verify ffmpeg is installed:
   ```bash
   ffmpeg -version
   which ffmpeg
   ```

2. Run the comprehensive test script to validate ffmpeg integration:
   ```bash
   python3 scripts/test-transcriber-full.py
   ```

3. Common solutions:
   - Install ffmpeg if missing: `sudo apt-get install -y ffmpeg`
   - Set PATH and FFMPEG_LOCATION environment variables:
     ```bash
     export PATH=/usr/bin:$PATH
     export FFMPEG_LOCATION=/usr/bin
     ```
   - For Docker environments, ensure ffmpeg is installed in the container

### Ollama Configuration

For summarization to work, you need a working Ollama installation with at least one model.
The system will automatically use an available model in this order of preference:
1. `codexcontinue` (custom model optimized for CodexContinue)
2. `llama3` 
3. `llama2`
4. `mistral`
5. `codellama`
6. Any other available model

To configure Ollama and set up an appropriate model:
```bash
# Start Ollama if not already running
./scripts/start-ollama-wsl.sh

# Configure Ollama for transcription (automatic model selection)
./scripts/setup-ollama-for-transcription.sh
```

## Limitations

- Processing longer videos (>10 minutes) may take significant time
- The quality of transcription depends on the audio clarity
- Summarization works best with clear, structured content
- The largest Whisper models require significant RAM and processing power
