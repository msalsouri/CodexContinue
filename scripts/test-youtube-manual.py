#!/usr/bin/env python3
"""
Manual test of YouTube transcription feature
"""

import os
import sys
import json
from pathlib import Path

# Add project root to path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
if project_root not in sys.path:
    sys.path.insert(0, project_root)
os.environ["PYTHONPATH"] = project_root

def test_transcription():
    """Test the YouTube transcription component"""
    print("Testing YouTube transcription...")
    
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create transcriber with tiny model for quick testing
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        
        # Print settings
        print(f"FFmpeg location: {transcriber.ffmpeg_location}")
        print(f"Ollama API URL: {transcriber.ollama_api_url}")
        print(f"Ollama model: {transcriber.ollama_model}")
        
        # Test with a short video
        url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"  # "Me at the zoo" - first YouTube video
        print(f"Processing video: {url}")
        
        # Download and transcribe
        result = transcriber.process_video(url)
        
        # Print results
        if "text" in result:
            print("\nTranscription Results:")
            print(f"- Characters: {len(result['text'])}")
            print(f"- Segments: {len(result.get('segments', []))}")
            print(f"- Processing time: {result['processing_time']['total_seconds']:.2f} seconds")
            
            # Print transcript preview
            preview_length = min(200, len(result['text']))
            print(f"\nTranscript preview:\n{result['text'][:preview_length]}...")
            
            # Save results
            with open("manual_test_result.json", "w") as f:
                json.dump(result, f, indent=2)
            
            with open("manual_test_transcript.txt", "w") as f:
                f.write(result["text"])
            
            print("\nResults saved to:")
            print("- manual_test_result.json")
            print("- manual_test_transcript.txt")
            
            return True
        else:
            print("Error: No text in result")
            return False
    
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("============================================")
    print("YouTube Transcription Feature Manual Test")
    print("============================================")
    success = test_transcription()
    print("\nTest result:", "SUCCESS" if success else "FAILED")
    sys.exit(0 if success else 1)
