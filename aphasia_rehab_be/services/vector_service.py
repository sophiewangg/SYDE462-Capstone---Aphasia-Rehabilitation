import chromadb
from chromadb.utils import embedding_functions

class VectorService:
    def __init__(self):
        self.client = chromadb.PersistentClient(path="./chroma_db")
        
        self.emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        
        self.collection = self.client.get_or_create_collection(
            name="therapy_exercises",
            embedding_function=self.emb_fn
        )

    def add_exercise(self, exercise_id: str, text: str, metadata: dict):
        self.collection.upsert(
            ids=[exercise_id],
            documents=[text],
            metadatas=[metadata]
        )

    def search_exercises(self, query_text: str, n_results: int = 1, filter_metadata: dict = None):
    # 'where' is the parameter Chroma uses for metadata filtering
        return self.collection.query(
            query_texts=[query_text],
            n_results=n_results,
            where=filter_metadata  # Add this line
    )
