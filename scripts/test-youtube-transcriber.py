#!/usr/bin/env python3
"""
Test script for YouTube transcription feature in CodexContinue
"""

import sys
import requests
import json
import argparse
import os

def test_youtube_transcriber(url, generate_summary=False):
    """Test the YouTube transcription feature with a given URL."""
    print(f"Testing YouTube transcription with URL: {url}")
    print(f"Summary generation: {'Enabled' if generate_summary else 'Disabled'}")
    
    try:
        # Set environment variables to ensure proper paths
        if '/usr/bin' not in os.environ.get('PATH', ''):
            os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
        
        # Explicitly set ffmpeg location
        os.environ['FFMPEG_LOCATION'] = '/usr/bin'
        
        # Call the ML service API
        response = requests.post(
            "http://localhost:5000/youtube/transcribe",
            json={"url": url, "generate_summary": generate_summary}
        )
        
        if response.status_code == 200:
            result = response.json()
            
            # Print a summary of the results
            print("\n==== Transcription Results ====")
            print("Status: Success")
            print(f"Source URL: {result.get('source_url', 'N/A')}")
            
            # Print the first 200 characters of the transcript
            text = result.get("text", "")
            print(f"\nTranscript Preview: {text[:200]}..." if text else "No transcript returned")
            
            # Print statistics
            segments = result.get("segments", [])
            print(f"\nTotal Segments: {len(segments)}")
            
            # Write the transcript to a file
            with open("transcript_test_output.txt", "w") as f:
                f.write(text)
            print(f"\nFull transcript saved to: transcript_test_output.txt")
            
            # Handle summary if available
            if generate_summary and "summary" in result:
                summary = result["summary"]
                print("\n==== Summary Results ====")
                summary_text = summary.get("summary", "")
                print(f"Summary Preview: {summary_text[:200]}..." if summary_text else "No summary returned")
                
                # Write the summary to a file
                with open("summary_test_output.txt", "w") as f:
                    f.write(summary_text)
                print(f"\nFull summary saved to: summary_test_output.txt")
                print(f"Summary generated using model: {summary.get('model', 'unknown')}")
            
            return True
        else:
            print(f"\nError: {response.status_code}")
            print(response.text)
            return False
    
    except Exception as e:
        print(f"\nError: {str(e)}")
        return False

if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Test YouTube transcription feature")
    parser.add_argument("--url", default="https://www.youtube.com/watch?v=dQw4w9WgXcQ", 
                        help="YouTube URL to transcribe")
    parser.add_argument("--summarize", action="store_true", 
                        help="Enable summarization using Ollama")
    args = parser.parse_args()
    
    print("YouTube Transcription Feature Test")
    print("==================================")
    
    # Check if the ML service is running
    try:
        response = requests.get("http://localhost:5000/health")
        if response.status_code != 200:
            print("Error: ML service is not running or not accessible.")
            sys.exit(1)
    except Exception:
        print("Error: ML service is not running or not accessible.")
        sys.exit(1)
    
    # Test the transcription
    success = test_youtube_transcriber(args.url, generate_summary=args.summarize)
    
    if success:
        print("\nTest completed successfully!")
    else:
        print("\nTest failed.")
        sys.exit(1)
