#!/usr/bin/env python3
"""
Simple test script to verify yt-dlp functionality without using the full transcriber.
This helps isolate issues with YouTube video downloading vs. transcription.
"""

import os
import sys
import tempfile
from pathlib import Path

def test_ytdlp():
    """Test basic yt-dlp functionality."""
    # Verify yt-dlp is installed
    try:
        import yt_dlp
        print("✓ yt-dlp is installed")
    except ImportError:
        print("✗ yt-dlp is not installed. Try: pip install yt-dlp")
        return False
    
    # Verify ffmpeg is in path
    ffmpeg_path = os.environ.get("FFMPEG_LOCATION", "/usr/bin")
    if not os.path.exists(os.path.join(ffmpeg_path, "ffmpeg")):
        print(f"✗ ffmpeg not found at {ffmpeg_path}")
        return False
    
    print(f"✓ ffmpeg found at {ffmpeg_path}")
    
    # Test downloading a short YouTube video
    print("Testing YouTube download with a short test video...")
    test_url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"  # First YouTube video ever
    
    with tempfile.TemporaryDirectory() as temp_dir:
        output_file = os.path.join(temp_dir, "test_video")
        output_file_mp3 = f"{output_file}.mp3"
        
        # Configure yt-dlp options
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': output_file,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
            'quiet': False,
            'ffmpeg_location': ffmpeg_path,
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([test_url])
            
            if os.path.exists(output_file_mp3):
                file_size = Path(output_file_mp3).stat().st_size
                print(f"✓ Download successful! Audio file size: {file_size/1024:.1f} KB")
                return True
            else:
                print(f"✗ Download failed - file not found: {output_file_mp3}")
                print(f"Files in temp directory: {os.listdir(temp_dir)}")
                return False
        except Exception as e:
            print(f"✗ Error downloading: {str(e)}")
            return False

def test_whisper():
    """Test basic whisper functionality."""
    try:
        import whisper
        print("✓ whisper is installed")
        
        print("Testing Whisper model loading (tiny model)...")
        model = whisper.load_model("tiny", device="cpu")
        print(f"✓ Whisper model loaded successfully: {model.device}")
        return True
    except ImportError:
        print("✗ whisper is not installed. Try: pip install openai-whisper")
        return False
    except Exception as e:
        print(f"✗ Error loading Whisper model: {str(e)}")
        return False

if __name__ == "__main__":
    print("=== Testing YouTube Transcription Components ===")
    yt_success = test_ytdlp()
    print()
    whisper_success = test_whisper()
    
    if yt_success and whisper_success:
        print("\n✓ All components are working correctly!")
        sys.exit(0)
    else:
        print("\n✗ Some components failed. Check the logs above.")
        sys.exit(1)
