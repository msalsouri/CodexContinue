#!/usr/bin/env python3
"""
YouTube Transcription Service for CodexContinue
"""

import os
import tempfile
import subprocess
from typing import Dict, Any, Optional
import logging
import yt_dlp
import whisper
import json
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class YouTubeTranscriber:
    def __init__(self, whisper_model_size: str = "base"):
        """Initialize the YouTube transcriber with the specified Whisper model size."""
        self.whisper_model_size = whisper_model_size
        self.model = None  # Lazy load the model when needed
        
        # Create temp directory for downloaded files
        self.temp_dir = os.path.join(os.path.expanduser("~"), ".codexcontinue/temp/youtube")
        os.makedirs(self.temp_dir, exist_ok=True)
        
        # Default Ollama endpoint
        self.ollama_api_url = os.environ.get("OLLAMA_API_URL", "http://localhost:11434")
        self.ollama_model = os.environ.get("OLLAMA_MODEL", "codexcontinue")
    
    def _load_model(self):
        """Load the Whisper model if not already loaded."""
        if self.model is None:
            logger.info(f"Loading Whisper model: {self.whisper_model_size}")
            try:
                # Force CPU usage instead of GPU to avoid CUDA/NumPy errors
                self.model = whisper.load_model(self.whisper_model_size, device="cpu")
                logger.info("Whisper model loaded successfully on CPU")
            except Exception as e:
                logger.error(f"Error loading model: {str(e)}")
                raise
        return self.model
    
    def download_audio(self, url: str) -> str:
        """Download audio from a YouTube video."""
        logger.info(f"Downloading audio from: {url}")
        
        # Create a unique filename based on the video ID
        video_id = url.split("v=")[1].split("&")[0] if "v=" in url else url.split("/")[-1]
        output_file = os.path.join(self.temp_dir, f"{video_id}")
        output_file_mp3 = f"{output_file}.mp3"
        
        if os.path.exists(output_file_mp3):
            logger.info(f"Audio file already exists: {output_file_mp3}")
            return output_file_mp3
        
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
            'no_warnings': False
        }
        
        # Download the audio
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        
        # Check if the file exists after download
        if not os.path.exists(output_file_mp3):
            logger.error(f"Downloaded file not found at: {output_file_mp3}")
            # List files in the temp directory to debug
            logger.info(f"Files in temp directory: {os.listdir(self.temp_dir)}")
        else:
            logger.info(f"Audio downloaded successfully: {output_file_mp3}")
            
        return output_file_mp3
    
    def transcribe(self, audio_file: str, language: Optional[str] = None) -> Dict[str, Any]:
        """Transcribe the audio file using Whisper."""
        logger.info(f"Transcribing audio file: {audio_file}")
        
        # Load the model
        model = self._load_model()
        
        # Transcribe
        transcription_options = {}
        if language:
            transcription_options["language"] = language
            
        result = model.transcribe(audio_file, **transcription_options)
        
        logger.info("Transcription completed successfully")
        return result
    
    def summarize_transcript(self, transcript: str, max_length: Optional[int] = 500) -> Dict[str, Any]:
        """Summarize the transcript using Ollama.
        
        Args:
            transcript (str): The transcript text to summarize
            max_length (int, optional): Maximum length of the summary in words. Defaults to 500.
            
        Returns:
            Dict[str, Any]: Dictionary containing the summary and metadata
        """
        logger.info(f"Summarizing transcript with Ollama using model: {self.ollama_model}")
        
        # Prepare the prompt for summarization
        prompt = f"""Please provide a concise summary of the following transcript.
Keep the summary under {max_length} words and focus on the key points.

TRANSCRIPT:
{transcript}

SUMMARY:"""
        
        try:
            # Call Ollama API
            headers = {"Content-Type": "application/json"}
            data = {
                "model": self.ollama_model,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.3,
                    "top_p": 0.9,
                }
            }
            
            response = requests.post(
                f"{self.ollama_api_url}/api/generate",
                headers=headers,
                data=json.dumps(data)
            )
            
            if response.status_code == 200:
                result = response.json()
                summary = result.get("response", "").strip()
                logger.info("Summarization completed successfully")
                
                return {
                    "summary": summary,
                    "model": self.ollama_model,
                    "tokens_generated": result.get("eval_count", 0)
                }
            else:
                error_msg = f"Ollama API error: {response.status_code} - {response.text}"
                logger.error(error_msg)
                return {
                    "summary": f"Error generating summary: {error_msg}",
                    "error": True
                }
                
        except Exception as e:
            logger.error(f"Error summarizing transcript: {str(e)}")
            return {
                "summary": f"Error generating summary: {str(e)}",
                "error": True
            }
    
    def process_video(self, url: str, language: Optional[str] = None, 
                     generate_summary: bool = False) -> Dict[str, Any]:
        """Download a YouTube video's audio and transcribe it.
        
        Args:
            url (str): YouTube video URL
            language (Optional[str], optional): Language code for transcription. Defaults to None.
            generate_summary (bool, optional): Whether to generate a summary. Defaults to False.
            
        Returns:
            Dict[str, Any]: Dictionary containing transcription results and optional summary
        """
        try:
            # Download the audio
            audio_file = self.download_audio(url)
            
            # Transcribe the audio
            result = self.transcribe(audio_file, language)
            
            # Add metadata
            result["source_url"] = url
            result["audio_file"] = audio_file
            
            # Generate summary if requested
            if generate_summary and result.get("text"):
                summary_result = self.summarize_transcript(result["text"])
                result["summary"] = summary_result
            
            return result
        except Exception as e:
            logger.error(f"Error processing video: {str(e)}")
            raise
