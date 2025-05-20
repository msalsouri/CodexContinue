# AI Assistant Guide for CodexContinue Project

## Project Overview

CodexContinue is a cross-platform development project that integrates machine learning capabilities with a web application. The project is designed to run on both macOS and Windows (via WSL - Windows Subsystem for Linux) environments, with specific optimizations for each platform.

## Repository Structure

- `app/`: Core application code
- `backend/`: Backend API server built with FastAPI
- `frontend/`: Frontend web interface
- `ml/`: Machine learning components and model integration
- `docker/`: Docker configuration for containerized development
- `scripts/`: Utility scripts for setup, maintenance, and diagnostics
- `docs/`: Documentation for various aspects of the project
- `notebooks/`: Jupyter notebooks for data analysis and demonstrations

## Current Development Context

You are assisting with the cross-platform setup of CodexContinue, specifically focusing on:

1. **Windows WSL Development Environment**: Setting up the development environment in Windows Subsystem for Linux with GPU support for machine learning components
2. **DevContainer Configuration**: Ensuring proper DevContainer configuration across platforms
3. **Ollama Integration**: Configuring Ollama (a large language model server) to run properly with GPU acceleration in WSL

## Key Files and Directories

### Configuration Files

- `.devcontainer/`: Contains DevContainer configuration
- `docker-compose.yml`: Main Docker Compose configuration
- `docker-compose.macos.yml`: macOS-specific Docker Compose overrides (CPU-only for Ollama)
- `docker-compose.dev.yml`: Development environment Docker Compose configuration

### Documentation

- `docs/WINDOWS_WSL_GUIDE.md`: Guide for setting up the project in WSL
- `docs/DEVCONTAINER_TROUBLESHOOTING.md`: Troubleshooting for DevContainer issues
- `docs/DEVCONTAINER_VOLUME_MOUNT_FIX.md`: Solutions for volume mounting issues in WSL

### Scripts

- `scripts/fix-devcontainer.sh`: Script to fix DevContainer configuration issues
- `scripts/wsl-quick-setup.sh`: Quick setup script for WSL environment
- `scripts/start-ollama-wsl.sh`: Script to start Ollama in WSL with GPU support
- `scripts/check-platform.sh`: Verify environment configuration

### Machine Learning

- `ml/models/ollama/`: Ollama model configuration
- `ml/scripts/build_codexcontinue_model.sh`: Script to build the custom model

## Development Workflow

1. **Repository Setup**: The project is maintained in a Git repository with coordination between macOS and Windows environments
2. **Container-Based Development**: Development is primarily done in Docker containers via VS Code DevContainers
3. **Platform-Specific Configurations**:
   - macOS uses CPU-only mode for Ollama
   - Windows (WSL) uses GPU acceleration for Ollama

## Recent Changes

Recent work has focused on:

1. Adding WSL support with GPU acceleration
2. Fixing DevContainer configurations for cross-platform compatibility
3. Creating documentation and scripts for smoother onboarding

## Current Status

The project has been successfully:

1. Set up on macOS
2. Configured for Windows WSL development
3. Fixed for DevContainer issues between platforms

The user is now at the stage of verifying the GPU integration with Ollama in the WSL environment.

## Common Issues and Solutions

1. **Volume Mount Issues in WSL**: Fixed by using relative paths instead of `${localWorkspaceFolder}`
2. **GPU Integration in WSL**: Requires proper NVIDIA driver installation and container toolkit setup
3. **Cross-Platform Development**: Docker volumes are platform-specific, so models need to be built separately on each platform

## Next Steps

1. Verify GPU support in WSL for Ollama
2. Test the full application stack
3. Continue development across both platforms

## Terminology

- **WSL**: Windows Subsystem for Linux
- **DevContainer**: Development containers for VS Code
- **Ollama**: Self-hosted large language model server
- **CodexContinue**: The project name, referring to an AI-assisted coding and documentation tool
- **Docker**: Containerization platform used for development and deployment
- **GPU**: Graphics Processing Unit, used for accelerating machine learning tasks
- **NVIDIA**: Manufacturer of GPUs, relevant for WSL GPU support
- **FastAPI**: Web framework for building APIs with Python
- **Docker Compose**: Tool for defining and running multi-container Docker applications
- **Jupyter Notebooks**: Interactive notebooks for data analysis and visualization
- **Volume Mounting**: The process of linking directories between the host and container
- **Cross-Platform Development**: Developing software that runs on multiple operating systems
- **Containerization**: The practice of packaging software into containers for consistent deployment
- **Machine Learning**: A subset of AI focused on building systems that learn from data
- **Model Integration**: The process of incorporating machine learning models into applications
- **API**: Application Programming Interface, a set of rules for building software applications
- **Frontend**: The user interface of the application
- **Backend**: The server-side logic and database interactions of the application
- **Dockerfile**: A script containing instructions to build a Docker image
- **Image**: A lightweight, standalone, executable package that includes everything needed to run a piece of software
- **Container**: A standard unit of software that packages up code and all its dependencies