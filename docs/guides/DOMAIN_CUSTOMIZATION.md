# Domain-Specific Customization Guide

This document explains how to customize the CodexContinue system for specific domains using the containerized architecture.

## Overview

CodexContinue can be customized for different domains such as healthcare, finance, legal, education, etc. by:

1. Creating domain-specific models with Ollama
2. Adjusting configuration settings
3. Adding domain-specific components
4. Customizing the user interface

## Creating Domain-Specific Models

### Custom Ollama Models

You can create domain-specific models by customizing the Modelfile:

1. Create a new Modelfile in the `ml/models/ollama` directory:

```bash
cp ml/models/ollama/Modelfile ml/models/ollama/Modelfile.healthcare
```

2. Edit the new Modelfile to customize the system prompt:

```
FROM llama3
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 8192

# Model metadata
SYSTEM """
You are CodexContinue Healthcare, an AI assistant specialized in healthcare software development and medical informatics.

Focus areas:
- Medical terminology and healthcare standards (HL7, FHIR, DICOM)
- Healthcare data processing and analysis
- Compliance with healthcare regulations (HIPAA, GDPR)
- Electronic Health Record (EHR) systems integration
- Medical research and clinical trials software

Key capabilities:
1. Generate healthcare-compliant code solutions
2. Explain medical informatics concepts clearly
3. Debug issues in healthcare software
4. Suggest architecture for healthcare applications
5. Integrate with healthcare data models

Always provide practical, working solutions with proper security and privacy considerations for healthcare data.
"""

# Template for consistent responses
TEMPLATE """
{{- if .System }}
SYSTEM: {{ .System }}
{{- end }}

{{- range .Messages }}
{{ .Role }}: {{ .Content }}
{{- end }}

A: 
"""
```

3. Build the domain-specific model using the custom model script:

```bash
# Create a new build script for the domain-specific model
cp ml/scripts/build_codexcontinue_model.sh ml/scripts/build_healthcare_model.sh
```

4. Edit the new script to use the domain-specific Modelfile:

```bash
#!/bin/bash
set -e

# Configuration
OLLAMA_API_URL=${OLLAMA_API_URL:-http://ollama:11434}
MODEL_NAME="codexcontinue-healthcare"
MODELFILE_PATH="/app/ml/models/ollama/Modelfile.healthcare"

echo "Building the CodexContinue Healthcare model..."
echo "Ollama API URL: ${OLLAMA_API_URL}"

# Check if Ollama is accessible
echo "Testing connection to Ollama..."
curl -s ${OLLAMA_API_URL}/api/tags > /dev/null || {
    echo "Error: Could not connect to Ollama at ${OLLAMA_API_URL}"
    exit 1
}

# Build the model
echo "Creating the model..."
curl -X POST -H "Content-Type: application/json" ${OLLAMA_API_URL}/api/create -d "{
  \"name\": \"${MODEL_NAME}\",
  \"modelfile\": \"$(cat ${MODELFILE_PATH})\"
}"

echo "Model ${MODEL_NAME} has been created successfully!"
```

## Domain-Specific Configuration

Create a domain-specific Docker Compose override file:

```bash
# Create a new Docker Compose file for healthcare
cp docker-compose.dev.yml docker-compose.healthcare.yml
```

Edit the new file to include domain-specific settings:

```yaml
# Healthcare-specific configuration overrides
services:
  # Domain-specific ML service configuration
  ml-service:
    environment:
      - DEFAULT_MODEL=codexcontinue-healthcare
      - DOMAIN=healthcare
    volumes:
      - ./healthcare-data:/app/domain-data

  # Domain-specific frontend configuration
  frontend:
    environment:
      - DOMAIN=healthcare
      - DOMAIN_TITLE=CodexContinue Healthcare
    volumes:
      - ./healthcare-ui:/app/domain-ui

  # Add domain-specific services if needed
  healthcare-db:
    image: postgres:latest
    environment:
      - POSTGRES_USER=healthcare
      - POSTGRES_PASSWORD=securepassword
      - POSTGRES_DB=healthcare_data
    volumes:
      - healthcare-db-data:/var/lib/postgresql/data

volumes:
  healthcare-db-data:
```

## Running Domain-Specific Instances

To run the domain-specific instance:

```bash
# Start the healthcare-specific instance
docker-compose -f docker-compose.yml -f docker-compose.healthcare.yml up -d

# Build the healthcare-specific model
docker exec codex-continue-ml-service ./ml/scripts/build_healthcare_model.sh
```

## Creating Domain-Specific Documentation

Add domain-specific documentation to the `docs` directory:

```bash
# Create domain-specific documentation
mkdir -p docs/domains/healthcare
touch docs/domains/healthcare/README.md
```

Example documentation content:

```markdown
# CodexContinue Healthcare

This documentation covers the healthcare-specific implementation of CodexContinue.

## Features

- Medical terminology understanding
- HIPAA-compliant code generation
- HL7/FHIR integration examples
- Healthcare data models
- Medical research tools

## Usage

To start the healthcare-specific instance:

```bash
docker-compose -f docker-compose.yml -f docker-compose.healthcare.yml up -d
```

## Examples

See the `examples/healthcare` directory for sample code and use cases.
```

## Domain-Specific Testing

Create domain-specific tests:

```bash
# Create domain-specific tests
mkdir -p tests/domains/healthcare
touch tests/domains/healthcare/test_healthcare_model.py
```

Example test:

```python
"""Tests for the healthcare-specific model."""
import pytest
from app.services.ml_client import ml_client

@pytest.mark.asyncio
async def test_healthcare_knowledge():
    """Test that the model has healthcare domain knowledge."""
    response = await ml_client.generate_text(
        "What is the FHIR standard and how can I implement it in Python?",
        model="codexcontinue-healthcare"
    )
    assert "Fast Healthcare Interoperability Resources" in response
    assert "Python" in response
```

## Conclusion

By following this guide, you can create domain-specific versions of CodexContinue for various industries and use cases. The containerized architecture makes it easy to run multiple instances with different configurations simultaneously.
