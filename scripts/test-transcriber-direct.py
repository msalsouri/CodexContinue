#!/usr/bin/env python3
"""
Simplified direct test for YouTube transcriber
"""

import os
import sys
import tempfile
import json
import requests
from ml.services.youtube_transcriber import YouTubeTranscriber

def check_ollama_models():
    """Check for available Ollama models and select an appropriate one."""
    print("Checking Ollama models...")
    ollama_api_url = os.environ.get("OLLAMA_API_URL", "http://localhost:11434")
    
    try:
        response = requests.get(f"{ollama_api_url}/api/tags")
        if response.status_code == 200:
            models_json = response.json()
            available_models = [model["name"] for model in models_json.get("models", [])]
            
            if available_models:
                print(f"Available models: {', '.join(available_models)}")
                
                # Try to find a suitable model
                preferred_models = ["codexcontinue", "llama3", "mistral", "llama2", "codellama"]
                for model in preferred_models:
                    if model in available_models:
                        print(f"Using model: {model}")
                        os.environ["OLLAMA_MODEL"] = model
                        return True
                
                # If no preferred model found, use the first available one
                os.environ["OLLAMA_MODEL"] = available_models[0]
                print(f"Using model: {available_models[0]}")
                return True
            else:
                print("No models available in Ollama")
        else:
            print(f"Error connecting to Ollama API: {response.status_code}")
    except Exception as e:
        print(f"Error checking Ollama models: {str(e)}")
    
    return False

def main():
    # Set environment variables
    os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
    os.environ['FFMPEG_LOCATION'] = "/usr/bin"
    
    # Print environment variables
    print("Environment:")
    print(f"  PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"  FFMPEG_LOCATION: {os.environ.get('FFMPEG_LOCATION', 'Not set')}")
    print(f"  PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    
    # Check Ollama models
    ollama_available = check_ollama_models()
    
    # Test URL (short video)
    url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
    print(f"\nTesting YouTube transcription with URL: {url}")
    
    try:
        # Initialize transcriber
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        
        # Process video
        print("Processing video...")
        result = transcriber.process_video(url, generate_summary=ollama_available)
        
        # Print results
        print("\nResults:")
        print(f"Text length: {len(result.get('text', ''))}")
        print(f"Number of segments: {len(result.get('segments', []))}")
        
        # Print first 100 characters of transcript
        text = result.get("text", "")
        print(f"\nTranscript preview: {text[:100]}..." if text else "No transcript")
        
        if "summary" in result:
            summary = result["summary"].get("summary", "")
            print(f"\nSummary preview: {summary[:100]}..." if summary else "No summary")
            if result["summary"].get("error"):
                print("Note: There was an error with the summary generation")
        elif ollama_available:
            print("\nSummary was not generated even though Ollama is available")
        else:
            print("\nSummary not requested or Ollama not available")
        
        print("\nTEST SUCCESSFUL!")
        return 0
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
