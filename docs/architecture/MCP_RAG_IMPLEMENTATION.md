# MCP Server with RAG Capabilities

This document describes the implementation of the Model Context Protocol (MCP) server with Retrieval Augmented Generation (RAG) capabilities in CodexContinue.

## Overview

The implementation adds a fully functional MCP server to the CodexContinue ML service with integrated vector database for RAG capabilities. This allows the system to retrieve contextually relevant information from your knowledge base and inject it into model prompts for more accurate and context-aware responses.

## Architecture

The architecture consists of the following components:

1. **MCP Server**: Implements the Model Context Protocol API endpoints for interacting with language models.
2. **Ollama Integration**: Communicates with Ollama to access the underlying language models.
3. **VectorStore**: Manages embeddings and similarity search using ChromaDB and HuggingFace embeddings.
4. **KnowledgeManager**: Handles importing and processing documents for the knowledge base.

```
┌─────────────────┐    ┌──────────────┐    ┌────────────────┐
│   MCP Server    │───▶│  RAG Engine  │───▶│ Vector Storage │
│  (Flask API)    │◀───│              │◀───│   (ChromaDB)   │
└─────────────────┘    └──────────────┘    └────────────────┘
        │                     │
        ▼                     ▼
┌─────────────────┐    ┌──────────────┐    
│ Ollama Service  │    │  Knowledge   │    
│   (LLM API)     │    │   Manager    │    
└─────────────────┘    └──────────────┘    
```

## API Endpoints

### MCP Endpoints

- `/v1/completions` - Generate completions for a given prompt with RAG
- `/v1/chat/completions` - Generate chat completions with RAG
- `/v1/models` - List available models from Ollama

### RAG Endpoints

- `/rag/import` - Import documents into the knowledge base
- `/rag/query` - Query the knowledge base directly

### Utility Endpoints

- `/health` - Health check endpoint
- `/` - Home page

## Data Storage

The implementation uses Docker volumes for persistent storage:

- `vector-data`: Stores vector embeddings and database files
- `knowledge-data`: Stores imported documents and knowledge base files

## Usage Examples

### Chat with RAG

```bash
curl -X POST http://localhost:5000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codexcontinue",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "How do I implement a dynamic programming solution for fibonacci?"}
    ],
    "temperature": 0.7,
    "use_rag": true
  }'
```

### Import Knowledge

```bash
curl -X POST http://localhost:5000/rag/import \
  -H "Content-Type: application/json" \
  -d '{
    "directory_path": "/path/to/documents",
    "file_types": [".py", ".md", ".txt"]
  }'
```

### Direct RAG Query

```bash
curl -X POST http://localhost:5000/rag/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How to implement fibonacci with dynamic programming?",
    "k": 3
  }'
```

## Testing

Use the provided testing script to verify your implementation:

```bash
python ml/scripts/test_mcp_rag.py
```

## Configuration

The following environment variables can be configured:

- `OLLAMA_API_URL`: URL for the Ollama API (default: http://ollama:11434)
- `DEFAULT_MODEL`: Default model to use (default: codexcontinue)
- `VECTOR_DB_PATH`: Path to store vector database files (default: /app/data/vectorstore)
- `KNOWLEDGE_BASE_PATH`: Path to store knowledge base files (default: /app/data/knowledge_base)

## Troubleshooting

If you encounter issues:

1. Check the ML service logs: `docker logs codexcontinue-ml-service-1`
2. Verify Ollama is running: `curl http://localhost:11434/api/tags`
3. Check volumes are properly mounted: `docker inspect codexcontinue-ml-service-1`
4. Ensure required packages are installed: Check the requirements.txt file
