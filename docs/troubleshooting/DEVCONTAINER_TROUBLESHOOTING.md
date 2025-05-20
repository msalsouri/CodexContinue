# Dev Container Troubleshooting Guide

This document provides troubleshooting steps for common issues with the VS Code Dev Container setup for CodexContinue.

## Common Issues and Solutions

### 1. Container fails to start or build

**Symptoms:**

- VS Code shows an error when trying to reopen in container
- Build process fails with errors

**Solutions:**

1. Check Docker is running:

   ```bash
   docker info
   ```

2. Clean up Docker resources:

   ```bash
   ./scripts/docker-cleanup.sh
   ```

3. Check for permission issues:

   ```bash
   ls -la .devcontainer
   ```

4. Try rebuilding with no cache:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
   ```

### 2. Cannot find Python packages

**Symptoms:**

- Import errors in Python code
- "Module not found" errors

**Solutions:**

1. Check that requirements files are being properly installed:

   ```bash
   docker compose exec frontend pip list
   docker compose exec backend pip list
   docker compose exec ml-service pip list
   ```

2. Manually install requirements:

   ```bash
   docker compose exec frontend pip install -r /app/frontend/requirements.txt
   docker compose exec backend pip install -r /app/backend/requirements.txt
   docker compose exec ml-service pip install -r /app/ml/requirements.txt
   ```

### 3. Volume mounting issues

**Symptoms:**

- Changes to local files not reflected in container
- "File not found" errors for files that exist locally

**Solutions:**

1. Check Docker volume mounts:

   ```bash
   docker compose config | grep volume -A 5
   ```

2. Restart VS Code

3. Try manually mounting the volume:

   ```bash
   docker compose down
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

### 4. Networking issues between services

**Symptoms:**

- Services cannot communicate with each other
- Connection refused errors

**Solutions:**

1. Check that all services are running:

   ```bash
   docker compose ps
   ```

2. Check the network configuration:

   ```bash
   docker network inspect codexcontinue_codexcontinue-network
   ```

3. Test connectivity between containers:

   ```bash
   docker compose exec frontend ping backend
   docker compose exec backend ping redis
   ```

## Advanced Troubleshooting

### Diagnostic logs

To get more detailed logs:

```bash
# View logs from all services
docker compose logs

# View logs from a specific service
docker compose logs frontend

# Follow logs in real-time
docker compose logs -f
```

### Container inspection

To inspect a running container:

```bash
# Get a shell in a container
docker compose exec frontend bash

# Check the file system
docker compose exec frontend ls -la /app

# Check environment variables
docker compose exec frontend env
```

### VSCode specific issues

1. Check that the Remote Containers extension is installed and up to date
2. Try reloading the window: Ctrl+Shift+P > Developer: Reload Window
3. Check VS Code logs: View > Output > Remote-Containers

If all else fails, you can completely reset the VS Code devcontainer:

1. Close VS Code
2. Delete the `.devcontainer/.persistence` folder if it exists
3. Run `docker compose down -v` to remove all containers and volumes
4. Reopen VS Code and try again
