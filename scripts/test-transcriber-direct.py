#!/usr/bin/env python3
"""
Simplified direct test for YouTube transcriber
"""

import os
import sys
import tempfile
from ml.services.youtube_transcriber import YouTubeTranscriber

def main():
    # Set environment variables
    os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
    os.environ['FFMPEG_LOCATION'] = "/usr/bin"
    
    # Print environment variables
    print("Environment:")
    print(f"  PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"  FFMPEG_LOCATION: {os.environ.get('FFMPEG_LOCATION', 'Not set')}")
    print(f"  PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    
    # Test URL (short video)
    url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
    print(f"\nTesting YouTube transcription with URL: {url}")
    
    try:
        # Initialize transcriber
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        
        # Process video
        print("Processing video...")
        result = transcriber.process_video(url, generate_summary=True)
        
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
        
        print("\nTEST SUCCESSFUL!")
        return 0
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
