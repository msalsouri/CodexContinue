# Contributing to CodexContinue

Thank you for your interest in contributing to CodexContinue! This document provides guidelines and instructions for contributing to the project.

## 🌱 Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.10+
- Git

### Setting Up the Development Environment

1. Clone the repository:

```bash
git clone https://github.com/yourusername/CodexContinue.git
cd CodexContinue
```

2. Initialize the project structure:

```bash
./scripts/init-project.sh
```

3. Start the development environment:

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

## 🏗️ Project Structure

The project follows a modular microservices architecture:

- `backend/`: FastAPI backend service
- `frontend/`: Streamlit frontend service
- `ml/`: Machine learning service with NLP capabilities
- `docker/`: Docker configuration files
- `scripts/`: Utility scripts
- `docs/`: Documentation
- `data/`: Persistent data storage (knowledge base, vector store)
- `notebooks/`: Jupyter notebooks for experimentation

## 🔄 Development Workflow

We use a feature branch workflow. For detailed instructions, see [DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md).

### Branching Strategy

- `main`: Stable, production-ready code
- Feature branches: `feature/your-feature-name`

### Creating a New Feature

1. Create a new branch from `main`:

```bash
git checkout main
git pull
git checkout -b feature/your-feature-name
```

2. Implement your changes, following the code style and conventions.

3. Run the diagnostic and cleanup scripts:

```bash
./scripts/diagnose-services.sh
./scripts/cleanup-root-files.sh
```

4. Submit a pull request to the `main` branch.

### Pull Request Process

1. Update the documentation to reflect any changes.
2. Add or update tests as necessary.
3. Ensure all CI checks pass.
4. Request review from at least one maintainer.
5. Address any feedback from reviewers.

## 🧪 Testing

### Running Tests

```bash
# Run tests for the ML service
./scripts/run-transcription-tests.sh

# Run specific test file
docker compose exec ml-service python -m pytest tests/test_youtube_transcriber.py
```

### Testing Guidelines

- Write unit tests for all new functionality.
- Aim for at least 80% code coverage.
- Test edge cases and error scenarios.
- Mock external dependencies when necessary.

## 📝 Code Style

This project follows PEP 8 for Python code style with the following tools:

- **Black**: Code formatting
- **Flake8**: Code linting
- **isort**: Import sorting

## 📚 Documentation

- Use docstrings for all functions, classes, and modules.
- Follow Google-style docstring format.
- Keep the documentation in `docs/` up to date.
- Use meaningful variable and function names.

## 🚀 Releasing

1. Create a release branch:

```bash
git checkout main
git checkout -b feature/release-vX.Y.Z
```

2. Update version numbers and changelog.

3. Submit a pull request to `main`.

4. After merging, tag the release:

```bash
git checkout main
git pull
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

## ❓ Troubleshooting

If you encounter issues during development:

1. Check the [troubleshooting guide](docs/troubleshooting-guide.md).
2. Run the diagnostic script: `./scripts/diagnose-services.sh`
3. Search for existing issues in the GitHub repository.
4. Create a new issue with detailed information if the problem persists.

Thank you for contributing to CodexContinue!
