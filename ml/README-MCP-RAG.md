# CodexContinue MCP Server with RAG Capabilities

This document describes the implementation of a Model Context Protocol (MCP) server with Retrieval Augmented Generation (RAG) capabilities in CodexContinue using LiteLLM.

## Overview

The implementation uses LiteLLM's Ollama adapter as the core MCP server and integrates it with a custom RAG proxy to provide context-aware responses. This approach combines the best of both worlds:

1. **LiteLLM** provides a production-ready OpenAI API compatible interface
2. **Ollama** handles the local LLM inference
3. **Our custom RAG proxy** adds context retrieval capabilities to enhance responses

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌────────────────┐
│   RAG Proxy     │───▶│   LiteLLM    │───▶│     Ollama     │
│  (Flask API)    │◀───│  MCP Server  │◀───│   (LLM API)    │
└─────────────────┘    └──────────────┘    └────────────────┘
        │                                          │
        ▼                                          ▼
┌─────────────────┐                       ┌────────────────┐
│  Vector Store   │                       │    Models      │
│   (ChromaDB)    │                       │               │
└─────────────────┘                       └────────────────┘
```

## Components

### 1. LiteLLM MCP Server

The `litellm/ollama` container provides:
- OpenAI API compatibility (follows MCP standards)
- Integration with Ollama models
- Support for both chat and completion endpoints
- Model management

### 2. RAG Proxy

Our custom `rag-proxy` service provides:
- Vector database integration with ChromaDB
- Document chunking and embedding
- Context augmentation of prompts
- API pass-through to LiteLLM

## Getting Started

### Starting the MCP Server

Run the following script to start the MCP server with RAG capabilities:

```bash
./scripts/start-mcp-litellm.sh
```

### Testing the Implementation

Use the provided test script to verify the RAG capabilities:

```bash
python ml/scripts/test_mcp_litellm_rag.py
```

## API Endpoints

### MCP Endpoints

The following MCP-compatible endpoints are available at `http://localhost:5001`:

- `POST /v1/completions` - Generate completions with RAG
- `POST /v1/chat/completions` - Generate chat completions with RAG
- `GET /v1/models` - List available models

### RAG Endpoints

Additional custom endpoints for RAG management:

- `POST /rag/import` - Import documents into the knowledge base
- `POST /rag/query` - Query the knowledge base directly

## Usage Examples

### Chat Completion with RAG

```bash
curl -X POST http://localhost:5001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codexcontinue",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What features does CodexContinue RAG support?"}
    ],
    "use_rag": true
  }'
```

### Import Documents

```bash
curl -X POST http://localhost:5001/rag/import \
  -H "Content-Type: application/json" \
  -d '{
    "directory_path": "/app/data/knowledge_base"
  }'
```

## Configuration

The following environment variables can be configured:

- `LITELLM_API_URL`: URL for the LiteLLM service (default: http://litellm:8000)
- `VECTOR_DB_PATH`: Path to store vector database files
- `KNOWLEDGE_BASE_PATH`: Path to store knowledge base files
- `RAG_PROXY_PORT`: Port for the RAG proxy service

## Troubleshooting

If you encounter issues:

1. Check container status: `docker-compose -f docker-compose.yml -f docker-compose.litellm.yml ps`
2. Check logs: `docker-compose -f docker-compose.yml -f docker-compose.litellm.yml logs rag-proxy`
3. Verify Ollama models: `curl http://localhost:11434/api/tags`
4. Test MCP endpoints: `curl http://localhost:5001/v1/models`