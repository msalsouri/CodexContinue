# Testing Scripts

This directory contains various test scripts used during development and testing of CodexContinue features.

## YouTube Transcription Test Scripts

These scripts were used during the development and testing of the YouTube transcription feature. 
They are kept here for reference but may not be actively maintained.

## Usage

If you need to test the YouTube transcription feature, it's recommended to use the Streamlit UI
or test the API directly with curl:

```bash
# Test the YouTube transcription API directly with curl
curl -X POST http://localhost:5060/youtube/transcribe \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=jNQXAC9IVRw", "language": "English", "whisper_model_size": "tiny"}'
```

## Creating New Test Scripts

If you need to create new test scripts, place them in this directory following this naming convention:

- `test-<feature>-<functionality>.py` - For Python test scripts
- `test-<feature>-<functionality>.sh` - For Bash test scripts
