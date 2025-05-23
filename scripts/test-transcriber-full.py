#!/usr/bin/env python3
"""
Full integration test for YouTube transcription with ffmpeg validation
"""

import os
import sys
import subprocess
import tempfile
import json
import requests
from pathlib import Path

# Add project root to path if running directly
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Setup environment variables
os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
os.environ['FFMPEG_LOCATION'] = "/usr/bin"
os.putenv('PATH', f"/usr/bin:{os.environ.get('PATH', '')}")
os.putenv('FFMPEG_LOCATION', "/usr/bin")

def test_ffmpeg():
    """Test if ffmpeg is properly installed and configured."""
    print("\n=== Testing FFmpeg Installation ===")
    
    try:
        # Check ffmpeg version
        result = subprocess.run(["ffmpeg", "-version"], 
                              capture_output=True, 
                              text=True, 
                              check=True)
        ffmpeg_version = result.stdout.split('\n')[0]
        print(f"✅ FFmpeg is properly installed: {ffmpeg_version}")
        
        # Check ffprobe version
        result = subprocess.run(["ffprobe", "-version"], 
                              capture_output=True, 
                              text=True, 
                              check=True)
        ffprobe_version = result.stdout.split('\n')[0]
        print(f"✅ FFprobe is properly installed: {ffprobe_version}")
        
        # Test creation of a simple test file
        with tempfile.NamedTemporaryFile(suffix='.mp4') as temp_video:
            cmd = [
                "ffmpeg", "-y", "-f", "lavfi", "-i", "testsrc=duration=5:size=1280x720:rate=30",
                "-c:v", "libx264", temp_video.name
            ]
            subprocess.run(cmd, check=True, capture_output=True)
            
            # Check the file size to confirm it was created
            file_size = os.path.getsize(temp_video.name)
            print(f"✅ Successfully created test video file ({file_size} bytes)")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ FFmpeg test failed: {e}")
        print(f"Error output: {e.stderr}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error during FFmpeg test: {e}")
        return False

def test_youtube_transcriber():
    """Test the YouTube transcriber directly."""
    print("\n=== Testing YouTube Transcriber ===")
    
    try:
        # Import here to avoid errors if modules are not installed
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create transcriber instance
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        print("✅ Successfully created YouTubeTranscriber instance")
        
        # Test URL (short video)
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        print(f"📥 Downloading and transcribing: {url}")
        
        # Process the video - first just download
        audio_file = transcriber.download_audio(url)
        print(f"✅ Audio downloaded to: {audio_file}")
        
        # Check if file exists and has size
        if os.path.exists(audio_file):
            file_size = os.path.getsize(audio_file)
            print(f"✅ Audio file exists with size: {file_size} bytes")
        else:
            print("❌ Downloaded audio file not found")
            return False
        
        # Now transcribe the file
        print("🔊 Transcribing audio...")
        result = transcriber.transcribe(audio_file)
        
        # Check transcription results
        if "text" in result and result["text"]:
            text_len = len(result["text"])
            segment_count = len(result.get("segments", []))
            print(f"✅ Transcription successful: {text_len} characters, {segment_count} segments")
            print(f"Preview: {result['text'][:100]}...")
            
            # Save transcript to a file for inspection
            transcript_file = "full_transcript_test.txt"
            with open(transcript_file, "w") as f:
                f.write(result["text"])
            print(f"✅ Saved full transcript to: {transcript_file}")
            
            return True
        else:
            print("❌ Transcription failed: No text in result")
            print(f"Result: {result}")
            return False
            
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("Make sure all required packages are installed:")
        print("  python -m pip install yt-dlp openai-whisper ffmpeg-python")
        return False
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    # Print Python environment
    print(f"Python: {sys.version}")
    print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    print(f"PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"FFMPEG_LOCATION: {os.environ.get('FFMPEG_LOCATION', 'Not set')}")
    
    # Run tests
    ffmpeg_ok = test_ffmpeg()
    
    if not ffmpeg_ok:
        print("\n❌ FFmpeg tests failed. Cannot continue with transcription tests.")
        return 1
    
    transcriber_ok = test_youtube_transcriber()
    
    # Print summary
    print("\n=== Test Summary ===")
    print(f"FFmpeg test: {'✅ PASSED' if ffmpeg_ok else '❌ FAILED'}")
    print(f"Transcriber test: {'✅ PASSED' if transcriber_ok else '❌ FAILED'}")
    
    return 0 if ffmpeg_ok and transcriber_ok else 1

if __name__ == "__main__":
    sys.exit(main())
