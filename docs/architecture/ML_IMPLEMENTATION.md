# ML Model Implementation in CodexContinue

This document details how machine learning capabilities are implemented in the CodexContinue project.

## Overview

CodexContinue uses a hybrid approach to machine learning:

1. **Custom Ollama Model**: A specialized LLM based on Llama3 for code generation and development tasks
2. **Task-Specific ML Models**: Smaller, specialized models for specific tasks
3. **Learning Capabilities**: Ability to adapt and improve through model updates and training

## Ollama Integration

### CodexContinue Model

The core of our ML capabilities is the CodexContinue custom model:

- **Base**: Built on Llama3
- **Context Window**: 8192 tokens
- **Specialization**: Software development and technical problem-solving
- **Storage**: Located in `ml/models/ollama/Modelfile`

### Model Creation Process

The model is created in the Ollama container through this process:

1. The Modelfile is copied from the original project using `sync-from-original.sh`
2. It is mounted to the Ollama container via a volume in `docker-compose.yml`
3. The `build_codexcontinue_model.sh` script creates the model in Ollama
4. The ML service connects to the model through the Ollama API

### Volume Mapping

For the Ollama integration to work properly, we implement the following volume mappings in the `docker-compose.yml` file:

```yaml
volumes:
  - ollama-data:/root/.ollama  # For model weights and Ollama internal data
  - ./ml/models/ollama:/models/ollama  # For model definition files
```

This ensures:
1. Model definitions are accessible inside the container
2. Model weights are persisted across container restarts
3. Multiple models can be managed independently

### Initialization Process

When starting the project for the first time:

1. Run `./scripts/start-codexcontinue.sh` which:
   - Initializes the project structure
   - Syncs models from the original project
   - Builds and starts containers
   - Creates the CodexContinue model in Ollama

## Directory Structure

```
ml/
├── app/
│   └── services/
│       ├── ml_service.py
│       ├── ml_ollama_router.py
│       └── ml_cache.py
├── models/
│   └── ollama/
│       └── Modelfile
└── scripts/
    ├── build_codexcontinue_model.sh
    └── test_ollama_connection.py
```

## ML Service

The ML service (`ml-service` container) provides:

1. A REST API for accessing ML capabilities
2. Intelligent routing between models for optimal performance
3. Fallbacks to ensure reliability
4. Integration with the backend API

## Configuration

The ML service is configured through environment variables:

- `OLLAMA_API_URL`: URL of the Ollama API (default: http://localhost:11434)
- `DEBUG`: Enable/disable debug mode
- `LOG_LEVEL`: Logging verbosity

## Learning Capabilities

CodexContinue implements learning capabilities through:

1. **Custom Model Updates**: The Modelfile can be modified to update the system prompt and parameters
2. **Domain Specialization**: Models can be customized for different domains like healthcare, finance, etc.
3. **Progressive Learning**: The system can be updated with new knowledge through model retraining
4. **Model Versioning**: Multiple versions of models can be maintained for different use cases

To implement a domain-specific model:

1. Create a new Modelfile in `ml/models/ollama/` (e.g., `Modelfile.healthcare`)
2. Customize the system prompt and parameters for the domain
3. Build the model with a unique name: `codexcontinue-healthcare`
4. Update the environment variables to use the new model

## Troubleshooting

If you encounter issues with the ML models:

1. Check if the Ollama container is running: `docker-compose ps ollama`
2. Verify the model exists: `curl http://localhost:11434/api/tags`
3. Test the ML service: `curl http://localhost:5000/health`
4. Check logs: `docker-compose logs ml-service`
