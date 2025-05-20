# 🐳 Docker Architecture for CodexContinue

This document describes the Docker-based architecture for the CodexContinue project.

## 📋 Overview

CodexContinue uses a containerized microservices architecture with Docker and Docker Compose. The system is designed to:

1. Provide a consistent development environment
2. Enable easy scalability of individual components
3. Simplify deployment across different environments
4. Support both development and production workflows

## 🏗️ Container Structure

### Base Services

- **Backend**: FastAPI-based REST API service
- **Frontend**: Streamlit-based user interface
- **ML Service**: Machine learning service with LLM integration 
- **Redis**: In-memory data store for caching and messaging
- **Ollama**: Local LLM service for privacy-focused AI capabilities

### Development Services

In development mode, additional services are available:

- **Jupyter**: JupyterLab environment for ML experimentation

## 📄 Configuration Files

- `docker-compose.yml`: Base configuration shared by all environments
- `docker-compose.dev.yml`: Development-specific configuration (hot-reloading, debugging)
- `docker-compose.prod.yml`: Production-specific configuration (optimized, scaled)

## 🛠️ Dockerfile Structure

Each service has its own Dockerfile with multi-stage builds:

1. **Base stage**: Common dependencies and setup
2. **Development stage**: Development-specific tools and configuration
3. **Production stage**: Optimized for production use

### Example Dockerfile Structure:

```dockerfile
# Base stage with common dependencies
FROM python:3.10-slim as base
...

# Development stage
FROM base as development
...

# Production stage
FROM base as production
...
```

## 🚀 Usage

### Development Environment

```bash
# Start the development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Start just one service
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up backend
```

### Production Environment

```bash
# Build production images
./scripts/docker-build.sh prod build

# Start the production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Building Images

We provide a utility script for building Docker images:

```bash
# Build all development images
./scripts/docker-build.sh dev build

# Build a specific service's production image
./scripts/docker-build.sh prod build:ml
```

## 📊 Resource Management

### Resource Allocation

- **Development**: Default resource allocation
- **Production**: Configurable resource limits per service

### GPU Support

The ML service and Ollama containers can leverage GPU acceleration when available:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## 🔄 Data Persistence

Docker volumes are used for persisting data:

- `redis-data`: Redis data
- `ollama-data`: Ollama models and data

## 🛡️ Security Considerations

- Non-root users in all containers
- Minimal base images
- Only required ports exposed
- Secrets management via environment variables or Docker secrets

## 📚 Best Practices

1. **Keep containers small**: Use multi-stage builds and .dockerignore
2. **Use specific versions**: Pin dependency versions for reproducibility
3. **Health checks**: Implement health checks for all services
4. **Resource limits**: Set appropriate memory and CPU limits
5. **Leverage caching**: Structure Dockerfiles to maximize build cache usage
6. **Separate environments**: Use different compose files for different environments

## 🔍 Troubleshooting

### Common Issues

1. **Container networking issues**:
   - Check network configuration in docker-compose files
   - Verify service names are correct in environment variables

2. **Volume permission issues**:
   - Ensure correct ownership of mounted directories
   - Use non-root users with appropriate permissions

3. **Build failures**:
   - Check Dockerfile syntax
   - Verify dependencies are available

### Logging

All containers output logs to stdout/stderr, which can be viewed with:

```bash
docker-compose logs [service_name]
```

### Health Checks

Monitor container health with:

```bash
docker ps
```

Look for the `STATUS` column to see which containers are healthy.
