#!/usr/bin/env python3
"""
Standalone YouTube Transcriber test
"""

import os
import sys
import json
import requests
import subprocess
import time
import yt_dlp
import whisper

def ensure_env():
    """Ensure environment is correctly configured."""
    # Make sure /usr/bin is in PATH
    if '/usr/bin' not in os.environ.get('PATH', ''):
        os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
    
    # Set PYTHONPATH if not set
    if not os.environ.get('PYTHONPATH'):
        os.environ['PYTHONPATH'] = os.path.expanduser('~/Projects/CodexContinue')

def test_direct_transcription():
    """Test direct transcription with whisper and yt-dlp."""
    print("\n=== Testing Direct Transcription ===")
    
    # Create temp directories
    temp_dir = os.path.expanduser("~/yt-transcribe-test")
    os.makedirs(temp_dir, exist_ok=True)
    
    # Test video URL
    url = "https://www.youtube.com/watch?v=9bZkp7q19f0"  # Short video
    print(f"Processing URL: {url}")
    
    try:
        # Step 1: Download the audio
        print("Downloading audio...")
        video_id = url.split("v=")[1].split("&")[0]
        output_file = os.path.join(temp_dir, video_id)
        output_file_mp3 = f"{output_file}.mp3"
        
        # Remove existing file if present
        if os.path.exists(output_file_mp3):
            os.unlink(output_file_mp3)
        
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': output_file,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
            'ffmpeg_location': '/usr/bin',  # Explicitly set ffmpeg location
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        
        if not os.path.exists(output_file_mp3):
            print(f"Error: Audio file not found at {output_file_mp3}")
            return False
        
        print(f"Audio downloaded successfully: {output_file_mp3}")
        
        # Step 2: Load Whisper model
        print("Loading Whisper model...")
        model = whisper.load_model("base", device="cpu")
        
        # Step 3: Transcribe
        print("Transcribing audio...")
        result = model.transcribe(output_file_mp3)
        
        print("\nTranscription Results:")
        print(f"Text length: {len(result['text'])} characters")
        print(f"First 100 chars: {result['text'][:100]}...")
        
        return True
    
    except Exception as e:
        print(f"Error in direct transcription: {str(e)}")
        return False

def test_ml_service():
    """Test the ML service API."""
    print("\n=== Testing ML Service API ===")
    
    # Start the ML service
    print("Starting ML service...")
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.expanduser("~/Projects/CodexContinue")
    
    # Use Popen to start the service in the background
    process = subprocess.Popen(
        ["python3", "ml/app.py"],
        env=env,
        cwd=os.path.expanduser("~/Projects/CodexContinue"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait for the service to start
    print("Waiting for service to start...")
    time.sleep(5)
    
    try:
        # Check if the service is running
        response = requests.get("http://localhost:5000/health")
        if response.status_code != 200:
            print(f"Error: ML service health check failed with status {response.status_code}")
            process.terminate()
            return False
        
        print("ML service is running.")
        
        # Test the transcription endpoint
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"  # Short video
        data = {
            "url": url,
            "generate_summary": True
        }
        
        print(f"Calling transcription API with URL: {url}")
        response = requests.post(
            "http://localhost:5000/youtube/transcribe", 
            json=data
        )
        
        if response.status_code == 200:
            result = response.json()
            print("\nAPI Response:")
            print(f"Text length: {len(result.get('text', ''))} characters")
            print(f"First 100 chars: {result.get('text', '')[:100]}...")
            
            if 'summary' in result:
                print("\nSummary available.")
            else:
                print("\nNo summary in response.")
            
            return True
        else:
            print(f"Error: API call failed with status {response.status_code}")
            print(f"Response: {response.text}")
            return False
    
    except Exception as e:
        print(f"Error testing ML service: {str(e)}")
        return False
    
    finally:
        # Clean up
        print("Stopping ML service...")
        process.terminate()
        stdout, stderr = process.communicate()
        if stderr:
            print(f"ML service stderr: {stderr.decode()}")

if __name__ == "__main__":
    print("=== YouTube Transcriber Comprehensive Test ===")
    ensure_env()
    
    # Test direct transcription
    direct_success = test_direct_transcription()
    print(f"\nDirect transcription test {'PASSED' if direct_success else 'FAILED'}")
    
    # Test ML service
    service_success = test_ml_service()
    print(f"\nML service test {'PASSED' if service_success else 'FAILED'}")
    
    # Overall result
    if direct_success and service_success:
        print("\nAll tests PASSED!")
        sys.exit(0)
    else:
        print("\nSome tests FAILED!")
        sys.exit(1)
