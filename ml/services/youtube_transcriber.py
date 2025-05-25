#!/usr/bin/env python3
"""
YouTube Transcription Service for CodexContinue
"""

import os
import tempfile
import subprocess
from typing import Dict, Any, Optional
import logging
import json
import requests
import glob
import importlib.util
import time
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Check required dependencies
def check_dependencies():
    """Check if required dependencies are installed."""
    missing_deps = []
    
    # Check for yt-dlp
    if importlib.util.find_spec("yt_dlp") is None:
        missing_deps.append("yt-dlp")
    
    # Check for whisper
    if importlib.util.find_spec("whisper") is None:
        missing_deps.append("openai-whisper")
    
    if missing_deps:
        logger.error(f"Missing required dependencies: {', '.join(missing_deps)}")
        logger.error("Please install missing dependencies with: pip install " + " ".join(missing_deps))
        return False
    
    # Import dependencies only after checking they exist
    return True

# Only import dependencies if they're available
if check_dependencies():
    import yt_dlp
    import whisper
else:
    logger.warning("Running with limited functionality due to missing dependencies")

class YouTubeTranscriber:
    def __init__(self, whisper_model_size: str = "base", use_gpu: bool = False):
        """Initialize the YouTube transcriber with the specified Whisper model size.
        
        Args:
            whisper_model_size (str): Size of the Whisper model to use ('tiny', 'base', 'small', 'medium', 'large')
            use_gpu (bool): Whether to use GPU for transcription if available
        """
        self.whisper_model_size = whisper_model_size
        self.use_gpu = use_gpu
        self.model = None  # Lazy load the model when needed
        
        # Create temp directory for downloaded files
        self.temp_dir = os.path.join(os.path.expanduser("~"), ".codexcontinue/temp/youtube")
        os.makedirs(self.temp_dir, exist_ok=True)
        
        # Default Ollama endpoint
        self.ollama_api_url = os.environ.get("OLLAMA_API_URL", "http://localhost:11434")
        self.ollama_model = os.environ.get("OLLAMA_MODEL", "codexcontinue")
        
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
        
        # Find ffmpeg in standard locations
        self.ffmpeg_location = self._find_ffmpeg()
        
        # Verify that ffmpeg and ffprobe are available
        ffmpeg_path = os.path.join(self.ffmpeg_location, "ffmpeg")
        ffprobe_path = os.path.join(self.ffmpeg_location, "ffprobe")
        
        if not os.path.exists(ffmpeg_path):
            logger.warning(f"ffmpeg not found at {ffmpeg_path}")
        if not os.path.exists(ffprobe_path):
            logger.warning(f"ffprobe not found at {ffprobe_path}")
            
        logger.info(f"Using ffmpeg from: {self.ffmpeg_location}")
        
        # Update environment variables
        self._update_environment_paths()
        
        # Clean up old temporary files
        self._cleanup_old_files()
    
    def _cleanup_old_files(self, max_age_days: int = 7):
        """Clean up old temporary files that are older than max_age_days."""
        try:
            logger.info(f"Cleaning up temporary files older than {max_age_days} days")
            now = datetime.now()
            count = 0
            
            for file_path in glob.glob(os.path.join(self.temp_dir, "*")):
                # Get file modification time
                mtime = os.path.getmtime(file_path)
                mod_time = datetime.fromtimestamp(mtime)
                
                # If file is older than max_age_days, delete it
                if now - mod_time > timedelta(days=max_age_days):
                    os.remove(file_path)
                    count += 1
                    logger.debug(f"Removed old file: {file_path}")
            
            if count > 0:
                logger.info(f"Cleaned up {count} old temporary files")
        except Exception as e:
            logger.warning(f"Error cleaning up temporary files: {str(e)}")
    
    def _find_ffmpeg(self):
        """Find ffmpeg in standard locations or from environment variable."""
        # First check environment variable
        if "FFMPEG_LOCATION" in os.environ and os.environ["FFMPEG_LOCATION"]:
            ffmpeg_path = os.environ["FFMPEG_LOCATION"]
            if os.path.exists(os.path.join(ffmpeg_path, "ffmpeg")):
                return ffmpeg_path
        
        # Check standard locations
        standard_locations = ["/usr/bin", "/usr/local/bin", "/opt/homebrew/bin", "/bin"]
        for location in standard_locations:
            if os.path.exists(os.path.join(location, "ffmpeg")):
                return location
        
        # Default to /usr/bin if nothing found (will likely fail later)
        logger.warning("ffmpeg not found in standard locations, defaulting to /usr/bin")
        return "/usr/bin"
    
    def _update_environment_paths(self):
        """Update environment variables to include ffmpeg path."""
        # Update PATH environment variable
        if self.ffmpeg_location not in os.environ.get("PATH", ""):
            os.environ["PATH"] = f"{self.ffmpeg_location}:{os.environ.get('PATH', '')}"
        
        # Set FFMPEG_LOCATION environment variable
        os.environ["FFMPEG_LOCATION"] = self.ffmpeg_location
        
        # Also set for subprocess calls
        os.putenv("PATH", os.environ["PATH"])
        os.putenv("FFMPEG_LOCATION", self.ffmpeg_location)
        
        logger.info(f"Updated environment PATH: {os.environ['PATH']}")
        logger.info(f"Updated FFMPEG_LOCATION: {os.environ['FFMPEG_LOCATION']}")
    
    def _load_model(self):
        """Load the Whisper model if not already loaded."""
        if self.model is None:
            logger.info(f"Loading Whisper model: {self.whisper_model_size}")
            try:
                # Determine device based on configuration and availability
                device = "cpu"
                if self.use_gpu:
                    try:
                        import torch
                        if torch.cuda.is_available():
                            device = "cuda"
                            logger.info("CUDA is available, using GPU for transcription")
                        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
                            device = "mps"
                            logger.info("MPS is available, using Apple Silicon GPU for transcription")
                    except ImportError:
                        logger.warning("Could not import torch to check GPU availability, defaulting to CPU")
                
                logger.info(f"Loading Whisper model on device: {device}")
                self.model = whisper.load_model(self.whisper_model_size, device=device)
                logger.info(f"Whisper model loaded successfully on {device}")
            except Exception as e:
                logger.error(f"Error loading model: {str(e)}")
                raise
        return self.model
    
    def download_audio(self, url: str) -> str:
        """Download audio from a YouTube video."""
        logger.info(f"Downloading audio from: {url}")
        
        # Ensure yt-dlp is available
        if 'yt_dlp' not in globals():
            raise ImportError("yt-dlp is not installed. Please install it with: pip install yt-dlp")
        
        # Create a unique filename based on the video ID
        video_id = url.split("v=")[1].split("&")[0] if "v=" in url else url.split("/")[-1]
        output_file = os.path.join(self.temp_dir, f"{video_id}")
        output_file_mp3 = f"{output_file}.mp3"
        
        if os.path.exists(output_file_mp3):
            logger.info(f"Audio file already exists: {output_file_mp3}")
            # Update file access time to prevent early cleanup
            os.utime(output_file_mp3, None)
            return output_file_mp3
        
        # Ensure ffmpeg is properly set in the environment
        os.environ["PATH"] = f"{self.ffmpeg_location}:{os.environ.get('PATH', '')}"
        os.environ["FFMPEG_LOCATION"] = self.ffmpeg_location
        os.putenv("PATH", f"{self.ffmpeg_location}:{os.environ.get('PATH', '')}")
        os.putenv("FFMPEG_LOCATION", self.ffmpeg_location)
        
        # Verify ffmpeg executable exists at the specified location
        ffmpeg_exe = os.path.join(self.ffmpeg_location, "ffmpeg")
        ffprobe_exe = os.path.join(self.ffmpeg_location, "ffprobe")
        if os.path.exists(ffmpeg_exe) and os.path.exists(ffprobe_exe):
            logger.info(f"Verified ffmpeg exists at: {ffmpeg_exe}")
            logger.info(f"Verified ffprobe exists at: {ffprobe_exe}")
        else:
            missing = []
            if not os.path.exists(ffmpeg_exe):
                missing.append("ffmpeg")
            if not os.path.exists(ffprobe_exe):
                missing.append("ffprobe")
            error_msg = f"Missing required executables in {self.ffmpeg_location}: {', '.join(missing)}"
            logger.error(error_msg)
            raise FileNotFoundError(error_msg)
        
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
            'ffmpeg_location': self.ffmpeg_location,
            'verbose': True  # Add verbose output for troubleshooting
        }
        
        logger.info(f"Using ffmpeg_location: {self.ffmpeg_location}")
        logger.info(f"Environment PATH: {os.environ.get('PATH')}")
        
        # Download the audio
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
        except Exception as e:
            logger.error(f"Error downloading audio: {str(e)}")
            raise RuntimeError(f"Failed to download audio from YouTube: {str(e)}")
        
        # Check if the file exists after download
        if not os.path.exists(output_file_mp3):
            logger.error(f"Downloaded file not found at: {output_file_mp3}")
            # List files in the temp directory to debug
            logger.info(f"Files in temp directory: {os.listdir(self.temp_dir)}")
            raise FileNotFoundError(f"Downloaded audio file not found at: {output_file_mp3}")
        else:
            logger.info(f"Audio downloaded successfully: {output_file_mp3}")
            
        return output_file_mp3
    
    def transcribe(self, audio_file: str, language: Optional[str] = None) -> Dict[str, Any]:
        """Transcribe the audio file using Whisper."""
        logger.info(f"Transcribing audio file: {audio_file}")
        
        # Ensure whisper is available
        if 'whisper' not in globals():
            raise ImportError("whisper is not installed. Please install it with: pip install openai-whisper")
        
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
            try:
                model_check = requests.get(f"{self.ollama_api_url}/api/tags", timeout=5)
            except requests.exceptions.RequestException as e:
                logger.error(f"Error connecting to Ollama API: {str(e)}")
                return {
                    "summary": f"Error connecting to Ollama API: {str(e)}",
                    "error": True
                }
            
            if model_check.status_code != 200:
                logger.error(f"Error connecting to Ollama API: {model_check.status_code}")
                return {
                    "summary": f"Error connecting to Ollama API: {model_check.status_code}",
                    "error": True
                }
                
            # Check if the configured model exists
            models_json = model_check.json()
            available_models = [model["name"] for model in models_json.get("models", [])]
            
            # Log available models for debugging
            logger.info(f"Available Ollama models: {available_models}")
            
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
                        logger.info(f"Found alternative model: {model}")
                        break
                
                if not found_model and available_models:
                    found_model = available_models[0]
                    logger.info(f"Using first available model: {found_model}")
                    
                if found_model:
                    logger.info(f"Using alternative model: {found_model}")
                    self.ollama_model = found_model
                    
                    # Also update the environment variable for future calls
                    os.environ["OLLAMA_MODEL"] = found_model
                    
                    # Try to persist the choice to config file
                    try:
                        config_dir = os.path.join(os.path.expanduser("~"), ".codexcontinue/config")
                        os.makedirs(config_dir, exist_ok=True)
                        config_file = os.path.join(config_dir, "transcription.env")
                        
                        with open(config_file, 'w') as f:
                            f.write(f"OLLAMA_MODEL={found_model}\n")
                            f.write(f"OLLAMA_API_URL={self.ollama_api_url}\n")
                        logger.info(f"Updated config file with model {found_model}")
                    except Exception as e:
                        logger.warning(f"Failed to update config file: {str(e)}")
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
            
            # Log the request being made
            logger.info(f"Making request to Ollama API with model: {self.ollama_model}")
            
            try:
                response = requests.post(
                    f"{self.ollama_api_url}/api/generate",
                    headers=headers,
                    data=json.dumps(data),
                    timeout=60  # Increase timeout for longer transcripts
                )
            except requests.exceptions.Timeout:
                logger.error("Timeout while waiting for Ollama response")
                return {
                    "summary": "Timeout while generating summary. The transcript may be too long.",
                    "error": True
                }
            except requests.exceptions.RequestException as e:
                logger.error(f"Error sending request to Ollama: {str(e)}")
                return {
                    "summary": f"Error communicating with Ollama: {str(e)}",
                    "error": True
                }
            
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
            import traceback
            logger.error(traceback.format_exc())
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
        import time
        start_time = time.time()
        logger.info(f"Processing video from URL: {url}")
        
        # Initialize result variable
        result = None
        
        try:
            # Download the audio
            logger.info("Step 1: Downloading audio...")
            audio_file = self.download_audio(url)
            download_time = time.time() - start_time
            logger.info(f"Audio download completed in {download_time:.2f} seconds")
            
            # Transcribe the audio
            logger.info(f"Step 2: Transcribing audio with Whisper {self.whisper_model_size} model...")
            transcribe_start = time.time()
            result = self.transcribe(audio_file, language)
            transcribe_time = time.time() - transcribe_start
            logger.info(f"Transcription completed in {transcribe_time:.2f} seconds")
            
            # Add metadata
            result["source_url"] = url
            result["audio_file"] = audio_file
            result["timestamp"] = time.strftime("%Y-%m-%d %H:%M:%S")
            result["processing_time"] = {
                "download_seconds": download_time,
                "transcribe_seconds": transcribe_time,
                "total_seconds": time.time() - start_time
            }
            
            # Log transcript statistics
            text_length = len(result.get("text", ""))
            segments_count = len(result.get("segments", []))
            logger.info(f"Transcription statistics: {text_length} characters, {segments_count} segments")
            
            # Generate summary if requested
            if generate_summary and result.get("text"):
                logger.info("Step 3: Generating summary with Ollama...")
                summary_start = time.time()
                summary_result = self.summarize_transcript(result["text"])
                summary_time = time.time() - summary_start
                logger.info(f"Summary generation completed in {summary_time:.2f} seconds")
                
                result["summary"] = summary_result
                if "processing_time" in result:
                    result["processing_time"]["summary_seconds"] = summary_time
            
            # Update total processing time
            if "processing_time" in result:
                result["processing_time"]["total_seconds"] = time.time() - start_time
            
            logger.info(f"Total processing completed in {time.time() - start_time:.2f} seconds")
            return result
        except Exception as e:
            logger.error(f"Error processing video: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            
            # Provide a more detailed error structure
            error_result = {
                "error": True,
                "error_message": str(e),
                "source_url": url,
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            
            # Try to add some text if we have it (partial results)
            if 'result' in locals() and result is not None and isinstance(result, dict) and "text" in result:
                error_result["partial_text"] = result["text"]
                error_result["partial_segments"] = result.get("segments", [])
            
            return error_result
