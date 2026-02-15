import chromadb
import os
from chromadb.utils import embedding_functions
import json

# Initialize Chroma and OpenAI
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key=os.getenv("GPT_API_KEY"),
    model_name="text-embedding-3-small"
)
client = chromadb.PersistentClient(path="./chroma_db")

def upload_dialogue_to_chroma(json_file_path):
    with open(json_file_path, 'r') as f:
        dialogue_data = json.load(f)

    for node_id, content in dialogue_data["nodes"].items():
        # We create a unique collection for every branching point
        # Example: 'coll_waiter_greeting', 'coll_ask_party_size'
        coll_name = f"coll_{node_id}"
        
        # Delete if exists to avoid the 'embedding function conflict' from earlier
        try:
            client.delete_collection(coll_name)
        except:
            pass

        collection = client.create_collection(
            name=coll_name, 
            embedding_function=openai_ef
        )

        # Prepare the data for this specific node
        documents = []
        metadatas = []
        ids = []

        for i, option in enumerate(content["options"]):
            for j, phrase in enumerate(option["user_phrases"]):
                documents.append(phrase)
                # Store the 'target' node in metadata so we know where to go next
                metadatas.append({"target": option["target"], "intent": option["intent"]})
                ids.append(f"{node_id}_{i}_{j}")

        # Upload to Chroma
        if documents:
            collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            print(f"✅ Uploaded {len(documents)} phrases for node: {node_id}")

# Run the uploader
upload_dialogue_to_chroma("dialogue.json")