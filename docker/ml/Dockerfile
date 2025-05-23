# Base image for all ML service environments
FROM python:3.12-slim AS base

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    build-essential \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Python setup
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    FFMPEG_LOCATION=/usr/bin

# Create a non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

# Development stage
FROM base AS development

# Copy requirements first for better caching
COPY ml/requirements.txt ./requirements.txt
RUN if [ -f ml/requirements-dev.txt ]; then cp ml/requirements-dev.txt ./requirements-dev.txt; fi
RUN pip install --no-cache-dir -r requirements.txt && \
    if [ -f requirements-dev.txt ]; then pip install --no-cache-dir -r requirements-dev.txt; fi

# Make sure flask and essential packages are explicitly installed
RUN pip install flask==2.3.0 flask-cors==4.0.0 gunicorn==21.2.0

# Set environment variables
ENV PYTHONPATH=/app
ENV DEBUG=true

# Command to run the application in development mode
CMD ["python", "/app/ml/app.py"]

# Production stage
FROM base AS production

# Copy and install production dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set proper permissions
RUN chown -R appuser:appuser /app

# Use non-root user
USER appuser

# Set environment variables
ENV PYTHONPATH=/app
ENV DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Command to run the application in production mode
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "120", "app:app"]
