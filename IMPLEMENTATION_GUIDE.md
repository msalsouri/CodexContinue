# Implementation Guide for CodexContinue Core Functionality

This guide provides step-by-step instructions for implementing the core functionality of the CodexContinue system, building on the containerized architecture that has been set up.

## 1. Prerequisites

Ensure you have the following prerequisites:

- Docker and Docker Compose installed
- Git for version control
- Access to the original CodexContinueGPT project
- Basic understanding of Python, FastAPI, Streamlit, and Flask

## 2. Project Initialization

First, initialize the project structure if it hasn't been done already:

```bash
# Create the basic project structure
./scripts/init-project.sh
```

This will:
- Create all necessary directories
- Set up service templates for backend, frontend, and ML
- Initialize ML model directories
- Create the Modelfile for the CodexContinue Ollama model

## 3. Backend Service Implementation

### 3.1. API Routes

Implement the following API routes in the backend service:

1. **User Management Routes**:
```python
# backend/app/api/endpoints/users.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse

router = APIRouter()

@router.post("/users/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Implementation
    pass

@router.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    # Implementation
    pass
```

2. **Chat Routes**:
```python
# backend/app/api/endpoints/chat.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.schemas.chat import ChatMessage, ChatResponse
from app.services.chat_service import ChatService

router = APIRouter()

@router.post("/chat/", response_model=ChatResponse)
async def chat(message: ChatMessage, db: Session = Depends(get_db)):
    chat_service = ChatService(db)
    return await chat_service.process_message(message)
```

3. **ML Integration Routes**:
```python
# backend/app/api/endpoints/ml.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.schemas.ml import MLRequest, MLResponse
from app.services.ml_client import MLClient

router = APIRouter()

@router.post("/ml/analyze", response_model=MLResponse)
async def analyze(request: MLRequest, db: Session = Depends(get_db)):
    ml_client = MLClient()
    return await ml_client.analyze(request)
```

### 3.2. Services Implementation

Create the following service implementations:

1. **Chat Service**:
```python
# backend/app/services/chat_service.py
from sqlalchemy.orm import Session
from app.schemas.chat import ChatMessage, ChatResponse
from app.services.ml_client import MLClient

class ChatService:
    def __init__(self, db: Session):
        self.db = db
        self.ml_client = MLClient()
    
    async def process_message(self, message: ChatMessage) -> ChatResponse:
        # Process the message using ML service
        # Store in database
        # Return response
        pass
```

2. **ML Client**:
```python
# backend/app/services/ml_client.py
import httpx
from app.schemas.ml import MLRequest, MLResponse
from app.core.config import settings

class MLClient:
    def __init__(self):
        self.base_url = settings.ML_SERVICE_URL
    
    async def analyze(self, request: MLRequest) -> MLResponse:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/analyze",
                json=request.dict()
            )
            response.raise_for_status()
            return MLResponse(**response.json())
```

## 4. ML Service Implementation

### 4.1. Flask Application

Set up the Flask application for ML service:

```python
# ml/app/main.py
from flask import Flask, request, jsonify
from flask_cors import CORS

from app.services.ml_service import MLService
from app.services.ollama_client import OllamaClient

app = Flask(__name__)
CORS(app)

ml_service = MLService()
ollama_client = OllamaClient()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"})

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    result = ml_service.analyze(data)
    return jsonify(result)

@app.route('/chat', methods=['POST'])
def chat():
    data = request.json
    result = ollama_client.generate(data)
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 4.2. ML Service Implementation

Implement the ML service:

```python
# ml/app/services/ml_service.py
from app.services.ollama_client import OllamaClient
from app.services.model_manager import ModelManager

class MLService:
    def __init__(self):
        self.ollama_client = OllamaClient()
        self.model_manager = ModelManager()
    
    def analyze(self, data):
        # Determine which model to use based on the request
        task = data.get('task', 'general')
        
        if task == 'sentiment':
            return self.model_manager.analyze_sentiment(data.get('text', ''))
        elif task == 'entities':
            return self.model_manager.extract_entities(data.get('text', ''))
        else:
            # Default to general LLM processing
            return self.ollama_client.generate({
                'prompt': data.get('text', ''),
                'model': 'codexcontinue'
            })
```

### 4.3. Ollama Client

Implement the Ollama client:

```python
# ml/app/services/ollama_client.py
import os
import requests
import json

class OllamaClient:
    def __init__(self):
        self.base_url = os.environ.get('OLLAMA_API_URL', 'http://ollama:11434')
        self.default_model = os.environ.get('DEFAULT_MODEL', 'codexcontinue')
    
    def generate(self, data):
        prompt = data.get('prompt', '')
        model = data.get('model', self.default_model)
        
        response = requests.post(
            f"{self.base_url}/api/generate",
            json={
                "model": model,
                "prompt": prompt
            }
        )
        
        if response.status_code != 200:
            return {"error": f"Ollama API error: {response.text}"}
        
        return {"response": response.json().get("response", "")}
```

## 5. Frontend Implementation

### 5.1. Main Application

Implement the main Streamlit application:

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
    
    # Display assistant response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            # Call backend API
            response = requests.post(
                f"{BACKEND_URL}/chat",
                json={"message": prompt}
            )
            
            if response.status_code == 200:
                answer = response.json().get("response", "Sorry, I couldn't process your request.")
                st.markdown(answer)
                # Add assistant response to chat
                st.session_state.messages.append({"role": "assistant", "content": answer})
            else:
                st.error(f"Error: {response.text}")
```

### 5.2. Sidebar Implementation

Add a sidebar with options:

```python
# Sidebar
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

# Additional features section
st.sidebar.subheader("Features")
enable_memory = st.sidebar.checkbox("Enable Memory", value=True)
enable_ml = st.sidebar.checkbox("Enable ML Capabilities", value=True)

# About section
st.sidebar.subheader("About")
st.sidebar.info(
    "CodexContinue is a containerized, modular, and scalable "
    "system with learning capabilities through Ollama integration."
)
```

## 6. Starting and Testing the System

### 6.1. Start the System

Use the start script to launch all services:

```bash
# Start the development environment
./scripts/start-codexcontinue.sh
```

This script will:
- Initialize the project if necessary
- Sync files from the original project
- Build and start all containers
- Build the CodexContinue model in Ollama

### 6.2. Verify Services

Check that all services are running:

```bash
# Check container status
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps
```

Verify individual service endpoints:
- Backend: http://localhost:8000/health
- Frontend: http://localhost:8501
- ML Service: http://localhost:5000/health
- Ollama: http://localhost:11434/api/tags

### 6.3. Test Ollama Model

Verify the CodexContinue model is working:

```bash
# Check if model exists
./scripts/check_ollama_model.sh
```

Test the model directly:

```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "codexcontinue",
  "prompt": "Write a simple hello world function in Python."
}'
```

## 7. Implementing Domain-Specific Customizations

To create a domain-specific version (e.g., for healthcare):

1. Create a custom Modelfile:
```bash
cp ml/models/ollama/Modelfile ml/models/ollama/Modelfile.healthcare
# Edit the file to customize system prompt for healthcare
```

2. Create a build script:
```bash
cp ml/scripts/build_codexcontinue_model.sh ml/scripts/build_healthcare_model.sh
# Edit the script to use the healthcare Modelfile
```

3. Create a domain-specific Docker Compose file:
```bash
cp docker-compose.dev.yml docker-compose.healthcare.yml
# Edit to include healthcare-specific settings
```

4. Start the domain-specific instance:
```bash
docker-compose -f docker-compose.yml -f docker-compose.healthcare.yml up -d
```

## 8. Development Workflow

For ongoing development, follow this workflow:

1. Make changes to code in respective service directories
2. No need to restart containers during development (hot-reload is configured)
3. If adding new services, use the setup script:
```bash
./scripts/setup-service.sh new-service [template]
```

4. Build Docker images when needed:
```bash
./scripts/docker-build.sh dev build:service-name
```

5. Update documentation as you add new features

## Conclusion

By following this guide, you'll have implemented the core functionality of the CodexContinue system. The containerized architecture provides a flexible and scalable platform for further development and customization.

Refer to the documentation in the `docs/` directory for more detailed information about specific components.

## 10. YouTube Transcription Feature

The YouTube transcription feature allows users to transcribe YouTube videos to text and optionally summarize the content using Ollama.

### 10.1. Components

The feature consists of three main components:

1. **Backend Service**:
   - `ml/services/youtube_transcriber.py` - Core transcription logic
   - Handles YouTube audio extraction, Whisper transcription, and Ollama summarization

2. **API Endpoint**:
   - Added to `ml/app.py`
   - Exposes `/youtube/transcribe` endpoint for the ML service

3. **Frontend UI**:
   - `frontend/pages/youtube_transcriber.py` - Streamlit interface
   - Provides user-friendly interaction for video transcription

### 10.2. Implementation Steps

1. **Install Dependencies**:
```bash
# Install ffmpeg if not already present
sudo apt-get update && sudo apt-get install -y ffmpeg

# Install Python dependencies
pip install yt-dlp openai-whisper
```

2. **Implement YouTube Transcriber Service**:
```python
# ml/services/youtube_transcriber.py
import os
import yt_dlp
import whisper

class YouTubeTranscriber:
    def __init__(self, whisper_model_size="base"):
        self.whisper_model_size = whisper_model_size
        self.model = None
        self.ffmpeg_location = self._find_ffmpeg()
        
    def _find_ffmpeg(self):
        # Logic to find ffmpeg installation
        pass
        
    def process_video(self, url, language=None, generate_summary=False):
        # Download audio, transcribe, and optionally summarize
        pass
```

3. **Add API Endpoint to ML Service**:
```python
# ml/app.py
@app.route('/youtube/transcribe', methods=["POST"])
def transcribe_youtube():
    data = request.get_json(silent=True) or {}
    url = data.get("url")
    language = data.get("language")
    whisper_model_size = data.get("whisper_model_size", "base")
    generate_summary = data.get("generate_summary", False)
    
    # Validate input and call YouTubeTranscriber
    pass
```

4. **Create Streamlit Frontend**:
```python
# frontend/pages/youtube_transcriber.py
import streamlit as st
import requests

# Configure page
st.set_page_config(
    page_title="YouTube Transcriber - CodexContinue",
    page_icon="🎬",
    layout="wide"
)

# Add form for YouTube URL input
with st.form("youtube_form"):
    # Form elements
    pass
    
# Handle form submission and display results
```

### 10.3. Running the Feature

1. **Start the ML Service**:
```bash
cd /home/msalsouri/Projects/CodexContinue && PYTHONPATH=/home/msalsouri/Projects/CodexContinue FFMPEG_LOCATION=/usr/bin python3 ml/app.py --port 5060
```

2. **Start the Streamlit Frontend**:
```bash
cd /home/msalsouri/Projects/CodexContinue && ML_SERVICE_URL=http://localhost:5060 PYTHONPATH=/home/msalsouri/Projects/CodexContinue streamlit run frontend/pages/youtube_transcriber.py
```

Alternatively, use the provided scripts:
```bash
./scripts/start-youtube-transcriber.sh
```

To stop the services:
```bash
./scripts/stop-youtube-transcriber.sh
```
