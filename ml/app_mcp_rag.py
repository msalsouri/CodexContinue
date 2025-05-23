#!/usr/bin/env python3
"""
RAG Proxy for MCP Server - Integrates vector database retrieval with LiteLLM
"""

import os
import logging
from typing import Dict, Any, Optional
import requests
from flask import Flask, jsonify, request
from flask_cors import CORS

# Import our custom services
from app.services.vector_store import VectorStore
from app.services.knowledge_manager import KnowledgeManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Initialize the vector store and knowledge manager
vector_store = VectorStore(collection_name="codexcontinue")
knowledge_manager = KnowledgeManager(vector_store=vector_store)

# Configuration
LITELLM_API_URL = os.getenv("LITELLM_API_URL", "http://litellm:8000")
RAG_PROXY_PORT = int(os.getenv("RAG_PROXY_PORT", 5001))
DEBUG = os.getenv("DEBUG", "true").lower() == "true"


def get_relevant_context(query: str, k: int = 5) -> str:
    """Get relevant context from the vector store."""
    try:
        return vector_store.get_relevant_context(query, k=k)
    except Exception as e:
        logger.error(f"Error retrieving context: {e}")
        return ""


def forward_request_to_litellm(endpoint: str, original_data: Dict[str, Any], 
                              context: Optional[str] = None) -> Dict[str, Any]:
    """
    Forward a request to LiteLLM with optional context augmentation.
    """
    # Make a copy of the original data to modify
    augmented_data = original_data.copy()
    
    # If there's no context or we're not supposed to augment, just forward as is
    if not context:
        return requests.post(f"{LITELLM_API_URL}/{endpoint}", json=augmented_data).json()
        
    # Handle completion requests (different from chat)
    if endpoint == "v1/completions":
        if context:
            # Add context to the prompt
            prompt = augmented_data.get("prompt", "")
            system_context = (
                f"Use the following context to help answer the question:\n"
                f"{context}\n\n"
                f"Question: {prompt}"
            )
            augmented_data["prompt"] = system_context
    
    # Handle chat completion requests
    elif endpoint == "v1/chat/completions":
        messages = augmented_data.get("messages", [])
        
        # Only add context if there are messages
        if messages:
            # Add a system message with context at the beginning
            system_msg = {
                "role": "system", 
                "content": f"Use the following context to help answer the user's questions:\n{context}"
            }
            
            # Add the system message with context if there isn't already a system message
            if not any(msg.get("role") == "system" for msg in messages):
                messages.insert(0, system_msg)
            else:
                # Update the existing system message
                for i, msg in enumerate(messages):
                    if msg.get("role") == "system":
                        existing_content = msg.get("content", "")
                        # Append the context to the existing system message
                        msg["content"] = f"{existing_content}\n\nAdditional context: {context}"
                        messages[i] = msg
                        break
            
            augmented_data["messages"] = messages
    
    # Send the augmented request to LiteLLM
    try:
        response = requests.post(f"{LITELLM_API_URL}/{endpoint}", json=augmented_data)
        return response.json()
    except Exception as e:
        logger.error(f"Error forwarding request to LiteLLM: {e}")
        return {"error": str(e)}


@app.route('/')
def home():
    """Home page for the RAG proxy."""
    return jsonify({
        "message": "CodexContinue RAG Proxy for MCP",
        "endpoints": [
            "/v1/completions",
            "/v1/chat/completions",
            "/v1/models",
            "/rag/import",
            "/rag/query",
            "/health"
        ]
    })


@app.route('/health')
def health():
    """Health check endpoint."""
    try:
        # Check vector store health
        vector_store.similarity_search("health check", k=1)
        
        # Check LiteLLM health
        litellm_status = "unavailable"
        try:
            response = requests.get(f"{LITELLM_API_URL}/v1/models")
            if response.status_code == 200:
                litellm_status = "available"
        except:
            pass
        
        return jsonify({
            "status": "healthy",
            "vector_store": "available",
            "litellm": litellm_status,
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


@app.route('/v1/completions', methods=['POST'])
def completions():
    """Proxy for the completions endpoint with RAG augmentation."""
    try:
        data = request.get_json(silent=True) or {}
        
        # Extract the prompt for context retrieval
        prompt = data.get('prompt', '')
        if not prompt:
            return jsonify({"error": "Prompt is required"}), 400
        
        # Check if RAG should be used
        use_rag = data.pop('use_rag', True)
        
        # Get context if RAG is enabled
        context = None
        if use_rag:
            context = get_relevant_context(prompt)
        
        # Forward to LiteLLM
        result = forward_request_to_litellm("v1/completions", data, context)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in completions endpoint: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/v1/chat/completions', methods=['POST'])
def chat_completions():
    """Proxy for the chat completions endpoint with RAG augmentation."""
    try:
        data = request.get_json(silent=True) or {}
        
        # Extract messages for context retrieval
        messages = data.get('messages', [])
        if not messages:
            return jsonify({"error": "Messages are required"}), 400
        
        # Check if RAG should be used
        use_rag = data.pop('use_rag', True)
        
        # Get context based on the last user message
        context = None
        if use_rag:
            # Extract the user's latest message for context retrieval
            user_messages = [msg["content"] for msg in messages if msg.get("role") == "user"]
            if user_messages:
                latest_user_message = user_messages[-1]
                context = get_relevant_context(latest_user_message)
        
        # Forward to LiteLLM
        result = forward_request_to_litellm("v1/chat/completions", data, context)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in chat completions endpoint: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/v1/models', methods=['GET'])
def list_models():
    """Proxy for the models endpoint."""
    try:
        response = requests.get(f"{LITELLM_API_URL}/v1/models")
        return jsonify(response.json())
    except Exception as e:
        logger.error(f"Error getting models: {e}")
        return jsonify({"error": f"Failed to get models: {str(e)}"}), 500


@app.route('/rag/import', methods=['POST'])
def import_knowledge():
    """Import documents into the RAG knowledge base."""
    try:
        data = request.get_json(silent=True) or {}
        
        # Check if directory path is provided
        directory_path = data.get('directory_path')
        if not directory_path:
            return jsonify({"error": "Directory path is required"}), 400
            
        # Optional file types filter
        file_types = data.get('file_types')
        # Ensure file_types is a list if provided
        if file_types is not None and not isinstance(file_types, list):
            file_types = [file_types]
        
        # Import documents
        result = knowledge_manager.import_directory(directory_path, file_types)
        
        return jsonify({
            "success": True,
            "message": f"Successfully imported documents from {directory_path}",
            "stats": result
        })
        
    except Exception as e:
        logger.error(f"Error importing knowledge: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/rag/query', methods=['POST'])
def query_knowledge():
    """Query the RAG knowledge base directly."""
    try:
        data = request.get_json(silent=True) or {}
        
        # Check if query is provided
        query = data.get('query')
        if not query:
            return jsonify({"error": "Query is required"}), 400
            
        # Optional parameters
        k = int(data.get('k', 5))
        
        # Get context for the query
        context = get_relevant_context(query, k=k)
        
        return jsonify({
            "success": True,
            "context": context
        })
        
    except Exception as e:
        logger.error(f"Error querying knowledge: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    # Create necessary directories
    vector_db_path = os.getenv("VECTOR_DB_PATH", os.path.join(os.path.expanduser("~"), ".codexcontinue/data/vectorstore"))
    knowledge_base_path = os.getenv("KNOWLEDGE_BASE_PATH", os.path.join(os.path.expanduser("~"), ".codexcontinue/data/knowledge_base"))
    
    os.makedirs(vector_db_path, exist_ok=True)
    os.makedirs(knowledge_base_path, exist_ok=True)
    
    # Log startup information
    logger.info("Starting RAG proxy for MCP...")
    logger.info(f"LiteLLM API URL: {LITELLM_API_URL}")
    logger.info(f"Vector store directory: {vector_db_path}")
    logger.info(f"Knowledge base directory: {knowledge_base_path}")
    
    # Start the server
    app.run(host='0.0.0.0', port=RAG_PROXY_PORT, debug=DEBUG)