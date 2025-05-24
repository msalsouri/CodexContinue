#!/usr/bin/env python3
"""
Comprehensive test for YouTube transcription feature.
This script tests all components of the transcription pipeline:
- ffmpeg installation
- yt-dlp functionality
- Whisper model loading and transcription
- Ollama integration for summarization
- API endpoints
"""

import os
import sys
import json
import time
import logging
import subprocess
import tempfile
import resource
import argparse
import traceback
import requests
from typing import Dict, Any, Optional, List, Tuple
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    filename='transcriber-comprehensive-test.log'
)
logger = logging.getLogger(__name__)
console = logging.StreamHandler()
console.setLevel(logging.INFO)
logger.addHandler(console)

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Set environment variables
os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
os.environ['FFMPEG_LOCATION'] = "/usr/bin"

# Constants
ML_SERVICE_URL = "http://localhost:5000"
TEST_VIDEO_SHORT = "https://www.youtube.com/watch?v=9bZkp7q19f0"  # Gangnam Style (short)
TEST_VIDEO_MEDIUM = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  # Rick Roll (medium)
TIMEOUT_SECONDS = 300  # 5 minutes timeout


def print_section(title):
    """Print a section title."""
    print(f"\n{'=' * 50}")
    print(f"  {title}")
    print(f"{'=' * 50}\n")


def test_dependencies():
    """Test if all required dependencies are installed."""
    print_section("Testing Dependencies")
    
    dependencies = {
        "ffmpeg": ["ffmpeg", "-version"],
        "python-packages": ["pip", "list"]
    }
    
    results = {}
    
    for name, command in dependencies.items():
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            print(f"✅ {name} is installed")
            if name == "python-packages":
                # Check for required packages
                output = result.stdout
                required_packages = ["yt-dlp", "whisper", "flask"]
                for package in required_packages:
                    if package in output:
                        print(f"  ✅ {package} is installed")
                    else:
                        print(f"  ❌ {package} not found")
            results[name] = True
        except Exception as e:
            print(f"❌ {name} test failed: {e}")
            results[name] = False
    
    return all(results.values())


def test_ffmpeg_functionality():
    """Test if ffmpeg works correctly by creating a test file."""
    print_section("Testing FFmpeg Functionality")
    
    try:
        with tempfile.NamedTemporaryFile(suffix='.mp4') as temp_video:
            cmd = [
                "ffmpeg", "-y", "-f", "lavfi", "-i", 
                "testsrc=duration=5:size=640x480:rate=30",
                "-c:v", "libx264", temp_video.name
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # Check if file was created
            file_size = os.path.getsize(temp_video.name)
            if file_size > 0:
                print(f"✅ FFmpeg created a test video file of {file_size} bytes")
                return True
            else:
                print("❌ FFmpeg created a zero-byte file")
                return False
    except Exception as e:
        print(f"❌ FFmpeg functionality test failed: {e}")
        return False


def check_ml_service(start_if_not_running=True):
    """Check if the ML service is running and start it if requested."""
    print_section("Checking ML Service")
    
    try:
        response = requests.get(f"{ML_SERVICE_URL}/health", timeout=2)
        if response.status_code == 200:
            print(f"✅ ML service is running at {ML_SERVICE_URL}")
            return True
    except:
        print(f"❌ ML service is not running at {ML_SERVICE_URL}")
        
        if start_if_not_running:
            print("Starting ML service...")
            try:
                # Check if the service is already running
                try:
                    subprocess.run(["pgrep", "-f", "python.*ml/app.py"], 
                                  check=True, capture_output=True)
                    print("ML service process exists but is not responding.")
                except subprocess.CalledProcessError:
                    # Start the service
                    env = os.environ.copy()
                    env["PYTHONPATH"] = project_root
                    
                    process = subprocess.Popen(
                        ["python3", os.path.join(project_root, "ml/app.py")],
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    
                    # Wait for the service to start
                    time.sleep(5)
                    
                    # Check if it's running
                    try:
                        response = requests.get(f"{ML_SERVICE_URL}/health", timeout=2)
                        if response.status_code == 200:
                            print(f"✅ Started ML service at {ML_SERVICE_URL}")
                            return True
                    except:
                        print("❌ Failed to start ML service")
                        return False
            except Exception as e:
                print(f"❌ Error starting ML service: {e}")
                return False
    
    return False


def test_transcription_api(video_url=TEST_VIDEO_SHORT, generate_summary=False):
    """Test the transcription API endpoint."""
    print_section(f"Testing Transcription API with {'summary' if generate_summary else 'no summary'}")
    
    try:
        # Make the API request
        print(f"Making request to {ML_SERVICE_URL}/youtube/transcribe")
        print(f"URL: {video_url}")
        print(f"Generate summary: {generate_summary}")
        
        start_time = time.time()
        response = requests.post(
            f"{ML_SERVICE_URL}/youtube/transcribe",
            json={
                "url": video_url,
                "generate_summary": generate_summary
            },
            timeout=TIMEOUT_SECONDS
        )
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            
            # Check the result
            transcript_text = result.get("text", "")
            segments = result.get("segments", [])
            
            print(f"✅ API transcription successful in {elapsed_time:.2f} seconds")
            print(f"✅ Transcript length: {len(transcript_text)} characters")
            print(f"✅ Number of segments: {len(segments)}")
            print(f"✅ First 100 characters: {transcript_text[:100]}...")
            
            # Check summary if requested
            if generate_summary:
                summary = result.get("summary", {})
                summary_text = summary.get("summary", "")
                model = summary.get("model", "unknown")
                
                if summary_text:
                    print(f"✅ Summary generated using model: {model}")
                    print(f"✅ Summary length: {len(summary_text)} characters")
                    print(f"✅ Summary preview: {summary_text[:100]}...")
                    
                    # Save summary to file for inspection
                    with open("test_summary_output.txt", "w") as f:
                        f.write(summary_text)
                    print(f"✅ Saved summary to test_summary_output.txt")
                else:
                    print("❌ No summary text found in response")
            
            # Save transcript to file for inspection
            with open("transcript_test_output.txt", "w") as f:
                f.write(transcript_text)
            print(f"✅ Saved transcript to transcript_test_output.txt")
            
            return True
        else:
            print(f"❌ API transcription failed: {response.status_code}")
            print(f"Error: {response.text}")
            return False
    except requests.exceptions.Timeout:
        print(f"❌ API request timed out after {TIMEOUT_SECONDS} seconds")
        return False
    except Exception as e:
        print(f"❌ API test failed with error: {e}")
        traceback.print_exc()
        return False


def test_component_directly():
    """Test the YouTubeTranscriber component directly."""
    print_section("Testing YouTubeTranscriber Component Directly")
    
    try:
        # Import here to avoid errors if modules not installed
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create transcriber instance
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        print(f"✅ Successfully created YouTubeTranscriber instance")
        
        # Test downloading audio
        print(f"Testing download from {TEST_VIDEO_SHORT}")
        audio_file = transcriber.download_audio(TEST_VIDEO_SHORT)
        
        if os.path.exists(audio_file):
            file_size = os.path.getsize(audio_file)
            print(f"✅ Audio downloaded successfully: {audio_file} ({file_size} bytes)")
        else:
            print(f"❌ Audio download failed")
            return False
        
        # Test transcription
        print("Testing transcription...")
        result = transcriber.transcribe(audio_file)
        
        if "text" in result and result["text"]:
            print(f"✅ Transcription successful")
            print(f"✅ Transcript length: {len(result['text'])} characters")
            print(f"✅ Number of segments: {len(result.get('segments', []))}")
            print(f"✅ Preview: {result['text'][:100]}...")
            
            # Save full transcript to file
            with open("full_transcript_test.txt", "w") as f:
                f.write(result["text"])
            print(f"✅ Saved full transcript to full_transcript_test.txt")
            
            return True
        else:
            print("❌ Transcription failed: No text in result")
            return False
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("Make sure all required packages are installed:")
        print("  pip install yt-dlp openai-whisper ffmpeg-python")
        return False
    except Exception as e:
        print(f"❌ Component test failed with error: {e}")
        traceback.print_exc()
        return False


def measure_resource_usage(video_url=TEST_VIDEO_SHORT):
    """Measure CPU, memory and disk usage during transcription."""
    print_section("Measuring Resource Usage During Transcription")
    
    try:
        # Import here to avoid errors if modules not installed
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create temp dir to measure disk usage
        temp_dir = os.path.join(os.path.expanduser("~"), ".codexcontinue/temp")
        os.makedirs(temp_dir, exist_ok=True)
        
        # Get initial disk usage
        initial_disk = subprocess.check_output(["du", "-s", temp_dir])
        initial_disk = int(initial_disk.decode().split()[0])
        
        # Track memory and CPU
        initial_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        initial_cpu = time.process_time()
        
        # Create transcriber and process video
        start_time = time.time()
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        result = transcriber.process_video(video_url)
        elapsed_time = time.time() - start_time
        
        # Measure final resource usage
        final_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        final_cpu = time.process_time()
        final_disk = subprocess.check_output(["du", "-s", temp_dir])
        final_disk = int(final_disk.decode().split()[0])
        
        # Calculate differences
        memory_used = (final_memory - initial_memory) / 1024  # Convert to MB
        cpu_used = final_cpu - initial_cpu
        disk_used = final_disk - initial_disk  # In KB
        
        # Print results
        print(f"Processing completed in {elapsed_time:.2f} seconds")
        print(f"Memory used: {memory_used:.2f} MB")
        print(f"CPU time used: {cpu_used:.2f} seconds")
        print(f"Disk space used: {disk_used} KB")
        print(f"Transcript length: {len(result.get('text', ''))} characters")
        
        # Save resource measurements to file
        resource_data = {
            "video_url": video_url,
            "elapsed_seconds": elapsed_time,
            "memory_used_mb": memory_used,
            "cpu_seconds": cpu_used,
            "disk_used_kb": disk_used,
            "transcript_length": len(result.get("text", "")),
            "segments_count": len(result.get("segments", []))
        }
        
        with open("resource_usage_test.json", "w") as f:
            json.dump(resource_data, f, indent=2)
        print("✅ Saved resource measurements to resource_usage_test.json")
        
        return True
    except Exception as e:
        print(f"❌ Resource measurement test failed: {e}")
        traceback.print_exc()
        return False


def check_ollama_connection():
    """Check if Ollama is running and what models are available."""
    print_section("Checking Ollama Service")
    
    ollama_api_url = os.environ.get("OLLAMA_API_URL", "http://localhost:11434")
    print(f"Checking Ollama at {ollama_api_url}")
    
    try:
        response = requests.get(f"{ollama_api_url}/api/tags", timeout=5)
        if response.status_code == 200:
            models_json = response.json()
            available_models = [model["name"] for model in models_json.get("models", [])]
            
            if available_models:
                print(f"✅ Ollama is running with {len(available_models)} models:")
                for model in available_models:
                    print(f"  - {model}")
                
                # Select a suitable model
                preferred_models = ["codexcontinue", "llama3", "llama2", "mistral"]
                selected_model = None
                
                for model in preferred_models:
                    if model in available_models:
                        selected_model = model
                        break
                
                if not selected_model and available_models:
                    selected_model = available_models[0]
                
                if selected_model:
                    print(f"✅ Selected model for testing: {selected_model}")
                    os.environ["OLLAMA_MODEL"] = selected_model
                    return True, selected_model
                else:
                    print("❌ No suitable models found")
                    return False, None
            else:
                print("❌ Ollama is running but no models available")
                return False, None
        else:
            print(f"❌ Error connecting to Ollama: {response.status_code}")
            return False, None
    except Exception as e:
        print(f"❌ Ollama connection test failed: {e}")
        return False, None


def main():
    parser = argparse.ArgumentParser(description="Comprehensive YouTube transcription feature test")
    parser.add_argument("--start-ml", action="store_true", 
                      help="Start the ML service if not running")
    parser.add_argument("--skip-resource-test", action="store_true",
                      help="Skip resource usage measurement test")
    parser.add_argument("--summary", action="store_true",
                      help="Test summarization with Ollama as well")
    args = parser.parse_args()
    
    # Store test results
    results = {}
    
    print("\nStarting Comprehensive YouTube Transcription Test")
    print(f"Current time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Python version: {sys.version}")
    print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
    
    # Run tests
    try:
        # Test dependencies
        results["dependencies"] = test_dependencies()
        
        # Test ffmpeg functionality
        results["ffmpeg"] = test_ffmpeg_functionality()
        
        # Check Ollama if summary requested
        if args.summary:
            results["ollama"], selected_model = check_ollama_connection()
            if not results["ollama"]:
                print("Warning: Ollama tests will be skipped or may fail")
        
        # Check ML service
        results["ml_service"] = check_ml_service(start_if_not_running=args.start_ml)
        
        if results["ml_service"]:
            # Test API transcription
            results["api_transcription"] = test_transcription_api(
                video_url=TEST_VIDEO_SHORT, 
                generate_summary=False
            )
            
            # Test API transcription with summary if Ollama is available
            if args.summary:
                results["api_summary"] = test_transcription_api(
                    video_url=TEST_VIDEO_SHORT,
                    generate_summary=True
                )
        
        # Test component directly
        results["component"] = test_component_directly()
        
        # Measure resource usage
        if not args.skip_resource_test:
            results["resource_usage"] = measure_resource_usage()
        
        # Print summary
        print_section("Test Summary")
        for test, result in results.items():
            print(f"{test}: {'✅ PASSED' if result else '❌ FAILED'}")
        
        # Determine overall result
        essential_tests = ["dependencies", "ffmpeg", "component"]
        if results["ml_service"]:
            essential_tests.append("api_transcription")
            
        overall_result = all(results.get(test, False) for test in essential_tests)
        print(f"\nOverall result: {'✅ PASSED' if overall_result else '❌ FAILED'}")
        
        # Export results to file
        with open("transcription_test_results.json", "w") as f:
            json.dump(results, f, indent=2)
        print("Saved test results to transcription_test_results.json")
        
        return 0 if overall_result else 1
    except Exception as e:
        print(f"Test suite failed with error: {e}")
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
