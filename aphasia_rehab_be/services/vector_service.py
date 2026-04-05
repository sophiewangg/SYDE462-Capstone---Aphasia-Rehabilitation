import chromadb
import re
import logging
from chromadb.utils import embedding_functions

logger = logging.getLogger("uvicorn")

class VectorService:
    def __init__(self):
        self.client = chromadb.PersistentClient(path="./chroma_db")
        
        self.emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        
        self.collection = self.client.get_or_create_collection(
            name="therapy_exercises",
            embedding_function=self.emb_fn,
            #metadata={"hnsw:space": "cosine"} #to use cosine distance instead of euclidean distance
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
            where=filter_metadata
    )

    def classify_intent(self, text: str, current_step: str = None, global_search: bool = False, threshold: float = 0.40):
        """
        Handles chunking, filtering logic, and searching for the best intent match.
        """
        if len(text.strip().split()) <= 3 and current_step:
            logger.info(f"🔒 Short utterance detected ('{text.strip()}'). Forcing local search.")
            global_search = False

        step_filter = {"step": current_step} if (current_step and not global_search) else None
        
        raw_chunks = re.split(r'\b(?:and|with|also|then|but)\b|,|\.|;', text.lower())
        chunks = [c.strip() for c in raw_chunks if len(c.strip()) > 2]
        if not chunks:
            chunks = [text.lower().strip()]

        detected_intents = set()
        best_match = {"distance": None, "metadata": None}

        for chunk in chunks:
            results = self.search_exercises(
                query_text=chunk, 
                n_results=1,
                filter_metadata=step_filter
            )
            
            distances = results.get("distances", [[]])[0]
            metadatas = results.get("metadatas", [[]])[0]

            if distances and metadatas:
                distance = distances[0]
                metadata = metadatas[0]

                if distance <= threshold:
                    intent = metadata.get("intent")
                    if intent:
                        detected_intents.add(intent)
                        # Track the absolute best match for the response
                        if best_match["distance"] is None or distance < best_match["distance"]:
                            best_match["distance"] = distance
                            best_match["metadata"] = metadata

        return {
            "match": len(detected_intents) > 0,
            "intents": list(detected_intents), 
            "distance": best_match["distance"],
            "metadata": best_match["metadata"],
            "text": text
        }