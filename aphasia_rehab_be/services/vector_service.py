import chromadb
import os

from chromadb.utils import embedding_functions

class VectorService:
    def __init__(self, api_key: str | None = None):
        self.client = chromadb.PersistentClient(path="./chroma_db")
        # Use OpenAI embeddings (no torch/sentence-transformers required)
        self.emb_fn = embedding_functions.OpenAIEmbeddingFunction(
            api_key=api_key or os.getenv("GPT_API_KEY"),
            model_name="text-embedding-3-small",
        )
        try:
            self.collection = self.client.get_or_create_collection(
                name="therapy_exercises",
                embedding_function=self.emb_fn,
            )
        except ValueError as e:
            if "embedding function" in str(e).lower() and "conflict" in str(e).lower():
                # Collection was created with a different embedder; recreate it
                self.client.delete_collection("therapy_exercises")
                self.collection = self.client.create_collection(
                    name="therapy_exercises",
                    embedding_function=self.emb_fn,
                )
            else:
                raise

    def add_exercise(self, exercise_id: str, text: str, metadata: dict):
        self.collection.add(
            ids=[exercise_id],
            documents=[text],
            metadatas=[metadata]
        )

    def search_exercises(self, query_text: str, n_results: int = 3):
        return self.collection.query(
            query_texts=[query_text],
            n_results=n_results,
            include=["documents", "metadatas", "distances"],
        )

    def find_best_path(self, transcript: str, options: list[dict]) -> tuple[str | None, float]:
        """
        Given user transcript and dialogue options [{"user_phrases": [...], "target": "..."}],
        return (target_node_id, distance) for the best matching option. Lower distance = better match.
        """
        # 1. Handle empty options edge case
        if not options:
            return None, float("inf")

        # 2. Flatten options into a list of (phrase, target) tuples
        phrases_with_targets: list[tuple[str, str]] = []
        for opt in options:
            for phrase in opt.get("user_phrases", []):
                phrases_with_targets.append((phrase, opt["target"]))
        
        if not phrases_with_targets:
            return None, float("inf")

        # 3. Embed everything in one batch (query + all options)
        texts_to_embed = [transcript] + [p for p, _ in phrases_with_targets]
        all_embs = self.emb_fn(texts_to_embed)
        
        query_emb = all_embs[0]
        phrase_embs = all_embs[1:]

        # 4. Find the closest match
        best_idx = 0
        best_dist = float("inf")

        for i, emb in enumerate(phrase_embs):
            # Calculate distance (assuming _cosine_distance returns a float or numpy float)
            d = self._cosine_distance(query_emb, emb)
            
            if d < best_dist:
                best_dist = d
                best_idx = i

        # 5. Return result (Explicitly cast to float to fix the JSON error)
        # ------------------------------------------------------------------
        # FIX IS HERE: We wrap best_dist in float()
        # ------------------------------------------------------------------
        return phrases_with_targets[best_idx][1], float(best_dist)

    @staticmethod
    def _cosine_distance(a: list[float], b: list[float]) -> float:
        dot = sum(x * y for x, y in zip(a, b))
        norm_a = sum(x * x for x in a) ** 0.5
        norm_b = sum(x * x for x in b) ** 0.5
        if norm_a == 0 or norm_b == 0:
            return float("inf")
        return 1.0 - dot / (norm_a * norm_b)
