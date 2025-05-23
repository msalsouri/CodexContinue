#!/usr/bin/env python3
"""
Test script for the MCP server with RAG capabilities
"""

import os
import sys
import json
import argparse
import requests
from pathlib import Path

# Default config
DEFAULT_MCP_URL = "http://localhost:5000"
DEFAULT_TEST_DIRECTORY = os.path.join(os.path.expanduser("~"), ".codexcontinue/test_data")

def create_test_data(directory):
    """Create test data files for RAG testing"""
    os.makedirs(directory, exist_ok=True)
    
    # Create a Python file
    with open(os.path.join(directory, "sample_code.py"), "w") as f:
        f.write("""
# This is a sample Python file for testing RAG
def fibonacci(n):
    \"\"\"Calculate the nth Fibonacci number using dynamic programming\"\"\"
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    
    # Initialize the first two numbers
    fib = [0, 1]
    
    # Calculate the fibonacci numbers iteratively
    for i in range(2, n + 1):
        fib.append(fib[i-1] + fib[i-2])
    
    return fib[n]

def factorial(n):
    \"\"\"Calculate the factorial of n recursively\"\"\"
    if n == 0 or n == 1:
        return 1
    else:
        return n * factorial(n-1)
""")
    
    # Create a markdown file with some context
    with open(os.path.join(directory, "algorithm_concepts.md"), "w") as f:
        f.write("""
# Algorithm Concepts

## Time Complexity

Time complexity is a measure of the amount of time an algorithm takes to run as a function of the length of the input. Common time complexities include:

- O(1): Constant time
- O(log n): Logarithmic time
- O(n): Linear time
- O(n log n): Log-linear time
- O(n²): Quadratic time
- O(2^n): Exponential time
- O(n!): Factorial time

## Space Complexity

Space complexity is a measure of the amount of memory an algorithm uses as a function of the length of the input.

## Algorithm Design Techniques

- Divide and conquer
- Dynamic programming
- Greedy algorithms
- Backtracking
""")

    print(f"Created test data in {directory}")
    return directory

def test_health(mcp_url):
    """Test the health endpoint"""
    try:
        response = requests.get(f"{mcp_url}/health")
        print(f"Health check: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_import_knowledge(mcp_url, directory):
    """Test importing knowledge into RAG"""
    try:
        response = requests.post(
            f"{mcp_url}/rag/import",
            json={"directory_path": directory}
        )
        print(f"Import knowledge: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Import knowledge failed: {e}")
        return False

def test_rag_query(mcp_url, query="What is the time complexity of fibonacci?"):
    """Test RAG query endpoint"""
    try:
        response = requests.post(
            f"{mcp_url}/rag/query",
            json={"query": query}
        )
        print(f"RAG query: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"RAG query failed: {e}")
        return False

def test_chat_completions(mcp_url, messages):
    """Test chat completions endpoint"""
    try:
        response = requests.post(
            f"{mcp_url}/v1/chat/completions",
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

def test_completions(mcp_url, prompt):
    """Test completions endpoint"""
    try:
        response = requests.post(
            f"{mcp_url}/v1/completions",
            json={
                "model": "codexcontinue",
                "prompt": prompt,
                "temperature": 0.7,
                "use_rag": True
            }
        )
        print(f"Completions: {response.status_code}")
        print(json.dumps(response.json(), indent=2))
        return response.status_code == 200
    except Exception as e:
        print(f"Completions failed: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Test MCP server with RAG capabilities')
    parser.add_argument('--url', default=DEFAULT_MCP_URL, help='MCP server URL')
    parser.add_argument('--test-dir', default=DEFAULT_TEST_DIRECTORY, help='Directory for test data')
    parser.add_argument('--skip-import', action='store_true', help='Skip knowledge import test')
    args = parser.parse_args()
    
    print(f"Testing MCP server at {args.url}")
    
    # Test health endpoint
    if not test_health(args.url):
        print("Health check failed, exiting")
        sys.exit(1)
    
    # Create test data if needed
    test_dir = Path(args.test_dir)
    if not test_dir.exists():
        create_test_data(args.test_dir)
    
    # Test importing knowledge
    if not args.skip_import:
        if not test_import_knowledge(args.url, args.test_dir):
            print("Import knowledge failed, continuing anyway")
    
    # Test RAG query
    test_rag_query(args.url)
    
    # Test chat completions
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain the time complexity of the fibonacci function and provide an optimized version."}
    ]
    test_chat_completions(args.url, messages)
    
    # Test completions
    prompt = "What's the difference between dynamic programming and recursion? Give examples using fibonacci."
    test_completions(args.url, prompt)
    
    print("All tests completed!")

if __name__ == "__main__":
    main()
