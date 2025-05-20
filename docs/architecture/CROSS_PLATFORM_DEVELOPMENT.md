# Cross-Platform Development for CodexContinue

This document explains how to work with CodexContinue across different platforms, specifically moving between macOS and Windows environments.

## Platform-Specific Configurations

### Windows with GPU Support

Windows with NVIDIA GPU capabilities can utilize full GPU acceleration for the Ollama service using either:

1. **Native Windows with Docker Desktop**:

   ```bash
   # Start the full environment with GPU support
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

2. **Windows Subsystem for Linux (WSL)** (Recommended):

   ```bash
   # Quick setup script for WSL 
   ./scripts/wsl-quick-setup.sh
   
   # OR start just the Ollama service with GPU support
   ./scripts/start-ollama-wsl.sh
   
   # Then start other services as needed
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

   Using WSL generally provides better GPU integration and performance with Docker. See [WINDOWS_WSL_GUIDE.md](WINDOWS_WSL_GUIDE.md) for detailed instructions.

The standard `docker-compose.yml` includes GPU configuration for Ollama:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

### macOS (CPU-only)

Since macOS doesn't support the same GPU integration, we've created a modified configuration:

```bash
# Start the Ollama service in CPU-only mode
./scripts/start-ollama-macos.sh

# Start the rest of the environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

This uses the `docker-compose.macos.yml` which removes GPU requirements for Ollama.

## Git Repository Setup for Cross-Platform Work

To effectively move between platforms:

1. Create a remote Git repository on GitHub or another hosting service

2. Use our helper script to set up the remote connection:

   ```bash
   ./scripts/setup-git-remote.sh
   ```

3. Before switching platforms, commit and push your changes:

   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

4. On your other platform (e.g., Windows), clone the repository:

   ```bash
   git clone https://github.com/your-username/CodexContinue.git
   cd CodexContinue
   ```

5. Start the environment with the appropriate configuration for that platform

## Ollama Model Configuration

The Ollama model works on both platforms but performs faster with GPU acceleration on Windows:

* Both platforms use the same Modelfile at `ml/models/ollama/Modelfile`
* The model is built using the same script on both platforms: `ml/scripts/build_codexcontinue_model.sh`
* Model weights are stored in a Docker volume, so they're isolated to each platform instance

## Development Workflow

A typical cross-platform workflow might look like:

1. Develop and test initial features on macOS
2. Push changes to GitHub
3. Clone on Windows for performance-intensive tasks utilizing GPU
4. Make additional changes on Windows
5. Push back to GitHub
6. Pull latest changes on macOS

## Troubleshooting

### Windows WSL Issues

If you're having issues with GPU access in WSL:

```bash
# Run the GPU troubleshooting script
./scripts/troubleshoot-wsl-gpu.sh
```

This script will diagnose common GPU issues in WSL and provide fix recommendations.

### General Issues

If you encounter issues when moving between platforms:

* Check Docker configuration for each platform
* Verify Ollama model was built correctly (run `./scripts/check_ollama_model.sh`)
* Ensure the latest code is pulled from the remote repository
* Docker volumes might need to be recreated when switching platforms
