#!/usr/bin/env python3
"""
YouTube Transcriber Test Script

This script tests the YouTube transcriber feature by sending a request to the ML service.
It helps verify that the ML service is properly processing YouTube transcription requests.
"""

import os
import sys
import requests
import json
import time
import argparse

# Default configuration
DEFAULT_ML_SERVICE_URL = "http://localhost:5000"
DEFAULT_TEST_VIDEO = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  # A well-known, short video

def test_transcription(url, video_url, whisper_model="base", language=None, generate_summary=False):
    """Test the YouTube transcription endpoint with the given parameters."""
    print(f"Testing YouTube transcription with model: {whisper_model}")
    print(f"Video URL: {video_url}")
    
    start_time = time.time()
    
    try:
        response = requests.post(
            f"{url}/youtube/transcribe",
            json={
                "url": video_url,
                "language": language,
                "whisper_model_size": whisper_model,
                "generate_summary": generate_summary
            },
            timeout=300  # 5 minutes timeout for larger models
        )
        
        elapsed_time = time.time() - start_time
        print(f"Request completed in {elapsed_time:.2f} seconds")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Transcription successful!")
            print(f"Transcript length: {len(result.get('text', ''))} characters")
            print(f"Number of segments: {len(result.get('segments', []))}")
            
            if generate_summary and "summary" in result:
                print("\nSummary Status:")
                summary_data = result["summary"]
                if summary_data.get("error"):
                    print(f"❌ Summary generation failed: {summary_data.get('summary', '')}")
                else:
                    print(f"✅ Summary generated using model: {summary_data.get('model', 'unknown')}")
                    print(f"Summary length: {len(summary_data.get('summary', ''))} characters")
            
            # Print a sample of the transcript
            if result.get("text"):
                print("\nSample of transcript (first 200 chars):")
                print(result["text"][:200] + "...")
            
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Could not connect to the ML service")
        print(f"ML Service URL: {url}")
        print("Make sure the ML service is running and accessible")
        return False
    except requests.exceptions.Timeout:
        print(f"❌ Timeout Error: The request timed out after {time.time() - start_time:.2f} seconds")
        print("This can happen with long videos or when using larger models")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Test YouTube Transcription Feature")
    parser.add_argument("--url", default=DEFAULT_ML_SERVICE_URL, help="ML service URL")
    parser.add_argument("--video", default=DEFAULT_TEST_VIDEO, help="YouTube video URL to test")
    parser.add_argument("--model", default="base", choices=["tiny", "base", "small", "medium", "large"], 
                        help="Whisper model size to use")
    parser.add_argument("--language", help="Optional language for transcription")
    parser.add_argument("--summarize", action="store_true", help="Generate summary")
    
    args = parser.parse_args()
    
    # Print configuration
    print("=== YouTube Transcription Test ===")
    print(f"ML Service URL: {args.url}")
    print(f"Model: {args.model}")
    print(f"Language: {args.language or 'Auto-detect'}")
    print(f"Summarize: {'Yes' if args.summarize else 'No'}")
    print("=" * 34)
    
    success = test_transcription(
        args.url, 
        args.video, 
        whisper_model=args.model, 
        language=args.language, 
        generate_summary=args.summarize
    )
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
