#!/usr/bin/env python3
"""
Test script for the Ollama API connection
"""

import os
import sys
import json
import requests
import argparse
from typing import Dict, Any, Optional

def check_ollama_connection(url: str = "http://localhost:11434") -> Dict[str, Any]:
    """Check connection to Ollama API"""
    try:
        response = requests.get(f"{url}/api/tags")
        if response.status_code == 200:
            return {
                "success": True,
                "status_code": response.status_code,
                "data": response.json()
            }
        else:
            return {
                "success": False,
                "status_code": response.status_code,
                "error": response.text
            }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

def list_models(url: str = "http://localhost:11434") -> Dict[str, Any]:
    """List available models"""
    return check_ollama_connection(url)

def test_generation(
    url: str = "http://localhost:11434",
    model: str = "codexcontinue",
    prompt: str = "Write a simple hello world function in Python."
) -> Dict[str, Any]:
    """Test model generation"""
    try:
        response = requests.post(
            f"{url}/api/generate",
            json={
                "model": model,
                "prompt": prompt
            }
        )
        
        if response.status_code == 200:
            return {
                "success": True,
                "status_code": response.status_code,
                "data": response.json()
            }
        else:
            return {
                "success": False,
                "status_code": response.status_code,
                "error": response.text
            }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

def main():
    parser = argparse.ArgumentParser(description='Test Ollama API connection')
    parser.add_argument('--url', default="http://localhost:11434", help='Ollama API URL')
    parser.add_argument('--model', default="codexcontinue", help='Model name to test')
    parser.add_argument('--prompt', default="Write a simple hello world function in Python.", 
                       help='Test prompt')
    args = parser.parse_args()
    
    print(f"Testing Ollama API at {args.url}")
    
    # Test connection
    print("\n1. Checking connection...")
    connection = check_ollama_connection(args.url)
    print(f"Connection: {'Success' if connection['success'] else 'Failed'}")
    if connection['success']:
        print(f"Available models: {[model['name'] for model in connection['data'].get('models', [])]}")
    else:
        print(f"Error: {connection.get('error', 'Unknown error')}")
        sys.exit(1)
    
    # Test generation with preferred model
    print(f"\n2. Testing generation with {args.model}...")
    if args.model not in [model['name'] for model in connection['data'].get('models', [])]:
        print(f"Warning: Model {args.model} not found, using default model.")
        args.model = connection['data'].get('models', [{}])[0].get('name', 'model not found')
        if args.model == 'model not found':
            print("No models available, skipping generation test.")
            sys.exit(1)
    
    generation = test_generation(args.url, args.model, args.prompt)
    print(f"Generation: {'Success' if generation['success'] else 'Failed'}")
    if generation['success']:
        print("\nGeneration result:")
        print("-" * 40)
        print(generation['data'].get('response', ''))
        print("-" * 40)
    else:
        print(f"Error: {generation.get('error', 'Unknown error')}")

if __name__ == "__main__":
    main()
