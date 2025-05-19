# Windows Setup Guide for CodexContinue

This guide explains how to set up and run CodexContinue on Windows with GPU acceleration.

## Prerequisites

1. **Docker Desktop for Windows**
   - [Download and install Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Enable WSL 2 integration

2. **NVIDIA GPU Drivers**
   - Install the latest NVIDIA drivers for your GPU
   - [NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-downloads) (optional but recommended)

3. **NVIDIA Container Toolkit (nvidia-docker)**
   - Follow the [installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)
   - This allows Docker containers to access GPU capabilities

4. **Git for Windows**
   - [Download and install Git](https://git-scm.com/download/win)

## Setup Steps

### 1. Clone the Repository

```bash
# Clone the repository from GitHub
git clone https://github.com/your-username/CodexContinue.git
cd CodexContinue
```

### 2. Verify GPU Support

```bash
# Check that NVIDIA drivers are working
nvidia-smi

# Verify that NVIDIA Docker integration works
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### 3. Start the Environment

```bash
# Start the development environment with GPU support
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### 4. Build the Ollama Model

The Ollama model should build automatically. To verify or rebuild:

```bash
# Check if the model is built
./scripts/check_ollama_model.sh

# Rebuild the model if needed
docker exec codexcontinue-ml-service-1 bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh"
```

### 5. Access the Services

- **Frontend**: <http://localhost:8501>
- **Backend API**: <http://localhost:8000>
- **ML Service**: <http://localhost:5000>
- **Jupyter Lab**: <http://localhost:8888>
- **Ollama API**: <http://localhost:11434>

## Performance Optimization

When using CodexContinue on Windows with a powerful GPU, you can:

1. **Increase Model Context Window**
   - Edit `ml/models/ollama/Modelfile` to increase `num_ctx` parameter
   - Higher values allow processing larger documents and more context

2. **Adjust Performance Parameters**
   - Tune the model parameters in the Modelfile for your specific hardware
   - More powerful GPUs can handle larger models and more intensive processing

3. **Enable Multi-GPU Support** (for systems with multiple GPUs)
   - Modify the `docker-compose.yml` file to specify which GPUs to use

## Development Workflow

1. Make your code changes
2. Test locally
3. Commit and push changes:

   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

## Troubleshooting

### GPU Not Detected

If the container can't access the GPU:

1. Verify NVIDIA drivers are installed: `nvidia-smi`
2. Check NVIDIA Docker integration: `docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi`
3. Restart Docker Desktop
4. Ensure the `--gpus all` flag is properly passed to containers

### Container Startup Issues

If containers fail to start:

1. Check Docker logs: `docker logs codexcontinue-ollama-1`
2. Verify port availability: ensure ports 8000, 8501, 5000, 8888, 11434 are not in use
3. Check resource allocation in Docker Desktop settings

### Ollama Model Build Failures

If the Ollama model fails to build:

1. Check Ollama logs: `docker logs codexcontinue-ollama-1`
2. Verify the Modelfile syntax
3. Try rebuilding with the build script
4. Check GPU memory - larger models require more VRAM
