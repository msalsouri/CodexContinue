# Container Architecture Implementation Guide

## Overview

This document provides detailed technical information on implementing and extending the containerized architecture of CodexContinue. It should be used in conjunction with the main architecture and containerization documents to understand the full system implementation.

## Docker Implementation Details

### Multi-stage Dockerfile Structure

Each service in CodexContinue uses a multi-stage Dockerfile approach with the following structure:

#### Backend Service Example

```dockerfile
# Base stage with common dependencies
FROM python:3.10-slim as base

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Development stage
FROM base as development

# Install development tools
RUN pip install --no-cache-dir pytest pytest-cov flake8 black isort debugpy

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBUG=true

# Use non-root user
USER appuser

# Command will be specified in docker-compose.dev.yml

# Production stage
FROM base as production

# Copy application code
COPY --chown=appuser:appuser . .

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBUG=false

# Use non-root user
USER appuser

# Command for production
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Docker Compose Configuration Inheritance

The Docker Compose configuration uses a layered approach:

1. **Base** (`docker-compose.yml`): Core service definitions
2. **Development** (`docker-compose.dev.yml`): Extends base for development
3. **Production** (`docker-compose.prod.yml`): Extends base for production

This structure allows for different configurations while maintaining a single source of truth for service definitions.

### Volume Management

#### Development Volumes

In development mode, code directories are mounted as volumes to enable hot-reloading:

```yaml
volumes:
  - ./backend:/app  # Mount source code for live development
```

#### Persistent Volumes

For data persistence:

```yaml
volumes:
  redis-data:  # Redis data persistence
  ollama-data: # Ollama models and configuration
```

#### Ollama Model Volumes

For Ollama integration, we have two critical volume mounts:

```yaml
volumes:
  - ollama-data:/root/.ollama  # For model weights and Ollama internal files
  - ./ml/models/ollama:/models/ollama  # For model definitions and Modelfile
```

This setup ensures:
1. The model definition files (like Modelfile) are accessible inside the container
2. Model weights and Ollama's internal data are persisted across container restarts
3. The ML service can access the models directory for building custom models

### Network Configuration

All services are connected via a bridge network:

```yaml
networks:
  codexcontinue-network:
    driver: bridge
```

Internal service discovery uses Docker's DNS system, allowing services to reference each other by name (e.g., `redis://redis:6379`).

## Service Implementation

### Backend Service (FastAPI)

#### Key Files:
- `/backend/app/main.py`: Entry point with FastAPI application
- `/backend/app/api/`: API route definitions
- `/backend/app/core/`: Core business logic
- `/backend/app/db/`: Database models and connections

#### Environment Variables:
- `REDIS_URL`: Connection string for Redis
- `DEBUG`: Enable/disable debug mode
- `LOG_LEVEL`: Logging verbosity

### Frontend Service (Streamlit)

#### Key Files:
- `/frontend/app.py`: Main Streamlit application
- `/frontend/pages/`: Additional UI pages
- `/frontend/components/`: Reusable UI components

#### Environment Variables:
- `BACKEND_URL`: URL for the backend API
- `ENVIRONMENT`: Current environment (development/production)

### ML Service (Flask/LLM)

#### Key Files:
- `/ml/app.py`: Flask application entry point
- `/ml/models/`: ML model definitions
- `/ml/utils/`: Utility functions for ML processing
- `/ml/models/ollama/Modelfile`: Definition for the CodexContinue custom model

#### Environment Variables:
- `OLLAMA_API_URL`: URL for Ollama API
- `DEBUG`: Enable/disable debug mode
- `LOG_LEVEL`: Logging verbosity

#### Ollama Model Integration:

The ML service integrates with Ollama for custom model capabilities:

1. **Model Definition**: The `ml/models/ollama/Modelfile` defines the CodexContinue model based on Llama3
2. **Model Building**: The `ml/scripts/build_codexcontinue_model.sh` script creates the model in Ollama
3. **Model Access**: The ML service connects to Ollama via its API at `http://ollama:11434`

During initialization, the `start-codexcontinue.sh` script:
1. Ensures the `ml/models/ollama` directory exists
2. Copies the Modelfile if it doesn't exist
3. Starts the containers
4. Builds the CodexContinue model in the Ollama container

This implementation allows for:
- Local LLM capabilities without external dependencies
- Customization of the model for domain-specific knowledge
- Learning capabilities through model updates

## Resource Management

### Memory and CPU Allocation

Production services have resource limits defined:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1g
```

### GPU Acceleration

For ML workloads, GPU resources can be allocated:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## Health Monitoring

Each service implements a health check endpoint:

- Backend: `/health`
- Frontend: `/healthz`
- ML Service: `/health`

Docker Compose uses these endpoints for container health monitoring:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Service Communication

Services communicate with each other via HTTP APIs:
- Frontend → Backend: REST API calls
- Backend → ML Service: REST API calls
- All services → Redis: Redis protocol

## Scaling Strategies

### Horizontal Scaling

In production, services can be horizontally scaled:

```yaml
deploy:
  replicas: 2
```

### Load Balancing

When running multiple replicas, Docker's built-in load balancing distributes traffic between containers.

## Security Considerations

### Non-root Users

All services run as non-root users for better security:

```dockerfile
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

USER appuser
```

### Network Security

Only necessary ports are exposed:

```yaml
ports:
  - "8000:8000"  # Expose only what's needed
```

### Secrets Management

Sensitive information is managed through environment variables:

```yaml
environment:
  - API_KEY=${API_KEY}
```

For production, consider using Docker secrets or a vault solution.

## Extending the Architecture

### Adding a New Service

1. Create a directory for the new service
2. Create a Dockerfile with multi-stage builds
3. Add service definition to `docker-compose.yml`
4. Add development overrides to `docker-compose.dev.yml`
5. Add production configuration to `docker-compose.prod.yml`

### Domain-Specific Customization

To customize for a specific domain:

1. Create a domain-specific Docker Compose override file (e.g., `docker-compose.healthcare.yml`)
2. Use specialized base images or model configurations
3. Add domain-specific environment variables
4. Include any additional services required for that domain

## Workflow Guide

### Development Workflow

```bash
# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Rebuild a specific service
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build frontend

# View logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend
```

### Testing Workflow

```bash
# Run tests for a specific service
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm backend pytest

# Run linting
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm backend flake8
```

### Production Deployment

```bash
# Build production images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Start production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Scale a service
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --scale backend=3
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Container fails to start

1. Check logs: `docker-compose logs <service_name>`
2. Verify environment variables are correctly set
3. Check for port conflicts

#### Volume permission issues

1. Ensure host directories have appropriate permissions
2. Check user IDs match between host and container

#### Inter-service communication issues

1. Verify service names in environment variables
2. Check network configuration
3. Ensure services are running: `docker-compose ps`

#### Performance issues

1. Check resource allocation
2. Monitor resource usage: `docker stats`
3. Consider scaling services or adjusting resource limits

## Conclusion

This implementation guide provides the technical details needed to understand, deploy, and extend the CodexContinue containerized architecture. Used alongside the other architecture documents, it forms a comprehensive guide to the system's design and implementation.
