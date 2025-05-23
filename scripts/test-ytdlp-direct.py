#!/usr/bin/env python3
"""
Direct test for YouTube transcriber components
"""

import os
import sys
import subprocess
import yt_dlp
import logging

# Set up logging to a file
logging.basicConfig(
    filename='youtube-transcriber-test.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Make sure ffmpeg is in PATH
os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
os.environ['FFMPEG_LOCATION'] = "/usr/bin"
os.putenv('PATH', f"/usr/bin:{os.environ.get('PATH', '')}")
os.putenv('FFMPEG_LOCATION', "/usr/bin")

def test_environment():
    """Print environment information that might be relevant for troubleshooting."""
    print("\n=== Environment Information ===")
    print(f"PATH: {os.environ.get('PATH', 'Not set')}")
    print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    print(f"Current directory: {os.getcwd()}")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")
    
    # Check ffmpeg
    try:
        ffmpeg_path = subprocess.check_output("which ffmpeg", shell=True).decode().strip()
        print(f"ffmpeg path: {ffmpeg_path}")
    except subprocess.CalledProcessError:
        print("ffmpeg not found in PATH")
    
    try:
        ffprobe_path = subprocess.check_output("which ffprobe", shell=True).decode().strip()
        print(f"ffprobe path: {ffprobe_path}")
    except subprocess.CalledProcessError:
        print("ffprobe not found in PATH")
    
    # Check yt-dlp version
    try:
        yt_dlp_version = subprocess.check_output(["yt-dlp", "--version"], text=True).strip()
        print(f"yt-dlp version: {yt_dlp_version}")
    except:
        print("Could not determine yt-dlp version")

def test_ytdlp_download():
    """Test downloading a YouTube video with yt-dlp."""
    print("\n=== Testing yt-dlp Download ===")
    
    # Create temp directory
    temp_dir = os.path.expanduser("~/ytdlp-test")
    os.makedirs(temp_dir, exist_ok=True)
    print(f"Temporary directory: {temp_dir}")
    
    # Set the URL (use a short video)
    url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
    output_file = os.path.join(temp_dir, "test")
    output_file_mp3 = f"{output_file}.mp3"
    
    print(f"Downloading from: {url}")
    print(f"Output file: {output_file_mp3}")
    
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
        'no_warnings': False,
        'ffmpeg_location': '/usr/bin',  # Explicitly set ffmpeg location
        'verbose': True
    }
    
    # Print options
    print(f"yt-dlp options: {ydl_opts}")
    
    try:
        print("Starting download...")
        # First, try to directly call ffmpeg to see if it works
        subprocess.run(["ffmpeg", "-version"], check=True)
        print("ffmpeg command test successful")
        
        # Download the audio
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        
        if os.path.exists(output_file_mp3):
            print(f"Success! Audio downloaded to: {output_file_mp3}")
            print(f"File size: {os.path.getsize(output_file_mp3)} bytes")
            return True
        else:
            print(f"Error: Output file not found at: {output_file_mp3}")
            print(f"Files in directory: {os.listdir(temp_dir)}")
            return False
            
    except Exception as e:
        print(f"Error during download: {str(e)}")
        return False

if __name__ == "__main__":
    print("=== YouTube Transcriber Component Test ===")
    test_environment()
    success = test_ytdlp_download()
    sys.exit(0 if success else 1)
