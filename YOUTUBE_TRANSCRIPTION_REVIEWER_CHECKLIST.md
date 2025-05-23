# YouTube Transcription Feature - Reviewer Checklist

This checklist will help you verify the YouTube transcription feature works correctly after merging.

## 🔍 Verification Checklist

### Basic Setup
- [ ] Ensure ffmpeg is installed (`apt-get install ffmpeg` or equivalent)
- [ ] Ensure Python dependencies are installed (`pip install -r ml/requirements.txt`)
- [ ] Optionally, ensure Ollama is installed for summarization features

### Running the Service
- [ ] Start the ML service: `./scripts/start-transcription-service.sh`
- [ ] Verify the service is running on port 5000 (default)
- [ ] Check health endpoint: `curl http://localhost:5000/health`

### Testing Transcription
- [ ] Run the verification script: `./scripts/verify-pr.sh`
- [ ] Test English video transcription:
  ```
  curl -X POST -H "Content-Type: application/json" \
      -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw", "language":"en"}' \
      http://localhost:5000/youtube/transcribe
  ```
- [ ] Test Korean video transcription:
  ```
  curl -X POST -H "Content-Type: application/json" \
      -d '{"url":"https://www.youtube.com/watch?v=9bZkp7q19f0"}' \
      http://localhost:5000/youtube/transcribe
  ```

### Docker Environment
- [ ] Test in Docker environment:
  ```
  cd docker/ml
  ./setup-youtube-transcription-docker.sh
  ```

### Advanced Testing
- [ ] Test Ollama integration if available:
  ```
  curl -X POST -H "Content-Type: application/json" \
      -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw", "summarize":true}' \
      http://localhost:5000/youtube/transcribe
  ```
- [ ] Test with a custom whisper model size:
  ```
  curl -X POST -H "Content-Type: application/json" \
      -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw", "whisper_model_size":"small"}' \
      http://localhost:5000/youtube/transcribe
  ```

## 🐛 Common Issues and Solutions

### FFMPEG Not Found
If you get an error about ffmpeg not being found:
- Install ffmpeg: `apt-get install ffmpeg` (or equivalent for your OS)
- Set the FFMPEG_LOCATION environment variable: `export FFMPEG_LOCATION=/path/to/ffmpeg`

### Transcription Too Slow
- Try using a smaller Whisper model size: `tiny`, `base`, `small`
- The first transcription is slow due to model loading, subsequent calls will be faster

### Ollama Integration Not Working
- Make sure Ollama is running: `curl http://localhost:11434/api/tags`
- If using Docker, ensure the Ollama API is accessible from the ML service container

## 📝 Feedback
If you encounter any issues or have suggestions for improvement, please add them to the PR discussion or create a new issue referencing this feature.
