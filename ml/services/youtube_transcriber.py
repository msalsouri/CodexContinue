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
        
        # Ensure ffmpeg is in PATH
        if '/usr/bin' not in os.environ.get('PATH', ''):
            os.environ['PATH'] = f"/usr/bin:{os.environ.get('PATH', '')}"
            
        # Try to read configuration file if it exists
        config_file = os.path.join(os.path.expanduser("~"), ".codexcontinue/config/transcription.env")
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if '=' in line:
                            key, value = line.strip().split('=', 1)
                            if key == "OLLAMA_MODEL" and value:
                                self.ollama_model = value
                                logger.info(f"Using Ollama model from config: {self.ollama_model}")
                            elif key == "OLLAMA_API_URL" and value:
                                self.ollama_api_url = value
                                logger.info(f"Using Ollama API URL from config: {self.ollama_api_url}")
            except Exception as e:
                logger.warning(f"Failed to read configuration file: {str(e)}")
            
        # Set ffmpeg location from environment if available
        self.ffmpeg_location = os.environ.get("FFMPEG_LOCATION", "/usr/bin")
        
        # Verify that ffmpeg and ffprobe are available
        ffmpeg_path = os.path.join(self.ffmpeg_location, "ffmpeg")
        ffprobe_path = os.path.join(self.ffmpeg_location, "ffprobe")
        
        if not os.path.exists(ffmpeg_path):
            logger.warning(f"ffmpeg not found at {ffmpeg_path}")
        if not os.path.exists(ffprobe_path):
            logger.warning(f"ffprobe not found at {ffprobe_path}")
            
        logger.info(f"Using ffmpeg from: {self.ffmpeg_location}")
    
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
            'no_warnings': False,
            'ffmpeg_location': self.ffmpeg_location,  # Use the instance variable
            'verbose': True  # Add verbose output for troubleshooting
        }
        
        logger.info(f"Using ffmpeg_location: {self.ffmpeg_location}")
        
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
            # First check if the model exists
            headers = {"Content-Type": "application/json"}
            model_check = requests.get(f"{self.ollama_api_url}/api/tags")
            
            if model_check.status_code != 200:
                logger.error(f"Error connecting to Ollama API: {model_check.status_code}")
                return {
                    "summary": f"Error connecting to Ollama API: {model_check.status_code}",
                    "error": True
                }
                
            # Check if the configured model exists
            models_json = model_check.json()
            available_models = [model["name"] for model in models_json.get("models", [])]
            
            # If our model doesn't exist, try to find an alternative
            if not available_models:
                logger.error("No models available in Ollama")
                return {
                    "summary": "No language models available in Ollama service",
                    "error": True
                }
                
            if self.ollama_model not in available_models:
                logger.warning(f"Model {self.ollama_model} not found. Looking for alternatives...")
                # Try to find a suitable alternative
                preferred_models = ["llama3", "llama2", "mistral", "codellama"]
                found_model = None
                
                for model in preferred_models:
                    if model in available_models:
                        found_model = model
                        break
                
                if not found_model and available_models:
                    found_model = available_models[0]
                    
                if found_model:
                    logger.info(f"Using alternative model: {found_model}")
                    self.ollama_model = found_model
                else:
                    logger.error("No suitable models found in Ollama")
                    return {
                        "summary": "No suitable language models found in Ollama service",
                        "error": True
                    }
            
            # Now call Ollama API with the selected model
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
