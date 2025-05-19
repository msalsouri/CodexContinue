# CodexContinue Development Environment Setup

This guide will help you get started with the CodexContinue development environment.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- [VS Code](https://code.visualstudio.com/)
- [VS Code Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## Quick Start

The easiest way to get started is using VS Code's Remote Containers feature:

1. Open VS Code
2. Open this folder in VS Code
3. Click on the Remote Containers icon in the bottom left corner
4. Select "Reopen in Container"

VS Code will build and start the development containers, then connect to the frontend service.

## Project Structure

```
CodexContinue/
├── .devcontainer/         # VS Code Remote Container configuration
├── app/                   # Core application code
├── backend/               # Backend API service
├── config/                # Configuration files
├── docker/                # Dockerfile definitions
├── docs/                  # Documentation
├── frontend/              # Frontend UI (Streamlit)
├── ml/                    # Machine Learning service
├── notebooks/             # Jupyter notebooks
└── scripts/               # Utility scripts
```

## Manual Development

If you prefer not to use VS Code's Remote Containers, you can manually start the development environment:

```bash
# Start the development environment
./scripts/start-dev-environment.sh

# Access the services:
# - Frontend: http://localhost:8501
# - Backend API: http://localhost:8000
# - ML Service: http://localhost:5000
# - Jupyter Lab: http://localhost:8888
```

## Jupyter Notebook Environment

CodexContinue includes a fully-configured Jupyter notebook environment for data exploration and model development:

```bash
# Launch Jupyter Lab and open it in your browser
./scripts/launch-jupyter.sh

# Verify the Jupyter environment is correctly configured
./scripts/verify-jupyter.sh
```

Available notebooks:

- `demo.ipynb` - A basic demonstration notebook
- `data_analysis.ipynb` - A comprehensive data analysis example

Notebook outputs can be saved to the `notebooks/exports` directory, which is accessible from both the container and your host machine.

## Troubleshooting

If you encounter issues with the development containers:

1. Run the diagnostics script:

   ```bash
   ./scripts/fix-devcontainer.sh
   ```

2. Clean up Docker resources:

   ```bash
   ./scripts/docker-cleanup.sh
   ```

3. Try rebuilding the containers:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
   ```

## Cross-Platform Development

CodexContinue supports development across different platforms:

### macOS Development

For macOS development without GPU support:

```bash
# Start Ollama without GPU requirements
./scripts/start-ollama-macos.sh

# Start the rest of the development environment
./scripts/start-dev-environment.sh
```

### Windows Development with GPU

For Windows systems with NVIDIA GPUs:

```bash
# Start full environment with GPU support
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

See [CROSS_PLATFORM_DEVELOPMENT.md](docs/CROSS_PLATFORM_DEVELOPMENT.md) and [WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md) for detailed instructions on setting up and developing across platforms.

### Git Repository Management

To set up a remote Git repository for cross-platform work:

```bash
# Configure the remote repository connection
./scripts/setup-git-remote.sh
```

This helps you move code between macOS and Windows environments efficiently.

## Documentation

See the `docs/` directory for more detailed documentation on:

- Architecture (`ARCHITECTURE.md`)
- Container Implementation (`CONTAINER_IMPLEMENTATION.md`)
- Containerization Strategy (`CONTAINERIZATION_STRATEGY.md`)
- Development Log (`DEVELOPMENT_LOG.md`)
- Docker Setup (`DOCKER.md`)

## Summary of Fixes

The development environment has been updated to fix several issues:

1. **Workspace Path Consistency** - All paths now use `/app` as the base directory
2. **Volume Mounting** - Improved volume mapping for all services
3. **Requirements Files** - Corrected paths for requirements installation
4. **Jupyter Integration** - Enhanced notebook environment with example notebooks
5. **Helper Scripts** - Added diagnostic and utility scripts

See `docs/DEVCONTAINER_FIX_SUMMARY.md` for a detailed list of changes.
