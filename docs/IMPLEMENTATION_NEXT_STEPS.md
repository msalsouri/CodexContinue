# Completing the CodexContinue Implementation

This guide provides detailed instructions on how to complete the implementation of the CodexContinue project, building on the containerized architecture that has already been set up.

## 1. Initialize the Project Structure

First, run the initialization script to create the basic service structure:

```bash
# Navigate to the project directory
cd /Users/msalsouri/Projects/CodexContinue

# Run the initialization script
./scripts/init-project.sh
```

This will:
- Create necessary directories for all services
- Initialize Docker configuration files
- Set up the ML model directories
- Create the Modelfile for Ollama integration

## 2. Sync from Original Project

Migrate essential code from the original CodexContinueGPT project:

```bash
# Run the sync script
./scripts/sync-from-original.sh
```

This script will:
- Copy relevant Python modules from the original project
- Adapt configurations to the new structure
- Ensure compatibility with the containerized approach

## 3. Implementing the Backend Service

### 3.1 Core API Routes

Create the following API endpoints in the backend service:

1. **User Management**:
   - `/users/create`: Create a new user
   - `/users/{id}`: Get user information
   - `/users/authenticate`: User authentication

2. **Chat System**:
   - `/chat/message`: Process chat messages
   - `/chat/history`: Get chat history

3. **ML Integration**:
   - `/ml/analyze`: Process text with ML models
   - `/ml/models`: List available models

### 3.2 Database Models

Implement the following database models:

1. **User Model**:
```python
# backend/app/models/user.py
from sqlalchemy import Column, Integer, String
from app.db.base import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
```

2. **Conversation Model**:
```python
# backend/app/models/conversation.py
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.base import Base

class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation")
```

3. **Message Model**:
```python
# backend/app/models/message.py
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.base import Base

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    content = Column(Text)
    role = Column(String)  # 'user' or 'assistant'
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    conversation = relationship("Conversation", back_populates="messages")
```

## 4. Implementing the ML Service

### 4.1 Ollama Client

Create the Ollama client to interact with the local LLM:

```python
# ml/app/services/ollama_client.py
import os
import requests
import json
import logging

logger = logging.getLogger(__name__)

class OllamaClient:
    def __init__(self):
        self.base_url = os.environ.get('OLLAMA_API_URL', 'http://ollama:11434')
        self.model_name = os.environ.get('DEFAULT_MODEL', 'codexcontinue')
        
    def _check_model_exists(self):
        """Check if the model exists in Ollama."""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                models = response.json().get("models", [])
                return any(m.get('name') == self.model_name for m in models)
            return False
        except Exception as e:
            logger.error(f"Error checking model: {e}")
            return False
            
    def generate(self, prompt, params=None):
        """Generate a response from the Ollama model."""
        if not self._check_model_exists():
            return {"error": f"Model {self.model_name} not found in Ollama"}
            
        default_params = {
            "temperature": 0.7,
            "top_p": 0.9,
            "top_k": 40,
        }
        
        if params:
            default_params.update(params)
            
        data = {
            "model": self.model_name,
            "prompt": prompt,
            **default_params
        }
        
        try:
            response = requests.post(f"{self.base_url}/api/generate", json=data)
            if response.status_code == 200:
                return {"response": response.json().get("response", "")}
            else:
                return {"error": f"API error: {response.status_code} - {response.text}"}
        except Exception as e:
            logger.error(f"Error calling Ollama API: {e}")
            return {"error": f"Failed to call Ollama API: {str(e)}"}
```

### 4.2 ML Service API

Implement the ML service API:

```python
# ml/app/api/routes.py
from flask import Blueprint, request, jsonify
from app.services.ollama_client import OllamaClient
import logging

api = Blueprint('api', __name__, url_prefix='/api')
ollama_client = OllamaClient()
logger = logging.getLogger(__name__)

@api.route('/generate', methods=['POST'])
def generate():
    data = request.json
    if not data or 'prompt' not in data:
        return jsonify({"error": "Missing prompt parameter"}), 400
        
    prompt = data.get('prompt')
    params = data.get('params', {})
    
    result = ollama_client.generate(prompt, params)
    
    if 'error' in result:
        return jsonify(result), 500
    
    return jsonify(result)

@api.route('/models', methods=['GET'])
def get_models():
    try:
        response = requests.get(f"{ollama_client.base_url}/api/tags")
        if response.status_code == 200:
            return jsonify(response.json())
        return jsonify({"error": f"Failed to get models: {response.text}"}), 500
    except Exception as e:
        logger.error(f"Error getting models: {e}")
        return jsonify({"error": f"Failed to get models: {str(e)}"}), 500
```

## 5. Implementing the Frontend

### 5.1 Main Application

Create the main Streamlit application:

```python
# frontend/app.py
import streamlit as st
import requests
import json
import os

# Configuration
BACKEND_URL = os.environ.get('BACKEND_URL', 'http://localhost:8000')

# Page setup
st.set_page_config(
    page_title="CodexContinue",
    page_icon="🧠",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Title and description
st.title("🧠 CodexContinue")
st.subheader("AI-powered development assistant with learning capabilities")

# Initialize session state
if 'messages' not in st.session_state:
    st.session_state.messages = []
if 'conversations' not in st.session_state:
    st.session_state.conversations = []

# Display chat messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Chat input
prompt = st.chat_input("Ask me anything about code...")

if prompt:
    # Add user message to chat
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Call backend API
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            try:
                response = requests.post(
                    f"{BACKEND_URL}/api/chat/message",
                    json={"prompt": prompt}
                )
                
                if response.status_code == 200:
                    answer = response.json().get("response", "")
                    st.markdown(answer)
                    st.session_state.messages.append({"role": "assistant", "content": answer})
                else:
                    st.error(f"Error: {response.text}")
            except Exception as e:
                st.error(f"Failed to connect to backend: {str(e)}")
```

### 5.2 Create a Sidebar

Add a sidebar with options:

```python
# Sidebar implementation to add after the page setup
st.sidebar.title("CodexContinue")

# Model selection
model = st.sidebar.selectbox(
    "Select Model",
    ["codexcontinue", "llama3", "codellama"]
)

# Temperature slider
temperature = st.sidebar.slider(
    "Temperature", 
    min_value=0.0, 
    max_value=1.0, 
    value=0.7, 
    step=0.1, 
    help="Higher values make output more random, lower values more deterministic"
)

# Context length slider
context_length = st.sidebar.slider(
    "Context Length",
    min_value=1024,
    max_value=8192,
    value=4096,
    step=1024,
    help="Maximum number of tokens to use for context"
)

# Conversations section
st.sidebar.subheader("Conversations")
if st.sidebar.button("New Conversation"):
    st.session_state.messages = []
    st.experimental_rerun()

# About section
st.sidebar.subheader("About")
st.sidebar.info(
    "CodexContinue is a containerized, modular AI assistant "
    "with learning capabilities through Ollama integration."
)
```

## 6. Starting and Testing the System

Use the start script to launch all services:

```bash
# Start the development environment
./scripts/start-codexcontinue.sh
```

This script will:
- Initialize the project if necessary
- Ensure the Ollama model is properly created
- Build and start all containers

## 7. Customizing for Different Domains

To create domain-specific versions:

1. Create a custom Modelfile:
```
# For healthcare domain
cp ml/models/ollama/Modelfile ml/models/ollama/Modelfile.healthcare
```

2. Edit the Modelfile to customize for healthcare:
```
FROM llama3
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 8192

# Model metadata
SYSTEM """
You are HealthcareContinue, an AI assistant specialized in healthcare,
medical research, and clinical workflows.

Focus areas:
- Medical terminology and concepts
- Clinical guidelines and best practices
- Healthcare regulations and compliance
- Medical research and literature
- Patient care workflows

Key capabilities:
1. Provide evidence-based medical information
2. Explain complex medical concepts clearly
3. Assist with clinical documentation
4. Support healthcare research tasks
5. Help with healthcare workflow optimization

Always prioritize patient safety and medical accuracy in your responses.
"""
```

3. Create a build script for the domain-specific model:
```bash
#!/bin/bash
# ml/scripts/build_healthcare_model.sh

set -e

# Configuration
OLLAMA_API_URL=${OLLAMA_API_URL:-http://ollama:11434}
MODEL_NAME="healthcarecontinue"
MODELFILE_PATH="/app/ml/models/ollama/Modelfile.healthcare"

echo "Building the HealthcareContinue model..."
echo "Ollama API URL: ${OLLAMA_API_URL}"

# Check if Ollama is accessible
curl -s ${OLLAMA_API_URL}/api/tags > /dev/null || {
    echo "Error: Could not connect to Ollama"
    exit 1
}

# Build the model
curl -X POST -H "Content-Type: application/json" ${OLLAMA_API_URL}/api/create -d "{
  \"name\": \"${MODEL_NAME}\",
  \"modelfile\": \"$(cat ${MODELFILE_PATH})\"
}"

echo "Model ${MODEL_NAME} has been created successfully!"
```

## 8. Next Steps

After completing the core implementation:

1. **Add Authentication**: Implement JWT-based authentication for API endpoints
2. **Create User Management UI**: Add user registration and login pages
3. **Implement Advanced ML Features**: Add more ML capabilities like code analysis
4. **Add Visualization Tools**: Create dashboards for system monitoring
5. **Implement Testing**: Add unit and integration tests
6. **Documentation**: Create API documentation with Swagger/ReDoc

By following these steps, you will have a fully functional CodexContinue system with learning capabilities through Ollama integration, ready for further enhancement and customization.
