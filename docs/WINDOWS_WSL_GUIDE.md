# Windows WSL Development Guide for CodexContinue

This guide provides specific instructions for Windows users working with CodexContinue in WSL (Windows Subsystem for Linux).

## Quick Start

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/CodexContinue.git
   cd CodexContinue
   ```

2. **Run the WSL quick setup script**:

   ```bash
   chmod +x scripts/wsl-quick-setup.sh
   ./scripts/wsl-quick-setup.sh
   ```

This script will check your environment, start the necessary services, and verify that everything is working correctly.

## Manual Setup Steps

If you prefer to set up manually or the quick setup script fails:

1. **Check your environment**:

   ```bash
   ./scripts/check-platform.sh
   ```

2. **Start the Ollama service with GPU support**:

   ```bash
   chmod +x scripts/start-ollama-wsl.sh
   ./scripts/start-ollama-wsl.sh
   ```

3. **Verify that the Ollama model is built**:

   ```bash
   ./scripts/check_ollama_model.sh
   ```

4. **Start the remaining services**:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

## Troubleshooting

### GPU Access Issues

If you're having issues with GPU access in WSL:

1. Make sure you have NVIDIA drivers installed in Windows
2. Verify the GPU is accessible in WSL:

   ```bash
   nvidia-smi
   ```

3. Check that NVIDIA Container Toolkit is installed:

   ```bash
   sudo apt-get install -y nvidia-docker2
   sudo systemctl restart docker
   ```

### Docker Issues

If Docker is not working correctly in WSL:

1. Restart the Docker service:

   ```bash
   sudo service docker start
   ```

2. Verify Docker is running:

   ```bash
   docker info
   ```

### Path or Permission Issues

If you encounter path or permission issues:

1. Make sure you're working within the WSL filesystem (not Windows-mounted paths)
2. Check file permissions and make scripts executable:

   ```bash
   chmod +x scripts/*.sh
   ```

## Accessing the Services

Once everything is running, you can access the services at:

- Frontend: <http://localhost:8501>
- Backend API: <http://localhost:8000>
- ML Service: <http://localhost:5000>
- Jupyter Lab: <http://localhost:8888>
- Ollama API: <http://localhost:11434>

## Additional Resources

- [WSL Setup Guide](./docs/WSL_SETUP.md) - Detailed WSL configuration
- [Cross-Platform Development](./docs/CROSS_PLATFORM_DEVELOPMENT.md) - Tips for cross-platform work
- [Ollama Model Testing](./docs/OLLAMA_MODEL_TESTING.md) - Testing the Ollama model
