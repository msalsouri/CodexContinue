# 🚀 CodexContinue

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109.0-green)](https://fastapi.tiangolo.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.30.0-red)](https://streamlit.io/)

A powerful, modular AI development assistant with memory and multi-model support. Built for professional developers who need a versatile AI assistant with local-first capabilities and enterprise-grade features.

## 🧠 Key Features

CodexContinue offers a range of powerful capabilities:

1. **YouTube Transcription**: Convert YouTube videos to text and summaries with local processing
   - Transcribe videos in multiple languages with automatic language detection
   - Generate summaries using Ollama models
   - Completely local processing for privacy and security
   - Simple interface for quick transcription tasks
   - High-quality transcripts using OpenAI's Whisper model (running locally)

2. **Custom Ollama Models**: Specialized models for software development tasks
   - Built on Llama3, optimized for code generation
   - Technical problem-solving expertise
   - Advanced reasoning for development workflows

3. **Knowledge Integration**: Easy integration of new knowledge and capabilities
   - Vector store for efficient knowledge retrieval
   - Custom knowledge bases for domain-specific information
   - Integration with external data sources

4. **Domain Adaptation**: Ability to customize the system for specific domains
   - See [DOMAIN_CUSTOMIZATION.md](docs/DOMAIN_CUSTOMIZATION.md) for details

## 🏛️ Architecture

CodexContinue follows a modern containerized microservices architecture that ensures:

1. **Modularity**: Each component is isolated and independently deployable
2. **Scalability**: Services can be scaled based on demand
3. **Maintainability**: Well-defined interfaces between components
4. **Flexibility**: Easy to add new capabilities or replace existing ones

The system consists of these core services:

- **Backend API**: FastAPI-based REST API handling business logic
- **Frontend UI**: Streamlit-based user interface
- **ML Service**: Machine learning service with LLM integration
- **Redis**: In-memory data store for caching and messaging
- **Ollama**: Local LLM service for privacy-focused AI capabilities

## 🚀 Quick Start

### Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/CodexContinue.git
cd CodexContinue

# Start the development environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Accessing the Application

- Frontend UI: http://localhost:8501
- Backend API: http://localhost:8000/docs
- ML Service API: http://localhost:5000/docs

## 🛠️ Development

For contribution guidelines, development workflow, and best practices, see:

- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute to the project
- [DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) - Development workflow and processes
- [troubleshooting-guide.md](docs/troubleshooting-guide.md) - Troubleshooting common issues

## 📋 Planned Features

The following features are planned for future development:

1. **Batch YouTube Transcription**: Process multiple YouTube videos at once
2. **Enhanced Summarization Options**: More control over summary generation
3. **Knowledge Base Integration**: Save transcriptions to knowledge base
4. **Transcription Annotation**: Add notes and annotations to transcriptions

For more information on upcoming features and development roadmap, see [NEXT_STEPS.md](NEXT_STEPS.md).

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
