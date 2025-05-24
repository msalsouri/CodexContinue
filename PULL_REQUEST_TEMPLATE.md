## PR Description

This PR fixes the YouTube transcriber connectivity issues that were preventing the feature from working correctly. The main problems were:

1. Ollama service not being detected in the frontend
2. Connection to ML service failing with "Max retries exceeded with url: /youtube/transcribe" error

### Changes Made

- **Environment Variable Configuration**:
  - Added required environment variables to the frontend service in both docker-compose files:
    - `OLLAMA_API_URL=http://ollama:11434`: Points to the Ollama service
    - `ML_SERVICE_URL=http://ml-service:5000`: Points to the ML service

- **Frontend Code Updates**:
  - Updated the hardcoded fallback URL in frontend code to use the correct ML service URL:
    ```python
    ML_SERVICE_URL = os.environ.get("ML_SERVICE_URL", "http://ml-service:5000")
    ```

- **Documentation Improvements**:
  - Added comprehensive troubleshooting guide in `docs/troubleshooting-guide.md`
  - Consolidated redundant documentation into a single source of truth
  - Removed outdated and empty documentation files

- **Maintenance Tools**:
  - Created diagnostic scripts to help troubleshoot service connectivity issues:
    - `scripts/diagnose-services.sh`: Checks connectivity between all services
    - `scripts/diagnose-ollama-connectivity.sh`: Specific tool for Ollama connectivity
  - Added cleanup scripts to maintain a clean project directory:
    - `scripts/cleanup-root-files.sh`: Removes temporary log and pid files
    - `scripts/cleanup-docs.sh`: Removes redundant documentation files

### Testing Done

- Verified environment variables are correctly set in both docker-compose files
- Confirmed inter-container connectivity is working properly
- Successfully ran YouTube transcription tests with sample videos
- All verification tests pass, confirming the fixes are working

### Screenshots

[If applicable, add screenshots here]

### References

- Issue #XYZ [Replace with actual issue number if available]
