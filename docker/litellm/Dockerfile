FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install LiteLLM
RUN pip install --no-cache-dir litellm==1.10.3 gunicorn

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0

# Create a non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set proper permissions
RUN chown -R appuser:appuser /app

# Use non-root user
USER appuser

# Expose port
EXPOSE 8000

# Command to run the application
ENTRYPOINT ["/app/entrypoint.sh"]
