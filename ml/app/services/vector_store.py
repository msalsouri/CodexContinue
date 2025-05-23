import os
import logging
from typing import List, Dict, Any, Optional

from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class VectorStore:
    def __init__(self, collection_name: str = "codexcontinue"):
        """Initialize the vector store with a specific embedding model."""
        # Use a lightweight, efficient model for embeddings
        self.embedding_model = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        
        # Connect to ChromaDB (either local or via the service)
        persist_directory = os.getenv("VECTOR_DB_PATH", os.path.join(os.path.expanduser("~"), ".codexcontinue/data/vectorstore"))
        chroma_url = os.getenv("CHROMA_URL", None)
        
        if chroma_url:
            # Use the external Chroma service
            from chromadb.config import Settings
            import chromadb
            
            client = chromadb.HttpClient(
                host=chroma_url.split(":")[0], 
                port=int(chroma_url.split(":")[1]),
                settings=Settings(allow_reset=True)
            )
            
            self.vectorstore = Chroma(
                client=client,
                collection_name=collection_name,
                embedding_function=self.embedding_model
            )
        else:
            # Use local persistence
            os.makedirs(persist_directory, exist_ok=True)
            
            self.vectorstore = Chroma(
                collection_name=collection_name,
                embedding_function=self.embedding_model,
                persist_directory=persist_directory
            )
        
        logger.info(f"Vector store initialized with collection: {collection_name}")
    
    def add_texts(self, texts: List[str], metadatas: Optional[List[Dict[str, Any]]] = None) -> List[str]:
        """Add texts to the vector store."""
        return self.vectorstore.add_texts(texts=texts, metadatas=metadatas)
    
    def add_documents(self, documents: List[Document]) -> List[str]:
        """Add documents to the vector store."""
        return self.vectorstore.add_documents(documents=documents)
    
    def similarity_search(self, query: str, k: int = 5) -> List[Document]:
        """Search for similar documents to the query."""
        return self.vectorstore.similarity_search(query=query, k=k)
    
    def process_document(self, content: str, metadata: Dict[str, Any], chunk_size: int = 1000) -> List[str]:
        """Process a document by splitting it into chunks and storing in the vector DB."""
        # Split the document into chunks
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=200
        )
        
        chunks = text_splitter.split_text(content)
        
        # Create metadata for each chunk (same metadata for all chunks from the same doc)
        metadatas = [metadata] * len(chunks)
        
        # Add to vector store
        ids = self.add_texts(chunks, metadatas)
        logger.info(f"Added {len(chunks)} chunks to vector store")
        
        return ids
    
    def get_relevant_context(self, query: str, k: int = 5) -> str:
        """Get relevant context for a query from the vector store."""
        documents = self.similarity_search(query, k=k)
        
        # Combine the relevant documents into a context string
        context = "\n\n".join([doc.page_content for doc in documents])
        
        # Include source information
        sources = []
        for doc in documents:
            if doc.metadata.get("source"):
                sources.append(doc.metadata["source"])
        
        if sources:
            context += "\n\nSources: " + ", ".join(set(sources))
        
        return context
