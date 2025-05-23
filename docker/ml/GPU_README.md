# GPU Support for ML Service

This directory contains Docker configurations and scripts to run the CodexContinue ML service with proper GPU support, avoiding gunicorn-related issues.

## Overview of Changes

The main changes include:

1. **GPU-specific Dockerfile** (`Dockerfile.gpu`):
   - Based on NVIDIA CUDA image
   - Configured for proper GPU access
   - Uses direct Python execution instead of gunicorn
   - Includes all necessary CUDA and GPU environment variables

2. **Updated docker-compose.gpu.yml**:
   - Uses the GPU-specific Dockerfile
   - Properly configures GPU resource allocation
   - Sets necessary environment variables

3. **New start script** (`start-ml-service-gpu.sh`):
   - Checks for NVIDIA GPU availability
   - Builds the GPU-specific container
   - Starts all services with proper GPU configuration
   - Performs basic verification of GPU access

## How to Use

### Prerequisites

- NVIDIA GPU with CUDA support
- NVIDIA drivers installed on the host system
- Docker and docker-compose installed
- NVIDIA Container Toolkit installed

### Starting the ML Service with GPU Support

```bash
# Run the start script
./scripts/start-ml-service-gpu.sh
```

### Verifying GPU Support

After starting the services, you can verify GPU support by:

1. Checking container logs:
```bash
docker-compose logs ml-service
```

2. Running the verification script:
```bash
./scripts/verify-gpu-ollama-wsl.sh
```

3. Checking GPU usage directly:
```bash
docker-compose exec ml-service nvidia-smi
```

## Troubleshooting

If you encounter issues with GPU support:

1. Ensure NVIDIA drivers are properly installed on the host
2. Verify the NVIDIA Container Toolkit is installed and configured
3. Check container logs for any error messages
4. Try restarting the Docker daemon

For more detailed troubleshooting steps, refer to the main documentation.
