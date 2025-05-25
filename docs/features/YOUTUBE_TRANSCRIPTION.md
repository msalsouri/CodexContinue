# YouTube Transcription Feature

This feature allows you to transcribe YouTube videos to text and optionally summarize the content using Ollama. It provides an easy way to extract information from educational videos and presentations.

## Overview

The YouTube Transcription feature in CodexContinue combines:

1. **yt-dlp**: To download audio from YouTube videos
2. **OpenAI Whisper**: For high-quality speech-to-text transcription
3. **Ollama**: For summarizing the transcribed content

All processing happens locally on your machine, ensuring privacy and data security.

## Technical Architecture

The feature is implemented with these components:

- **ML Service**: Flask API that handles transcription requests
- **Frontend**: Streamlit UI for user interaction
- **Storage**: Local caching of downloaded audio and transcriptions
- **GPU Acceleration**: Optional GPU support for faster transcription

## Setup

The YouTube Transcription feature is included in the standard CodexContinue installation. To start the service:

```bash
# Start all services with Docker Compose
docker compose up -d
```

Or you can use the provided script:

```bash
./scripts/start-codexcontinue.sh
```

## Dependencies

The feature requires:
- **ffmpeg**: For audio processing
- **yt-dlp**: For downloading YouTube videos
- **openai-whisper**: For transcription
- **Ollama**: For summarization (optional)

These dependencies are automatically installed in the Docker containers.

## Usage

1. Navigate to the YouTube Transcriber page in the Streamlit UI:
   - Open your browser to `http://localhost:8501`
   - Click on "YouTube Transcriber" in the sidebar

2. Enter a YouTube URL and configure options:
   - Select the language (optional, improves accuracy)
   - Choose a Whisper model size (larger models are more accurate but slower)
   - Click "Transcribe" to get just the transcript
   - Click "Transcribe & Summarize" to also get an AI-generated summary

3. View the results in the tabbed interface:
   - **Video**: Watch the original YouTube video
   - **Transcript**: Read and download the full transcript
   - **Summary**: Read and download the AI-generated summary (if requested)

## Advanced Features

### Caching

Downloaded videos and transcriptions are cached to avoid redundant processing:
- Audio files are stored in `~/.codexcontinue/temp/youtube/`
- Files older than 7 days are automatically cleaned up

### GPU Acceleration

The system can use GPU acceleration for Whisper if available:
- CUDA for NVIDIA GPUs 
- MPS for Apple Silicon GPUs

## Troubleshooting

If you encounter issues with the YouTube transcription feature:

1. Check connectivity between services:
   ```bash
   ./scripts/diagnose-services.sh
   ```

2. Verify environment variables in docker-compose.yml:
   - `OLLAMA_API_URL` should be set to `http://ollama:11434`
   - `ML_SERVICE_URL` should be set to `http://ml-service:5000`

3. Check the logs for specific errors:
   ```bash
   docker compose logs ml-service
   docker compose logs frontend
   ```

4. For more details, see the [troubleshooting guide](../troubleshooting-guide.md).

## Future Enhancements

Planned improvements include:
- Batch processing of multiple YouTube videos
- Custom summarization prompts
- Saving transcriptions to knowledge base
- Annotation and highlighting of transcriptions
