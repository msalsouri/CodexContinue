#!/bin/python3
import requests
import time
import sys

def test_endpoint(url, name):
    try:
        print(f"Testing {name} at {url}...", end="")
        sys.stdout.flush()
        response = requests.get(url, timeout=3)
        print(f" Status: {response.status_code}")
        if response.status_code < 400:
            print(f"Response: {response.text[:100]}..." if len(response.text) > 100 else f"Response: {response.text}")
            return True
        else:
            print(f"Error: Status code {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f" Error: {e}")
        return False

def main():
    services = [
        {"name": "Ollama API", "url": "http://localhost:11434/api/tags"},
        {"name": "Backend API", "url": "http://localhost:8000/health"},
        {"name": "Streamlit Frontend", "url": "http://localhost:8501"},
        {"name": "ML Service", "url": "http://localhost:5000/health"}
    ]
    
    print("===== CodexContinue Service Test =====")
    success_count = 0
    
    for service in services:
        if test_endpoint(service["url"], service["name"]):
            success_count += 1
        print()
    
    print(f"Summary: {success_count}/{len(services)} services are accessible")
    
if __name__ == "__main__":
    main()
