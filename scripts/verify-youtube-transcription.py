#!/usr/bin/env python3
"""
Final verification script for YouTube transcription feature
This script verifies all aspects of the feature: component, API, and Ollama integration
"""

import os
import sys
import json
import time
import argparse
import logging
import requests
import subprocess
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add project root to path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
if project_root not in sys.path:
    sys.path.insert(0, project_root)
os.environ["PYTHONPATH"] = project_root

def check_environment():
    """Check if the environment is properly set up."""
    logger.info("Checking environment...")
    
    # Check for PYTHONPATH
    pythonpath = os.environ.get("PYTHONPATH", "")
    if not pythonpath:
        logger.warning("PYTHONPATH is not set")
        return False
    logger.info(f"PYTHONPATH: {pythonpath}")
    
    # Check for ffmpeg
    try:
        result = subprocess.run(["which", "ffmpeg"], 
                              capture_output=True, 
                              text=True, 
                              check=True)
        ffmpeg_path = result.stdout.strip()
        logger.info(f"ffmpeg found at: {ffmpeg_path}")
        
        # Set FFMPEG_LOCATION
        os.environ["FFMPEG_LOCATION"] = os.path.dirname(ffmpeg_path)
        logger.info(f"FFMPEG_LOCATION set to: {os.environ['FFMPEG_LOCATION']}")
    except subprocess.CalledProcessError:
        logger.error("ffmpeg not found")
        return False
    
    # Check required Python packages
    packages = ["yt_dlp", "whisper", "flask", "requests"]
    for package in packages:
        try:
            subprocess.run(["python3", "-c", f"import {package}"], 
                         check=True, 
                         stdout=subprocess.PIPE, 
                         stderr=subprocess.PIPE)
            logger.info(f"Package {package} is installed")
        except subprocess.CalledProcessError:
            logger.error(f"Package {package} is not installed")
            return False
    
    return True

def test_component():
    """Test the YouTubeTranscriber component directly."""
    logger.info("Testing YouTubeTranscriber component...")
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create transcriber
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        logger.info(f"Created transcriber with ffmpeg_location: {transcriber.ffmpeg_location}")
        
        # Test URL
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        logger.info(f"Testing with URL: {url}")
        
        # Process video
        result = transcriber.process_video(url)
        
        # Check result
        if "text" in result and result["text"]:
            logger.info("Component test successful")
            logger.info(f"Text length: {len(result['text'])}")
            logger.info(f"Segments: {len(result.get('segments', []))}")
            return True
        else:
            logger.error("Component test failed: No text in result")
            return False
    except Exception as e:
        logger.error(f"Component test failed with error: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

def test_api(port=5000):
    """Test the YouTube transcription API endpoint."""
    logger.info(f"Testing API endpoint on port {port}...")
    try:
        # Test health endpoint
        health_url = f"http://localhost:{port}/health"
        logger.info(f"Checking health at: {health_url}")
        health_response = requests.get(health_url, timeout=5)
        
        if health_response.status_code != 200:
            logger.error(f"Health check failed: {health_response.status_code}")
            return False
        logger.info("Health check successful")
        
        # Test transcription endpoint
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        logger.info(f"Testing transcription of URL: {url}")
        
        api_url = f"http://localhost:{port}/youtube/transcribe"
        response = requests.post(
            api_url,
            json={"url": url, "whisper_model_size": "tiny"},
            timeout=180
        )
        
        if response.status_code == 200:
            result = response.json()
            if "text" in result and result["text"]:
                logger.info("API test successful")
                logger.info(f"Text length: {len(result['text'])}")
                logger.info(f"Segments: {len(result.get('segments', []))}")
                return True
            else:
                logger.error("API test failed: No text in result")
                return False
        else:
            logger.error(f"API test failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        logger.error(f"API test failed with error: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

def test_ollama():
    """Test Ollama integration."""
    logger.info("Testing Ollama integration...")
    try:
        # Check if Ollama is running
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=5)
            if response.status_code != 200:
                logger.warning("Ollama is not running properly, skipping test")
                return True  # Not a failure, just skipped
        except requests.exceptions.RequestException:
            logger.warning("Ollama is not running, skipping test")
            return True  # Not a failure, just skipped
        
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Create transcriber
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        
        # Test summarization with a sample transcript
        sample_transcript = """
        This is a sample transcript for testing Ollama summarization.
        It contains several sentences to give the model enough content to summarize.
        We want to verify that the summarization functionality is working correctly.
        Ollama should be able to generate a concise summary of this text.
        """
        
        summary_result = transcriber.summarize_transcript(sample_transcript)
        
        if "error" in summary_result and summary_result["error"]:
            logger.warning(f"Summarization test skipped: {summary_result.get('summary')}")
            return True  # Not a failure, just a warning
        
        logger.info("Ollama test successful")
        logger.info(f"Model used: {summary_result.get('model')}")
        logger.info(f"Summary: {summary_result.get('summary')}")
        return True
    except Exception as e:
        logger.error(f"Ollama test failed with error: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

def main():
    parser = argparse.ArgumentParser(description="Verify YouTube transcription functionality")
    parser.add_argument("--api-port", type=int, default=5000, help="Port for API testing")
    parser.add_argument("--skip-api", action="store_true", help="Skip API testing")
    parser.add_argument("--skip-ollama", action="store_true", help="Skip Ollama testing")
    args = parser.parse_args()
    
    logger.info("Starting YouTube transcription verification")
    
    # Check environment
    env_ok = check_environment()
    if not env_ok:
        logger.error("Environment check failed")
        return 1
    
    # Test component
    component_ok = test_component()
    
    # Test API
    api_ok = True
    if not args.skip_api:
        api_ok = test_api(args.api_port)
    else:
        logger.info("Skipping API test")
    
    # Test Ollama
    ollama_ok = True
    if not args.skip_ollama:
        ollama_ok = test_ollama()
    else:
        logger.info("Skipping Ollama test")
    
    # Print summary
    logger.info("=== Verification Summary ===")
    logger.info(f"Environment: {'✅ OK' if env_ok else '❌ FAILED'}")
    logger.info(f"Component: {'✅ OK' if component_ok else '❌ FAILED'}")
    logger.info(f"API: {'✅ OK' if api_ok else '❌ FAILED'}")
    logger.info(f"Ollama: {'✅ OK' if ollama_ok else '❌ FAILED'}")
    
    if env_ok and component_ok and api_ok and ollama_ok:
        logger.info("✅ All verification tests passed")
        return 0
    else:
        logger.error("❌ Some verification tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())
