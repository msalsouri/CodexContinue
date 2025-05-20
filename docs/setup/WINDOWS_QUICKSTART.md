# Windows Development Quick Start

Follow these steps to get CodexContinue running on your Windows system with GPU support:

## 1. Clone the Repository

```bash
# Clone the repository from GitHub
git clone https://github.com/your-username/CodexContinue.git
cd CodexContinue
```

## 2. Install Prerequisites

Ensure you have:

- Docker Desktop for Windows with WSL 2 backend
- NVIDIA GPU drivers installed
- NVIDIA Container Toolkit (nvidia-docker)

For detailed setup instructions, see [WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md).

## 3. Verify GPU Support

```bash
# Check that NVIDIA drivers are working
nvidia-smi

# Verify that NVIDIA Docker integration works
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

## 4. Start the Environment

```bash
# Start the development environment with GPU support
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## 5. Build the Ollama Model

```bash
# Check if the model is built
./scripts/check_ollama_model.sh

# If needed, build the model manually
docker exec codexcontinue-ml-service-1 bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh"
```

## 6. Access the Services

- **Frontend**: <http://localhost:8501>
- **Backend API**: <http://localhost:8000>
- **ML Service**: <http://localhost:5000>
- **Jupyter Lab**: <http://localhost:8888>

## 7. Development Workflow

Make your changes, then commit and push back to the repository:

```bash
git add .
git commit -m "Description of your changes"
git push
```

## 8. Troubleshooting

If you encounter issues:

1. Check the logs: `docker compose logs`
2. Run diagnostics: `./scripts/fix-devcontainer.sh`
3. Verify GPU access: `docker exec codexcontinue-ollama-1 nvidia-smi`

For more detailed information, refer to:

- [WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md)
- [CROSS_PLATFORM_DEVELOPMENT.md](docs/CROSS_PLATFORM_DEVELOPMENT.md)
- [DEVCONTAINER_TROUBLESHOOTING.md](docs/DEVCONTAINER_TROUBLESHOOTING.md)
