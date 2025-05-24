# CodexContinue Troubleshooting Guide

## YouTube Transcriber Connectivity Issues

### Issue: Ollama service not being detected & ML service connection failures

**Symptoms:**
1. Frontend unable to connect to Ollama service
2. Connection to ML service failing with "Max retries exceeded with url: /youtube/transcribe" error
3. YouTube transcription feature not working

**Root Causes:**
1. Missing environment variables in the frontend container configuration
2. Frontend using incorrect port (5060) to connect to ML service instead of the correct port (5000)
3. Container networking not properly configured for service discovery

**Fix Applied:**
1. Added required environment variables to the frontend service in both docker-compose files:
   - `OLLAMA_API_URL=http://ollama:11434`: Points to the Ollama service
   - `ML_SERVICE_URL=http://ml-service:5000`: Points to the ML service

2. Updated the hardcoded fallback URL in frontend code:
   ```python
   ML_SERVICE_URL = os.environ.get("ML_SERVICE_URL", "http://ml-service:5000")
   ```

3. Rebuilt and restarted the containers with the new configuration

**Verifying the Fix:**
1. Check ML service health: `curl http://localhost:5000/health`
2. Verify Ollama service accessibility from ML service: 
   ```
   docker exec codexcontinue-ml-service-1 curl -s http://ollama:11434/api/tags
   ```
3. Test YouTube transcription with a sample video URL

**Prevention:**
1. Always use environment variables for service URLs instead of hardcoding them
2. Add more robust health checks and connectivity tests at startup
3. Implement a more comprehensive system diagnostic tool

## Other Common Issues

### Container Startup Failures

If any container fails to start:

1. Check container logs: `docker compose logs <service-name>`
2. Verify volume mounts and permissions
3. Ensure required environment variables are set

### GPU Access Issues for Ollama

If Ollama can't access GPU resources:

1. Verify Docker has GPU access: `docker run --gpus all nvidia/cuda:11.0-base nvidia-smi`
2. Check that nvidia-container-toolkit is installed and configured correctly
3. Ensure Ollama container has proper GPU resource allocation in docker-compose.yml

## Maintenance and Cleanup

### Removing Temporary Files

Over time, log files and other temporary files may accumulate in the project directory. To clean up these files:

1. Run the cleanup script: `./scripts/cleanup-root-files.sh`
2. This script will remove:
   - Log files (e.g., `frontend.log`, `ml_service.log`)
   - PID files (e.g., `.ml_service.pid`, `.streamlit.pid`)
   - Any temporary override files

These files are temporary in nature and don't contain important configuration or persistent data, so they can be safely removed.

### Using the Diagnostics Tool

To diagnose service connectivity issues:

1. Run the diagnostics script: `./scripts/diagnose-services.sh`
2. This tool will check:
   - Container status
   - Environment variables
   - Service health endpoints
   - Inter-container connectivity
