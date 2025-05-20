# WSL NVIDIA GPU Setup for CodexContinue

This document outlines the steps taken to configure NVIDIA GPU support in WSL for the CodexContinue project.

## Current Status

- ✅ NVIDIA drivers are installed and functioning in WSL
- ✅ NVIDIA libraries are configured in the standard WSL location
- ✅ NVIDIA Container Toolkit is installed and configured
- ✅ Docker is configured with NVIDIA runtime support
- ✅ GPU acceleration is available to containers
- ✅ Shell warnings related to Docker/NVIDIA have been fixed

## Steps Completed

1. Verified the NVIDIA driver is installed using `nvidia-smi`
2. Fixed missing library symbolic links in `/usr/lib/wsl/lib/` using `fix-nvidia-wsl-libs.sh`
3. Verified Docker integration with NVIDIA GPU
4. Created documentation and diagnostic tools
5. Fixed shell warnings related to Docker feedback plugin and duplicate NVM entries

## Troubleshooting

If you encounter shell warnings, please refer to:
- [Shell Warnings Fix](../troubleshooting/SHELL_WARNINGS_FIX.md) - Comprehensive guide to fix common shell warnings

You can also run our automatic shell warnings diagnostic and fix script:
```bash
cd ~/Projects/CodexContinue
./scripts/check-shell-warnings.sh
```

## Useful Commands

### Check GPU Status
```bash
nvidia-smi
```

### Verify Docker GPU Integration
```bash
docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
```

### Start Ollama with GPU Support
```bash
./scripts/start-ollama-wsl.sh
```

### Start CodexContinue with GPU Support
```bash
docker compose -f docker-compose.yml up
```

### Start CodexContinue without GPU Support (Fallback)
```bash
docker compose -f docker-compose.yml -f docker-compose.macos.yml up
```

## Troubleshooting Scripts

The following scripts are available to diagnose and fix issues:

- `scripts/verify-nvidia-wsl.sh` - Checks NVIDIA driver setup in WSL
- `scripts/fix-nvidia-wsl-libs.sh` - Fixes NVIDIA library symlinks in WSL
- `scripts/fix-nvidia-docker-wsl.sh` - Configures Docker to use NVIDIA runtime
- `scripts/manage-ollama-process.sh` - Manages Ollama processes and fixes port conflicts
- `scripts/troubleshoot-wsl-gpu.sh` - Comprehensive GPU troubleshooting script

## Common Issues

### Shell Warnings

If you notice warnings in the top-left corner of your terminal, refer to:
- [Shell Warnings Fix](../troubleshooting/SHELL_WARNINGS_FIX.md)

These are typically related to Docker configuration or missing Docker plugins and can be safely fixed.

### Docker Errors
