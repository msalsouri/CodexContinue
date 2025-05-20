# Ollama Model Testing Guide

This guide explains how to test and verify the Ollama model integration in CodexContinue across both macOS and Windows platforms.

## Checking Model Availability

The first step is to check if the CodexContinue model is available in Ollama:

```bash
# Run the model check script
./scripts/check_ollama_model.sh
```

This script:

1. Checks if Ollama is running and accessible
2. Lists available models
3. Verifies if the CodexContinue model exists
4. Tests the model with a simple query

## Building the Model

If the model is not available, you have two options to build it:

### Option 1: Using the Check Script

When running `./scripts/check_ollama_model.sh`, if the model doesn't exist, you'll be prompted to build it. Answer 'y' to build the model directly.

### Option 2: Manually Building

```bash
# For macOS (using the non-GPU version)
# First ensure Ollama is running
./scripts/start-ollama-macos.sh

# For Windows or full environment
# First ensure all services are running
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Then run the build script
docker exec codexcontinue-ml-service-1 bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh"
```

## Testing the Model

### Basic Testing

Once the model is built, test it with a simple query:

```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "codexcontinue",
  "prompt": "Write a simple hello world function in Python."
}'
```

You should receive a code response from the model.

### Performance Testing

To test model performance differences between platforms:

```bash
# Save start time
START=$(date +%s)

# Send a complex query
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "codexcontinue",
  "prompt": "Explain how to implement a binary search tree in Python with detailed code examples."
}'

# Calculate elapsed time
END=$(date +%s)
echo "Time taken: $((END-START)) seconds"
```

On Windows with GPU acceleration, this should be significantly faster than on macOS.

## Understanding Platform Differences

### macOS Configuration

On macOS, Ollama runs without GPU acceleration:

- Uses CPU for model inference
- Model response will be slower
- Less memory consumption
- Container configuration in `docker-compose.macos.yml`

### Windows Configuration

On Windows with NVIDIA GPU:

- Uses GPU acceleration
- Faster response times
- Higher memory consumption
- Container configuration in standard `docker-compose.yml`

## Troubleshooting Model Issues

### Model Not Found

If the model check says "CodexContinue model is not available":

1. Verify Ollama is running:

   ```bash
   curl http://localhost:11434/api/tags
   ```

2. Check the Modelfile exists:

   ```bash
   cat ml/models/ollama/Modelfile
   ```

3. Try building manually (see above)

### Model Not Responding

If the model exists but doesn't generate responses:

1. Check container logs:

   ```bash
   docker logs codexcontinue-ollama-1
   ```

2. Restart the Ollama container:

   ```bash
   docker restart codexcontinue-ollama-1
   ```

3. On Windows, verify GPU access:

   ```bash
   docker exec codexcontinue-ollama-1 nvidia-smi
   ```

### Slow Performance

If model responses are unusually slow:

1. Check hardware resource usage:

   ```bash
   # On macOS
   top -o cpu

   # On Windows
   docker stats
   ```

2. For Windows, verify GPU usage:

   ```bash
   nvidia-smi
   ```

## Advanced: Creating Custom Models

You can create domain-specific variants of the CodexContinue model:

1. Create a custom Modelfile:

   ```bash
   cp ml/models/ollama/Modelfile ml/models/ollama/Modelfile.domain
   ```

2. Edit the system prompt in the new Modelfile

3. Create a build script for the new model:

   ```bash
   cp ml/scripts/build_codexcontinue_model.sh ml/scripts/build_domain_model.sh
   ```

4. Edit the script to use the new model name and Modelfile

5. Run your custom build script

See [DOMAIN_CUSTOMIZATION.md](DOMAIN_CUSTOMIZATION.md) for more details.
