# 🚀 CodexContinue

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109.0-green)](https://fastapi.tiangolo.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.30.0-red)](https://streamlit.io/)

A powerful, modular AI development assistant with memory and multi-model support. Built for professional developers who need a versatile AI assistant with local-first capabilities and enterprise-grade features.

## 🧠 Learning Capabilities

CodexContinue features built-in learning capabilities through:

1. **Custom Ollama Models**: Specialized models for software development tasks
2. **Domain Adaptation**: Ability to customize the system for specific domains
3. **Model Customization**: Flexible model configuration via Modelfile
4. **Knowledge Integration**: Easy integration of new knowledge and capabilities

The system uses a custom CodexContinue model built on Llama3, specifically designed for software development tasks with:
- Expanded code generation capabilities
- Technical problem-solving expertise
- Advanced reasoning for development workflows
- Domain-specific knowledge (through customizable models)

See [DOMAIN_CUSTOMIZATION.md](docs/DOMAIN_CUSTOMIZATION.md) for information on adapting the system to specific domains.

## 🏛️ Architecture

CodexContinue follows a modern containerized microservices architecture that ensures:

1. **Modularity**: Each component is isolated and independently deployable
2. **Scalability**: Services can be scaled based on demand
3. **Maintainability**: Well-defined interfaces between components
4. **Flexibility**: Easy to add new capabilities or replace existing ones

The system consists of these core services:

- **Backend API**: FastAPI-based REST API handling business logic
- **Frontend UI**: Streamlit-based user interface
- **ML Service**: Machine learning service with LLM integration
- **Redis**: In-memory data store for caching and messaging
- **Ollama**: Local LLM service for privacy-focused AI capabilities

## 🚀 Quick Start

### Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/CodexContinue.git
cd CodexContinue

# Start the development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Production Environment

```bash
# Build production images
./scripts/docker-build.sh prod build

# Start the production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🛠️ Development

### Prerequisites

- Docker and Docker Compose
- Python 3.10+
- Git

### Project Structure

```
.
├── app/            # Primary application code directory
├── backend/        # Backend API service
├── config/         # Configuration files
├── docker/         # Docker configuration for all services
├── docs/           # Documentation
├── frontend/       # Frontend UI service
├── ml/             # Machine learning service
├── scripts/        # Utility scripts
└── docker-compose.yml  # Base docker-compose configuration
```

### Setup a New Service

We provide a convenience script to set up a new service with the recommended structure:

```bash
# Create a basic service
./scripts/setup-service.sh myservice

# Create a FastAPI-based service
./scripts/setup-service.sh myservice fastapi

# Create an ML-focused service
./scripts/setup-service.sh myservice ml
```

## 🧠 Domain-Specific Customization

CodexContinue can be customized for different domains:

### 🏥 Health Domain
- Medical data processing
- Healthcare-focused UI
- Medical terminology integration

### ⚖️ Legal Domain
- Legal document processing
- Case management
- Legal research capabilities

### 💰 Finance Domain
- Financial data analysis
- Market trend visualization
- Investment planning tools

### 👩‍💻 Developer Domain
- Code generation and analysis
- Project scaffolding
- Documentation assistance

## 📚 Documentation

For more detailed documentation on each component:

- [Backend API Documentation](docs/backend.md)
- [Frontend UI Guide](docs/frontend.md)
- [ML Service Documentation](docs/ml.md)
- [Deployment Guide](docs/deployment.md)
- [Developer Guide](docs/developer.md)

## 🤝 Contributing

Contributions are welcome! Please check out our [Contributing Guide](CONTRIBUTING.md).

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🔄 Cross-Platform Development

CodexContinue is designed to work across different platforms:

### Windows with GPU Support

For development on Windows with GPU capability:

```bash
# Start the full environment with GPU support
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### macOS (CPU-only)

For development on macOS without GPU capability:

```bash
# Start the Ollama service in CPU-only mode
./scripts/start-ollama-macos.sh

# Start the rest of the environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Git Repository Setup

To move between platforms:

1. Set up a remote Git repository:

```bash
./scripts/setup-git-remote.sh
```

2. Push your changes before switching platforms:

```bash
git add .
git commit -m "Your commit message"
git push
```

3. On the other platform, clone the repository:

```bash
git clone https://github.com/your-username/CodexContinue.git
cd CodexContinue
```
