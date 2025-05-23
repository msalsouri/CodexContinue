#!/usr/bin/env python3
"""
Direct test for the YouTubeTranscriber component
"""

import os
import sys
import logging
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)
os.environ["PYTHONPATH"] = project_root

def main():
    """Test the YouTubeTranscriber component directly."""
    print("Testing YouTubeTranscriber component directly")
    
    # Print environment info
    print(f"Python version: {sys.version}")
    print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    print(f"PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"FFMPEG_LOCATION: {os.environ.get('FFMPEG_LOCATION', 'Not set')}")
    
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create a YouTubeTranscriber instance
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        print(f"Created YouTubeTranscriber with ffmpeg_location: {transcriber.ffmpeg_location}")
        
        # Test with a short video
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        print(f"Processing video: {url}")
        
        # Process the video
        result = transcriber.process_video(url)
        
        # Check the result
        if "text" in result:
            text = result["text"]
            segments = result.get("segments", [])
            
            print(f"Transcription successful:")
            print(f"  Characters: {len(text)}")
            print(f"  Segments: {len(segments)}")
            print(f"  Preview: {text[:100]}...")
            
            # Save to file
            with open("direct_test_transcript.txt", "w") as f:
                f.write(text)
            
            # Save full result to JSON
            with open("direct_test_result.json", "w") as f:
                json.dump(result, f, indent=2)
            
            print("Transcription saved to direct_test_transcript.txt")
            print("Full result saved to direct_test_result.json")
            
            return 0
        else:
            print("Error: No text in transcription result")
            return 1
    
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
