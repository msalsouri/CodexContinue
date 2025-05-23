import os
import glob
from typing import List, Dict, Any
import logging
from pathlib import Path

from .vector_store import VectorStore

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KnowledgeManager:
    def __init__(self, vector_store: VectorStore):
        """Initialize the knowledge manager with a vector store."""
        self.vector_store = vector_store
        self.knowledge_dir = os.getenv("KNOWLEDGE_BASE_PATH", "/app/data/knowledge_base")
        os.makedirs(self.knowledge_dir, exist_ok=True)
    
    def import_directory(self, directory_path: str, file_types: List[str] = None) -> Dict[str, Any]:
        """Import all supported files from a directory into the knowledge base."""
        if file_types is None:
            file_types = ["md", "txt", "py", "js", "html", "css", "json", "yaml", "yml"]
        
        imported_count = 0
        failed_imports = []
        
        # Get list of files with the specified extensions
        patterns = [f"**/*.{ext}" for ext in file_types]
        
        for pattern in patterns:
            for file_path in glob.glob(os.path.join(directory_path, pattern), recursive=True):
                try:
                    self.import_file(file_path)
                    imported_count += 1
                except Exception as e:
                    logger.error(f"Error importing {file_path}: {str(e)}")
                    failed_imports.append({"path": file_path, "error": str(e)})
        
        return {
            "imported_count": imported_count,
            "failed_imports": failed_imports
        }
    
    def import_file(self, file_path: str) -> str:
        """Import a single file into the knowledge base."""
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
        
        # Read the file content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Create metadata for the document
        metadata = {
            "source": file_path,
            "file_type": Path(file_path).suffix[1:],  # Remove the dot from extension
            "filename": os.path.basename(file_path)
        }
        
        # Process the document and add to vector store
        chunk_ids = self.vector_store.process_document(content, metadata)
        
        logger.info(f"Imported {file_path} into knowledge base with {len(chunk_ids)} chunks")
        return chunk_ids[0] if chunk_ids else None
