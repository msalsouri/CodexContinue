#!/usr/bin/env python3
"""
Test script for Ollama integration with YouTube transcription
"""
import os
import sys
import json
import requests
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add the project root to the path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
sys.path.insert(0, project_root)
os.environ["PYTHONPATH"] = project_root

def check_ollama():
    """Check if Ollama is running and which models are available."""
    logger.info("Checking Ollama service...")
    
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        
        if response.status_code == 200:
            models = response.json().get("models", [])
            
            if models:
                logger.info(f"✅ Ollama is running with {len(models)} models:")
                for model in models:
                    logger.info(f"  - {model['name']}")
                return True, models
            else:
                logger.info("⚠️ Ollama is running but no models are available")
                return True, []
        else:
            logger.error(f"❌ Ollama returned error: {response.status_code}")
            return False, []
    except Exception as e:
        logger.error(f"❌ Failed to connect to Ollama: {e}")
        return False, []

def test_summarization():
    """Test the summarization capability using YouTubeTranscriber."""
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        logger.info("Creating YouTubeTranscriber instance...")
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        
        # Check the Ollama model configuration
        logger.info(f"Configured Ollama model: {transcriber.ollama_model}")
        logger.info(f"Configured Ollama API URL: {transcriber.ollama_api_url}")
        
        # Use a sample transcript to test summarization
        sample_transcript = """
        This is a test transcript for summarization. It discusses various topics including:
        1. The importance of artificial intelligence in modern society
        2. How machine learning is transforming businesses
        3. The ethical considerations of AI development
        4. Future trends in natural language processing
        
        Researchers around the world are working on improving AI models and making them more accessible.
        These improvements will lead to better user experiences and more powerful applications.
        
        However, there are concerns about privacy, bias, and the potential for misuse.
        It's essential that we develop strong ethical guidelines and regulations for AI systems.
        """
        
        logger.info("Testing summarization with sample transcript...")
        summary_result = transcriber.summarize_transcript(sample_transcript)
        
        if "error" in summary_result and summary_result["error"]:
            logger.error(f"❌ Summarization failed: {summary_result.get('summary')}")
            return False
        
        logger.info("✅ Summarization successful:")
        logger.info(f"Model used: {summary_result.get('model')}")
        logger.info(f"Summary: {summary_result.get('summary')}")
        
        # Save the results
        with open("summarization_test_result.json", "w") as f:
            json.dump(summary_result, f, indent=2)
        logger.info("Results saved to summarization_test_result.json")
        
        return True
    except Exception as e:
        logger.error(f"❌ Error testing summarization: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

def test_end_to_end_with_summary():
    """Test the complete transcription and summarization flow."""
    try:
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        logger.info("Testing end-to-end transcription and summarization...")
        transcriber = YouTubeTranscriber(whisper_model_size="tiny")
        
        # Use a short video for testing
        url = "https://www.youtube.com/watch?v=9bZkp7q19f0"
        logger.info(f"Processing video: {url}")
        
        result = transcriber.process_video(url, generate_summary=True)
        
        if "text" in result and result["text"] and "summary" in result:
            logger.info("✅ End-to-end test successful:")
            logger.info(f"Transcript length: {len(result['text'])} characters")
            logger.info(f"Segments: {len(result.get('segments', []))}")
            
            summary_data = result["summary"]
            if "error" in summary_data and summary_data["error"]:
                logger.warning(f"⚠️ Summary generated with error: {summary_data.get('summary')}")
            else:
                logger.info(f"Summary model: {summary_data.get('model')}")
                logger.info(f"Summary: {summary_data.get('summary')[:100]}...")
            
            # Save the results
            with open("end_to_end_test_result.json", "w") as f:
                json.dump(result, f, indent=2)
            logger.info("Results saved to end_to_end_test_result.json")
            
            return True
        else:
            logger.error("❌ End-to-end test failed: Missing transcript or summary")
            return False
    except Exception as e:
        logger.error(f"❌ Error in end-to-end test: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

def main():
    """Run the tests."""
    logger.info("=== Ollama Integration Test for YouTube Transcription ===")
    
    # Check if Ollama is running
    ollama_running, models = check_ollama()
    
    if not ollama_running:
        logger.warning("⚠️ Ollama is not running, summarization tests may fail")
    
    # Test summarization
    summarization_ok = test_summarization()
    logger.info(f"Summarization test: {'✅ PASSED' if summarization_ok else '❌ FAILED'}")
    
    # Test end-to-end flow
    end_to_end_ok = test_end_to_end_with_summary()
    logger.info(f"End-to-end test: {'✅ PASSED' if end_to_end_ok else '❌ FAILED'}")
    
    # Overall result
    overall_ok = summarization_ok and end_to_end_ok
    logger.info(f"\nOverall result: {'✅ PASSED' if overall_ok else '❌ FAILED'}")
    
    return 0 if overall_ok else 1

if __name__ == "__main__":
    sys.exit(main())
