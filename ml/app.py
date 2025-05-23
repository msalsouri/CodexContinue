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
    generate_summary = data.get("generate_summary", False)
    
    if not url:
        return jsonify({"error": "No URL provided"}), 400
    
    try:
        # Import here to avoid importing on startup if whisper is not installed
        from ml.services.youtube_transcriber import YouTubeTranscriber
        
        transcriber = YouTubeTranscriber(whisper_model_size="base")
        result = transcriber.process_video(url, language, generate_summary=generate_summary)
        
        response_data = {
            "text": result["text"],
            "segments": result["segments"],
            "source_url": result["source_url"]
        }
        
        # Include summary if it was generated
        if generate_summary and "summary" in result:
            response_data["summary"] = result["summary"]
        
        return jsonify(response_data)
    except Exception as e:
        logger.error(f"Error transcribing YouTube video: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Log some debug information
    logger.info("Starting ML service...")
    logger.info(f"PYTHONPATH: {os.getenv('PYTHONPATH', 'Not set')}")
    logger.info(f"DEBUG: {os.getenv('DEBUG', 'Not set')}")
    logger.info(f"OLLAMA_API_URL: {os.getenv('OLLAMA_API_URL', 'Not set')}")
    
    # Create necessary directories
    vector_db_path = os.getenv("VECTOR_DB_PATH", "/app/data/vectorstore")
    knowledge_base_path = os.getenv("KNOWLEDGE_BASE_PATH", "/app/data/knowledge_base")
    
    os.makedirs(vector_db_path, exist_ok=True)
    os.makedirs(knowledge_base_path, exist_ok=True)
    
    logger.info(f"VectorDB directory: {vector_db_path}")
    logger.info(f"Knowledge base directory: {knowledge_base_path}")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
