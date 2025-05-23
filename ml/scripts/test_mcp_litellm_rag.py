#!/usr/bin/env python3
"""
Test script for the MCP server with RAG capabilities using LiteLLM
"""

import os
import sys
import json
import requests
import argparse
from pathlib import Path
import time

def create_test_document(directory, filename="test_document.md"):
    """Create a test document for RAG testing"""
    os.makedirs(directory, exist_ok=True)
    
    test_content = """
# CodexContinue RAG Test Document

## Overview

This is a test document to demonstrate the RAG capabilities of the CodexContinue MCP server.

## Key Features

1. **Vector Database**: Uses ChromaDB for storing embeddings
2. **Embeddings**: Uses sentence-transformers/all-MiniLM-L6-v2 for embeddings
3. **Document Processing**: Supports chunking and metadata extraction
4. **LiteLLM Integration**: Provides OpenAI-compatible API for model access
5. **MCP Protocol**: Compatible with the Model Context Protocol

## Example Usage

To use the RAG capabilities:

```python
import requests

response = requests.post(
    "http://localhost:5001/v1/chat/completions",
    json={
        "model": "codexcontinue",
        "messages": [
            {"role": "user", "content": "What features does CodexContinue RAG support?"}
        ],
        "use_rag": True
    }
)

print(response.json())
```

## Conclusion

This test document should be correctly indexed by the RAG system and retrievable via semantic search.
"""
    
    with open(os.path.join(directory, filename), "w") as f:
        f.write(test_content)
        
    print(f"Created test document: {os.path.join(directory, filename)}")
    
    return os.path.join(directory, filename)

def test_health(url):
    """Test the health endpoint"""
    try:
        response = requests.get(f"{url}/health")
        print(f"Health check: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_import_knowledge(url, directory):
    """Test importing knowledge into RAG"""
    try:
        response = requests.post(
            f"{url}/rag/import",
            json={"directory_path": directory}
        )
        print(f"Import knowledge: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Import knowledge failed: {e}")
        return False

def test_rag_query(url, query="What features does CodexContinue RAG support?"):
    """Test RAG query endpoint"""
    try:
        response = requests.post(
            f"{url}/rag/query",
            json={"query": query}
        )
        print(f"RAG query: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"RAG query failed: {e}")
        return False

def test_chat_completions(url, messages):
    """Test chat completions endpoint with RAG"""
    try:
        response = requests.post(
            f"{url}/v1/chat/completions",
            json={
                "model": "codexcontinue",
                "messages": messages,
                "temperature": 0.7,
                "use_rag": True
            }
        )
        print(f"Chat completions: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Chat completions failed: {e}")
        return False

def test_models(url):
    """Test the models endpoint"""
    try:
        response = requests.get(f"{url}/v1/models")
        print(f"Models: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Models request failed: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Test MCP server with RAG capabilities via LiteLLM')
    parser.add_argument('--url', default="http://localhost:5001", help='MCP server URL')
    parser.add_argument('--test-dir', default="/tmp/codexcontinue_test_data", help='Directory for test data')
    parser.add_argument('--skip-import', action='store_true', help='Skip knowledge import test')
    args = parser.parse_args()
    
    print(f"Testing MCP server at {args.url}")
    
    # Test health endpoint
    print("\n==== Testing Health Endpoint ====")
    if not test_health(args.url):
        print("Health check failed, exiting")
        sys.exit(1)
    
    # Create test document
    print("\n==== Creating Test Document ====")
    test_doc_path = create_test_document(args.test_dir)
    
    # Test models endpoint
    print("\n==== Testing Models Endpoint ====")
    test_models(args.url)
    
    # Test importing knowledge
    if not args.skip_import:
        print("\n==== Testing Knowledge Import ====")
        test_import_knowledge(args.url, args.test_dir)
        # Allow time for indexing
        print("Waiting for indexing to complete...")
        time.sleep(5)
    
    # Test RAG query
    print("\n==== Testing RAG Query ====")
    test_rag_query(args.url)
    
    # Test chat completions
    print("\n==== Testing Chat Completions with RAG ====")
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What features does CodexContinue RAG support?"}
    ]
    test_chat_completions(args.url, messages)
    
    print("\nAll tests completed!")

if __name__ == "__main__":
    main()
