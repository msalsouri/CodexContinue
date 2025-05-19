# Development container configuration for the CodexContinue project
# Use this file to develop inside a container with VS Code

FROM python:3.10-slim as devcontainer

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    git \
    bash \
    build-essential \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Python setup
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create a non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

# Install development tools
RUN pip install --no-cache-dir \
    black \
    flake8 \
    pytest \
    pytest-cov \
    ipython \
    debugpy

# Switch to non-root user
USER appuser

# We don't need a specific command here since VS Code handles that
# through the devcontainer.json configuration
