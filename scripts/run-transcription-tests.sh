#!/bin/bash
# Run comprehensive tests for the YouTube transcription feature

set -e
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_LOG="youtube-transcription-test.log"

# Initialize log file
echo "YouTube Transcription Feature Tests" > "$TEST_LOG"
echo "$(date)" >> "$TEST_LOG"
echo "===================================" >> "$TEST_LOG"

# Print section header
print_section() {
  echo ""
  echo "====================================================="
  echo "  $1"
  echo "====================================================="
  echo ""
}

# Set environment variables
export PYTHONPATH="$PROJECT_ROOT"
export PATH="/usr/bin:$PATH"
export FFMPEG_LOCATION="/usr/bin"

# Check ffmpeg installation
print_section "Checking ffmpeg installation"
if ! command -v ffmpeg &> /dev/null; then
  echo "❌ ffmpeg not found. Installing ffmpeg..."
  sudo apt-get update && sudo apt-get install -y ffmpeg
else
  FFMPEG_VERSION=$(ffmpeg -version | head -n 1)
  echo "✅ ffmpeg is installed: $FFMPEG_VERSION"
fi

# Check dependencies
print_section "Checking Python dependencies"
REQUIRED_PACKAGES=("yt-dlp" "openai-whisper" "flask" "flask-cors")
MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
  if ! pip show $package &> /dev/null; then
    echo "❌ Package $package is missing"
    MISSING_PACKAGES+=("$package")
  else
    VERSION=$(pip show $package | grep Version | cut -d' ' -f2)
    echo "✅ $package is installed (version $VERSION)"
  fi
done

# Install missing packages if needed
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
  echo "Installing missing packages..."
  pip install "${MISSING_PACKAGES[@]}"
fi

# Stop any existing ML service
print_section "Stopping any existing ML service"
pkill -f "python.*ml/app.py" || true
sleep 2

# Start ML service in the background
print_section "Starting ML service"
python3 "$PROJECT_ROOT/ml/app.py" > ml-service.log 2>&1 &
ML_PID=$!
echo "ML service started with PID: $ML_PID"
echo "Waiting for ML service to initialize..."
sleep 5

# Check if service is running
if ! curl -s http://localhost:5000/health > /dev/null; then
  echo "❌ Error: ML service failed to start"
  cat ml-service.log
  exit 1
else
  echo "✅ ML service is running"
fi

# Run validation script
print_section "Running basic validation script"
python3 "$PROJECT_ROOT/scripts/validate-youtube-transcriber.py"
VALIDATION_STATUS=$?

if [ $VALIDATION_STATUS -ne 0 ]; then
  echo "❌ Basic validation failed with status: $VALIDATION_STATUS"
  cat youtube_transcriber_validation.log
else
  echo "✅ Basic validation passed"
fi

# Run comprehensive tests
print_section "Running comprehensive tests"
python3 "$PROJECT_ROOT/scripts/test-transcriber-comprehensive.py" --start-ml

# Check if Ollama is available
if curl -s http://localhost:11434/api/tags > /dev/null; then
  print_section "Testing with Ollama summarization"
  python3 "$PROJECT_ROOT/scripts/test-transcriber-comprehensive.py" --summary
else
  echo "⚠️ Ollama is not available, skipping summarization tests"
fi

# Stop ML service
print_section "Stopping ML service"
kill $ML_PID || true
sleep 2

echo "All tests completed"

# Check for result files and display summary
if [ -f "transcription_test_results.json" ]; then
  print_section "Test Result Summary"
  echo "See transcription_test_results.json for detailed results"
  echo "Transcript sample is in transcript_test_output.txt"
fi

echo "Log files generated:"
echo "- ml-service.log - ML service output"
echo "- youtube_transcriber_validation.log - Basic validation results"
echo "- transcriber-comprehensive-test.log - Comprehensive test log"

echo "Done"
