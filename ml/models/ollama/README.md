# CodexContinue Ollama Model

This directory contains the model definitions for the CodexContinue Ollama-based LLM integration.

## Model Files

- `Modelfile`: The primary model definition for the CodexContinue model, based on Llama3.

## Model Configuration

The CodexContinue model has the following configurations:

- **Base Model**: Llama3
- **Parameters**:
  - Temperature: 0.7
  - Top-p: 0.9
  - Top-k: 40
  - Context Window: 8192 tokens
- **Specialization**: Software development, code generation, and technical problem-solving
- **Response Format**: Custom template for consistent output

## Platform-Specific Configurations

### Windows (with GPU)

On Windows with GPU capabilities, the standard Docker Compose configuration will use GPU acceleration:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

### macOS (CPU only)

On macOS, GPU acceleration is not available, so we use the modified `docker-compose.macos.yml` which removes GPU requirements:

```bash
# Start the development environment on macOS
docker compose -f docker-compose.yml -f docker-compose.macos.yml up -d ollama
```

## Building the Model

The model is built using the script at `ml/scripts/build_codexcontinue_model.sh`, which is automatically run during project initialization.

To manually rebuild the model:

```bash
# First ensure Ollama service is running
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d ollama

# For macOS without GPU
docker compose -f docker-compose.yml -f docker-compose.macos.yml up -d ollama

# Then execute the build script inside the container
docker exec codexcontinue-ml-service-1 bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh"
```

## Verification

To verify the model is working correctly:

```bash
./scripts/check_ollama_model.sh
```

## Testing the Model

You can test the model directly with a curl command:

```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "codexcontinue",
  "prompt": "Write a simple hello world function in Python."
}'
```
