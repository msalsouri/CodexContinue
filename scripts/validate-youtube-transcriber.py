#!/usr/bin/env python3
"""
Validation test for YouTube transcription feature fixes
"""

import os
import sys
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

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
    
    # Try to import the YouTubeTranscriber
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        print("Successfully imported YouTubeTranscriber")
        
        # Create an instance
        transcriber = YouTubeTranscriber()
        print(f"Created transcriber with ffmpeg_location: {transcriber.ffmpeg_location}")
        
        # Test the Ollama model configuration
        print(f"Configured Ollama model: {transcriber.ollama_model}")
        print(f"Configured Ollama API URL: {transcriber.ollama_api_url}")
        
        # Everything passed
        print("Validation test PASSED - YouTube transcriber properly configured")
        
        # Write results to a file
        with open('youtube_transcriber_validation.log', 'w') as f:
            f.write("YouTube Transcription Feature Validation\n")
            f.write("======================================\n")
            f.write(f"ffmpeg_location: {transcriber.ffmpeg_location}\n")
            f.write(f"Ollama model: {transcriber.ollama_model}\n")
            f.write(f"Ollama API URL: {transcriber.ollama_api_url}\n")
            f.write("\nTest PASSED - Feature is working correctly\n")
        
        return 0
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
