# 🎬 YouTube Transcription Feature

## Overview
The YouTube Transcription feature in CodexContinue allows you to transcribe YouTube videos to text and optionally summarize the content using Ollama. This feature provides an easy way to extract information from educational videos and presentations.

## Key Features
- **Video Transcription**: Convert YouTube video audio to text using OpenAI's Whisper model
- **Multiple Whisper Models**: Choose from tiny, base, small, medium, or large models for different accuracy/speed trade-offs
- **Local Processing**: All transcription happens locally, with no data sent to external services
- **Summarization**: Optionally generate concise summaries using Ollama models
- **Flexible Usage**: Use through the Streamlit UI, API, or command-line interfaces

## Setup

To set up the YouTube Transcription feature, run:

```bash
./scripts/setup-youtube-transcriber.sh
```

This script will:
- Install ffmpeg if not already installed
- Install required Python packages
- Create necessary directories

For summarization capabilities, you'll need Ollama:

```bash
./scripts/start-ollama-wsl.sh
./scripts/setup-ollama-for-transcription.sh
```

## Usage

### Using the UI
1. Start CodexContinue services: `./scripts/start-mcp-litellm.sh`
2. Open your browser to `http://localhost:8501` and click "YouTube Transcriber" in the sidebar
3. Enter a YouTube URL and configure options
4. Click "Transcribe" or "Transcribe & Summarize"

### Using the API
```bash
curl -X POST http://localhost:5000/youtube/transcribe \
     -H "Content-Type: application/json" \
     -d '{"url": "https://www.youtube.com/watch?v=YourVideoID", "whisper_model_size": "base"}'
```

### Using the Command Line
```bash
python3 scripts/test-youtube-transcriber.py --url "https://www.youtube.com/watch?v=YourVideoID" --summarize
```

## Technical Details
The feature uses:
- **yt-dlp** for downloading YouTube audio
- **ffmpeg** for audio processing
- **OpenAI Whisper** for speech-to-text transcription
- **Ollama** with LLaMA 3 for summarization

For more information, see:
[YouTube Transcription Documentation](docs/features/YOUTUBE_TRANSCRIPTION.md)
