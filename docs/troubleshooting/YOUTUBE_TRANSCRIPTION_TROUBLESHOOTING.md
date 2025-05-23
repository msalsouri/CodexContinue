# YouTube Transcription Troubleshooting Guide

## Common Issues and Solutions

### 1. ffmpeg Not Found

**Symptoms:**
- Error message: "ffmpeg not found in any standard locations"
- "Missing required executables in /usr/bin: ffmpeg, ffprobe"

**Solutions:**
- Install ffmpeg:
  ```bash
  sudo apt-get update && sudo apt-get install -y ffmpeg
  ```

- Verify installation:
  ```bash
  ffmpeg -version
  which ffmpeg
  ```

- Set environment variables manually:
  ```bash
  export FFMPEG_LOCATION=/usr/bin
  export PATH=/usr/bin:$PATH
  ```

### 2. API Endpoint Returns Error

**Symptoms:**
- 500 error when calling the API endpoint
- Error message about ffmpeg not being found or initialized

**Solutions:**
- Ensure the ML service is started with the correct PYTHONPATH:
  ```bash
  export PYTHONPATH=/home/msalsouri/Projects/CodexContinue
  python3 ml/app.py
  ```

- Try using a different port if port 5000 is in use:
  ```bash
  python3 ml/app.py --port 5050
  ```

- Use the start script which sets up the environment properly:
  ```bash
  ./scripts/start-transcription-service.sh
  ```

### 3. Summarization Not Working

**Symptoms:**
- Transcription works but summarization fails
- Error about Ollama model not found

**Solutions:**
- Ensure Ollama is running:
  ```bash
  ./scripts/start-ollama-wsl.sh
  ```

- Set up Ollama for transcription:
  ```bash
  ./scripts/setup-ollama-for-transcription.sh
  ```

- Check available models:
  ```bash
  curl http://localhost:11434/api/tags
  ```

- Set the OLLAMA_MODEL environment variable:
  ```bash
  export OLLAMA_MODEL=llama3
  ```

### 4. Docker Environment Issues

**Symptoms:**
- Transcription works on host but not in Docker
- Path issues in container

**Solutions:**
- Run the Docker setup script:
  ```bash
  ./docker/ml/setup-youtube-transcription-docker.sh
  ```

- Verify ffmpeg is installed in the container:
  ```bash
  docker exec -it codexcontinue-ml ffmpeg -version
  ```

- Ensure volumes are mounted correctly:
  ```bash
  docker-compose down
  docker-compose up -d
  ```

### 5. Performance Issues

**Symptoms:**
- Transcription takes too long
- System becomes unresponsive during transcription

**Solutions:**
- Use a smaller Whisper model:
  ```json
  {"url": "...", "whisper_model_size": "tiny"}
  ```

- Limit the length of videos being transcribed (under 10 minutes is recommended)

- Ensure enough memory is available (at least 8GB RAM)

- For GPU acceleration, ensure CUDA is properly configured (if available)

## Diagnostic Tools

### 1. Check Environment

Run the status checker to verify all components:
```bash
./scripts/check-transcription-status.py
```

### 2. Test Components Individually

Test just the transcriber component:
```bash
./scripts/test-transcriber-component.py
```

Test the API endpoint:
```bash
./scripts/simple-api-test.py
```

### 3. Run Full Test Suite

Run all tests at once:
```bash
./scripts/test-youtube-transcription-final.sh
```

## Reporting Issues

If you continue to experience problems:

1. Collect the logs:
   ```bash
   cp ml-service-*.log ml-fixed-service.log youtube_transcriber_validation.log /tmp/yt-transcriber-logs/
   ```

2. Include information about your environment:
   ```bash
   python3 --version
   ffmpeg -version
   pip list | grep -E "yt-dlp|whisper|flask"
   ```

3. Create an issue in the repository with this information
