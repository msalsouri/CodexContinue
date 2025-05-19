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

- `app/`: Shared code and utilities
- `backend/`: FastAPI backend service
- `frontend/`: Streamlit frontend service
- `ml/`: Machine learning service
- `docker/`: Docker configuration files
- `scripts/`: Utility scripts
- `config/`: Configuration files
- `docs/`: Documentation

## 🔄 Development Workflow

### Branching Strategy

- `main`: Stable release branch
- `develop`: Development branch for integration
- Feature branches: `feature/your-feature-name`
- Bug fix branches: `bugfix/issue-description`
- Release branches: `release/vX.Y.Z`

### Creating a New Feature

1. Create a new branch from `develop`:

```bash
git checkout develop
git pull
git checkout -b feature/your-feature-name
```

2. Implement your changes, following the code style and conventions.

3. Add tests for your changes.

4. Submit a pull request to the `develop` branch.

### Pull Request Process

1. Update the documentation to reflect any changes.
2. Add or update tests as necessary.
3. Ensure all CI checks pass.
4. Request review from at least one maintainer.
5. Address any feedback from reviewers.

## 🧪 Testing

### Running Tests

```bash
# Run tests for a specific service
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm backend pytest

# Run tests with coverage
docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm backend pytest --cov=app
```

### Testing Guidelines

- Write unit tests for all new functionality.
- Aim for at least 80% code coverage.
- Test edge cases and error scenarios.
- Mock external dependencies.

## 📝 Code Style

This project follows PEP 8 for Python code style with the following tools:

- **Black**: Code formatting
- **Flake8**: Code linting
- **isort**: Import sorting
- **mypy**: Type checking

### Pre-commit Hooks

We use pre-commit hooks to ensure code quality. Install them with:

```bash
pip install pre-commit
pre-commit install
```

## 📚 Documentation

- Use docstrings for all functions, classes, and modules.
- Follow Google-style docstring format.
- Keep the documentation in `docs/` up to date.
- Use meaningful variable and function names.

## 🚀 Releasing

1. Create a release branch:

```bash
git checkout develop
git checkout -b release/vX.Y.Z
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

## 🤝 Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing to the project.

## ❓ Questions and Support

If you have questions or need support, please:

1. Check the [documentation](docs/).
2. Search for existing issues.
3. Create a new issue if necessary.

Thank you for contributing to CodexContinue!
