import os
import logging
from flask import Flask, jsonify, request
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({"message": "Welcome to CodexContinue ML Service"})

@app.route('/health')
def health():
    # Check if environment variables are set
    env_vars = {
        "PYTHONPATH": os.getenv("PYTHONPATH", "Not set"),
        "DEBUG": os.getenv("DEBUG", "Not set"),
        "OLLAMA_API_URL": os.getenv("OLLAMA_API_URL", "Not set"),
        "VECTOR_DB_PATH": os.getenv("VECTOR_DB_PATH", "Not set"),
        "KNOWLEDGE_BASE_PATH": os.getenv("KNOWLEDGE_BASE_PATH", "Not set")
    }
    
    return jsonify({
        "status": "healthy",
        "environment": env_vars
    })

@app.route('/youtube/transcribe', methods=["POST"])
def transcribe_youtube():
    """Transcribe a YouTube video."""
    data = request.get_json(silent=True) or {}
    url = data.get("url")
    language = data.get("language")
    whisper_model_size = data.get("whisper_model_size", "base")
    generate_summary = data.get("generate_summary", False)
    
    if not url:
        return jsonify({"error": "No URL provided"}), 400
    
    # Validate URL format (simple check)
    if not url.startswith("http"):
        return jsonify({"error": "Invalid URL format. URL must start with http:// or https://"}), 400
    
    if "youtube.com" not in url and "youtu.be" not in url:
        return jsonify({"error": "URL doesn't appear to be a YouTube link"}), 400
    
    try:
        # Import YouTubeTranscriber - it will handle ffmpeg path detection and setup
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        # Instead of managing ffmpeg here, create the transcriber first
        # which will handle path detection internally
        transcriber = YouTubeTranscriber(whisper_model_size=whisper_model_size)
        ffmpeg_location = transcriber.ffmpeg_location
        
        # Log the ffmpeg location used
        logger.info(f"Using ffmpeg from transcriber's detected location: {ffmpeg_location}")
        
        # Print debugging information
        logger.info(f"Processing YouTube URL: {url}")
        logger.info(f"Whisper model size: {whisper_model_size}")
        logger.info(f"Environment PATH: {os.environ.get('PATH')}")
        logger.info(f"Transcriber initialized with ffmpeg_location: {transcriber.ffmpeg_location}")
        
        result = transcriber.process_video(url, language, generate_summary=generate_summary)
        
        if not result.get("text"):
            return jsonify({"error": "Transcription failed: No text was generated"}), 500
        
        response_data = {
            "text": result["text"],
            "segments": result["segments"],
            "source_url": result["source_url"]
        }
        
        # Include summary if it was generated
        if generate_summary and "summary" in result:
            response_data["summary"] = result["summary"]
        
        # Include metadata about the process
        response_data["metadata"] = {
            "whisper_model": whisper_model_size,
            "ffmpeg_location": ffmpeg_location,
            "language": language,
            "timestamp": result.get("timestamp", "")
        }
        
        return jsonify(response_data)
    except FileNotFoundError as e:
        logger.error(f"File not found error: {str(e)}")
        return jsonify({"error": f"File not found: {str(e)}"}), 500
    except RuntimeError as e:
        logger.error(f"Runtime error: {str(e)}")
        return jsonify({"error": f"Error processing video: {str(e)}"}), 500
    except Exception as e:
        logger.error(f"Error transcribing YouTube video: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Log some debug information
    logger.info("Starting ML service...")
    logger.info(f"PYTHONPATH: {os.getenv('PYTHONPATH', 'Not set')}")
    logger.info(f"DEBUG: {os.getenv('DEBUG', 'Not set')}")
    logger.info(f"OLLAMA_API_URL: {os.getenv('OLLAMA_API_URL', 'Not set')}")
    
    # Parse command line arguments for port
    import argparse
    parser = argparse.ArgumentParser(description="Start the ML service")
    parser.add_argument("--port", type=int, default=5000, help="Port to run the server on")
    args = parser.parse_args()
    
    # Create necessary directories - use local paths for development environment
    if os.getenv("ENVIRONMENT") == "production":
        base_dir = "/app"
    else:
        # For development, use local paths
        base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    vector_db_path = os.getenv("VECTOR_DB_PATH", os.path.join(base_dir, "data/vectorstore"))
    knowledge_base_path = os.getenv("KNOWLEDGE_BASE_PATH", os.path.join(base_dir, "data/knowledge_base"))
    temp_dir = os.path.join(os.path.expanduser("~"), ".codexcontinue/temp")
    
    os.makedirs(vector_db_path, exist_ok=True)
    os.makedirs(knowledge_base_path, exist_ok=True)
    os.makedirs(temp_dir, exist_ok=True)
    
    logger.info(f"VectorDB directory: {vector_db_path}")
    logger.info(f"Knowledge base directory: {knowledge_base_path}")
    logger.info(f"Temp directory: {temp_dir}")
    logger.info(f"Starting server on port: {args.port}")
    
    app.run(host='0.0.0.0', port=args.port, debug=True)
