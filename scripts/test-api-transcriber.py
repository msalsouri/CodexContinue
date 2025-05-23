#!/usr/bin/env python3
"""
Test the YouTube transcription API endpoint with various fixes for ffmpeg
"""
import os
import sys
import requests
import json
import time
import argparse
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    parser = argparse.ArgumentParser(description="Test the YouTube transcription API")
    parser.add_argument("--url", default="https://www.youtube.com/watch?v=9bZkp7q19f0",
                      help="YouTube URL to transcribe")
    parser.add_argument("--model", default="tiny", 
                      help="Whisper model size to use (tiny, base, small, medium, large)")
    parser.add_argument("--api-url", default="http://localhost:5000",
                      help="ML service API URL")
    args = parser.parse_args()
    
    # Test API connection
    try:
        response = requests.get(f"{args.api_url}/health", timeout=5)
        if response.status_code == 200:
            print(f"✅ ML service is running: {response.json()}")
        else:
            print(f"❌ ML service is not healthy: {response.status_code}")
            return 1
    except Exception as e:
        print(f"❌ Failed to connect to ML service: {e}")
        return 1
    
    # Make transcription request
    print(f"Testing transcription of URL: {args.url}")
    print(f"Using Whisper model: {args.model}")
    
    try:
        start_time = time.time()
        response = requests.post(
            f"{args.api_url}/youtube/transcribe",
            json={
                "url": args.url,
                "whisper_model_size": args.model,
                "generate_summary": False
            },
            timeout=120  # 2 minute timeout
        )
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Transcription successful in {elapsed_time:.2f} seconds")
            
            # Print metadata
            if "metadata" in result:
                print("\nMetadata:")
                for key, value in result["metadata"].items():
                    print(f"  {key}: {value}")
            
            # Print transcript stats
            text = result.get("text", "")
            segments = result.get("segments", [])
            print(f"\nTranscript statistics:")
            print(f"  Characters: {len(text)}")
            print(f"  Segments: {len(segments)}")
            print(f"  Preview: {text[:100]}...")
            
            # Save transcript
            with open("api_transcript_test.txt", "w") as f:
                f.write(text)
            print(f"Saved transcript to api_transcript_test.txt")
            
            return 0
        else:
            print(f"❌ Transcription failed with status code: {response.status_code}")
            print(f"Error: {response.text}")
            return 1
    except Exception as e:
        print(f"❌ Request failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
