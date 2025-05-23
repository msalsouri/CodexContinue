#!/usr/bin/env python3
"""
Simple test for YouTube transcription API endpoint
"""
import requests
import json
import time
import sys

def test_api():
    """Test the YouTube transcription API endpoint"""
    # First check if the API is available
    print("Testing API health...")
    try:
        health_response = requests.get("http://localhost:5060/health", timeout=5)
        if health_response.status_code == 200:
            print(f"API health endpoint OK: {health_response.json()}")
        else:
            print(f"API health check failed: {health_response.status_code}")
            return False
    except Exception as e:
        print(f"Error connecting to API: {e}")
        return False
    
    # Now test the transcription endpoint
    print("\nTesting transcription endpoint...")
    try:
        # Use a very short video for quick testing
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        print(f"Transcribing URL: {url}")
        
        start_time = time.time()
        response = requests.post(
            "http://localhost:5060/youtube/transcribe",
            json={"url": url, "whisper_model_size": "tiny"},
            timeout=180  # 3 minute timeout
        )
        
        elapsed_time = time.time() - start_time
        print(f"Request took {elapsed_time:.2f} seconds")
        
        if response.status_code == 200:
            result = response.json()
            text = result.get("text", "")
            segments = result.get("segments", [])
            
            print(f"Transcription successful:")
            print(f"- Characters: {len(text)}")
            print(f"- Segments: {len(segments)}")
            
            if text:
                print(f"- Preview: {text[:100]}...")
                
                # Save the transcription
                with open("simple_test_transcript.txt", "w") as f:
                    f.write(text)
                
                # Save the full result
                with open("simple_test_result.json", "w") as f:
                    json.dump(result, f, indent=2)
                
                print("Results saved to simple_test_transcript.txt and simple_test_result.json")
                return True
            else:
                print("Error: No text in transcription result")
                return False
        else:
            print(f"Error: Transcription request failed with status code {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"Error during transcription request: {e}")
        return False

if __name__ == "__main__":
    print("Simple YouTube Transcription API Test")
    print("====================================")
    
    success = test_api()
    
    if success:
        print("\n✅ Test completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Test failed!")
        sys.exit(1)
