# Docker Troubleshooting for Linux/WSL Environments

This guide addresses common issues with running CodexContinue Docker containers in Linux and Windows Subsystem for Linux (WSL) environments.

## Known Issues and Solutions

### 1. Flask ML Service Not Starting

**Issue**: The ML service container fails to start because Flask is not explicitly installed in the Docker image.

**Solution**: We've updated the Dockerfile to explicitly install Flask and Gunicorn:

```dockerfile
# Make sure flask and essential packages are explicitly installed
RUN pip install flask==2.3.0 gunicorn==21.2.0
```

### 2. Frontend Service Path Issues

**Issue**: The Streamlit frontend service cannot find the app.py file due to incorrect path in the Docker configuration.

**Solution**: The docker-compose.dev.yml file has been updated to use the correct path:

```yaml
command: ["streamlit", "run", "frontend/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

### 3. Service Accessibility

**Issue**: Services running in Docker containers may not be accessible from the host machine.

**Solution**: Use the provided test scripts to verify service accessibility:

- `scripts/check-service-access.py`: Python script to check all service endpoints
- `scripts/test-codexcontinue-ports.sh`: Bash script to test port availability and service responses

## Running Individual Services

### Running ML Service Independently

If you need to run the ML service independently from other services, we've created a custom script:

```bash
./scripts/start-ml-service.sh
```

This script will:
1. Build a custom Docker image for the ML service
2. Configure it to connect to Ollama running on the host
3. Start the service on port 5000

## Checking Service Accessibility

To verify that all services are accessible, run:

```bash
# Using the Python script
python3 scripts/check-service-access.py

# Or using the Bash script
./scripts/test-codexcontinue-ports.sh
```

The Python script will check each service endpoint and display response status, while the Bash script provides more detailed information about port usage and service responses.

## Troubleshooting Tips

1. **Docker Network Issues**: If services can't communicate with each other, ensure they're on the same Docker network:
   ```bash
   docker network ls
   docker network inspect codexcontinue_codexcontinue-network
   ```

2. **Port Conflicts**: If you see "address already in use" errors, check for processes using the ports:
   ```bash
   sudo lsof -i :8000   # Backend
   sudo lsof -i :8501   # Frontend
   sudo lsof -i :5000   # ML Service
   sudo lsof -i :11434  # Ollama
   ```

3. **Container Logs**: Check container logs for detailed error information:
   ```bash
   docker logs codexcontinue-backend
   docker logs codexcontinue-frontend
   docker logs codexcontinue-ml-service
   docker logs codexcontinue-ollama
   ```

## Further Assistance

If you continue to experience issues with Docker containers in Linux/WSL environments, please:
1. Check the GitHub issues for similar problems
2. Run `docker-compose logs` to get comprehensive logs
3. Include your OS version and Docker version when reporting issues
