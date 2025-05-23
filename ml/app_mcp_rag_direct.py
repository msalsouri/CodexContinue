#!/usr/bin/env python3
"""
Simplified RAG Proxy for MCP Server - Direct implementation without gunicorn
"""

import os
import logging
from flask import Flask, jsonify, request
from flask_cors import CORS

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health_check():
    """Simple health check endpoint"""
    return jsonify({"status": "healthy", "service": "mcp-rag-proxy"})

@app.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    """
    Handle chat completions requests with RAG integration
    This is a simplified version that just forwards to LiteLLM
    """
    try:
        # Get the litellm API URL from environment variable
        litellm_url = os.environ.get("LITELLM_API_URL", "http://litellm:8000")
        
        # Log the request
        logger.info(f"Received chat completion request, forwarding to {litellm_url}")
        
        # For now, we're just returning a mock response
        return jsonify({
            "id": "mcp-rag-mock-response",
            "object": "chat.completion",
            "model": "ollama/codexcontinue",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "This is a mock response from the RAG proxy. In a real implementation, this would contain retrieval-augmented responses."
                },
                "finish_reason": "stop"
            }]
        })
    except Exception as e:
        logger.error(f"Error processing chat completion request: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # Get port from environment, default to 5001
    port = int(os.environ.get("RAG_PROXY_PORT", 5001))
    
    logger.info(f"Starting MCP RAG Proxy server on port {port}")
    app.run(host="0.0.0.0", port=port, debug=True)
