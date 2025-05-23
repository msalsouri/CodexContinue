#!/usr/bin/env python3
"""
Validation test for YouTube transcription feature fixes
"""

import os
import sys
import logging
import json
import subprocess
import requests

# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

def test_ffmpeg():
    """Test if ffmpeg is properly installed and configured."""
    print("Testing ffmpeg installation...")
    
    try:
        # Check ffmpeg version
        result = subprocess.run(["ffmpeg", "-version"], 
                              capture_output=True, 
                              text=True, 
                              check=True)
        ffmpeg_version = result.stdout.split('\n')[0]
        print(f"✅ FFmpeg is properly installed: {ffmpeg_version}")
        return True
    except Exception as e:
        print(f"❌ FFmpeg test failed: {e}")
        return False

def test_api_endpoint():
    """Test the YouTube transcription API endpoint."""
    print("\nTesting YouTube transcription API endpoint...")
    
    try:
        # Check if the ML service is running
        health_url = "http://localhost:5000/health"
        try:
            response = requests.get(health_url)
            if response.status_code == 200:
                print(f"✅ ML service is running: {response.json()}")
            else:
                print(f"❌ ML service health check failed: {response.status_code}")
                return False
        except requests.exceptions.ConnectionError:
            print("❌ ML service is not running")
            return False
        
        # Try to transcribe a short YouTube video
        url = "http://localhost:5000/youtube/transcribe"
        data = {
            "url": "https://www.youtube.com/watch?v=9bZkp7q19f0",
            "generate_summary": False
        }
        
        print(f"Making request to {url} with data: {data}")
        response = requests.post(url, json=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ API transcription successful")
            print(f"✅ Transcript length: {len(result.get('text', ''))}")
            print(f"✅ Preview: {result.get('text', '')[:100]}...")
            return True
        else:
            print(f"❌ API transcription failed: {response.status_code}")
            print(f"Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ API test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Test the YouTube transcription feature"""
    print("Starting YouTube transcription validation test")
    
    # Print environment information
    print(f"Python version: {sys.version}")
    print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    print(f"PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"FFMPEG_LOCATION: {os.environ.get('FFMPEG_LOCATION', 'Not set')}")
    
    # Set required environment variables
    os.environ['FFMPEG_LOCATION'] = '/usr/bin'
    if '/usr/bin' not in os.environ.get('PATH', ''):
        os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
    
    # Test ffmpeg installation
    ffmpeg_ok = test_ffmpeg()
    
    # Test API endpoint
    api_ok = test_api_endpoint()
    
    # Try to import the YouTubeTranscriber
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        print("\nSuccessfully imported YouTubeTranscriber")
        
        # Create an instance
        transcriber = YouTubeTranscriber()
        print(f"Created transcriber with ffmpeg_location: {transcriber.ffmpeg_location}")
        
        # Test the Ollama model configuration
        print(f"Configured Ollama model: {transcriber.ollama_model}")
        print(f"Configured Ollama API URL: {transcriber.ollama_api_url}")
        
        # Everything passed
        print("\nValidation test summary:")
        print(f"FFmpeg test: {'✅ PASSED' if ffmpeg_ok else '❌ FAILED'}")
        print(f"API test: {'✅ PASSED' if api_ok else '❌ FAILED'}")
        print(f"Component test: ✅ PASSED")
        
        # Write results to a file
        with open('youtube_transcriber_validation.log', 'w') as f:
            f.write("YouTube Transcription Feature Validation\n")
            f.write("======================================\n")
            f.write(f"ffmpeg_location: {transcriber.ffmpeg_location}\n")
            f.write(f"Ollama model: {transcriber.ollama_model}\n")
            f.write(f"Ollama API URL: {transcriber.ollama_api_url}\n")
            f.write(f"FFmpeg test: {'PASSED' if ffmpeg_ok else 'FAILED'}\n")
            f.write(f"API test: {'PASSED' if api_ok else 'FAILED'}\n")
            f.write(f"Component test: PASSED\n")
            f.write("\nOverall result: {'PASSED' if ffmpeg_ok and api_ok else 'FAILED'}\n")
        
        if ffmpeg_ok and api_ok:
            print("\nValidation test PASSED - YouTube transcriber properly configured")
            return 0
        else:
            print("\nValidation test FAILED - See above for details")
            return 1
    except Exception as e:
        print(f"Test FAILED: {str(e)}")
        
        # Write error to a file
        with open('youtube_transcriber_validation.log', 'w') as f:
            f.write("YouTube Transcription Feature Validation\n")
            f.write("======================================\n")
            f.write(f"ERROR: {str(e)}\n")
            f.write("\nTest FAILED\n")
            
        return 1

if __name__ == "__main__":
    result = main()
    print(f"\nValidation test {'PASSED' if result == 0 else 'FAILED'}")
    sys.exit(result)
