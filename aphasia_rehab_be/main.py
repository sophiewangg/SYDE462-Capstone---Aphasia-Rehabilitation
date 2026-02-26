import asyncio
import json
import logging
import os
from pathlib import Path
import uuid

from database import database, models
from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, WebSocket, WebSocketDisconnect
from services import (CueService, TranscriptionService, UserService, VectorService)
from services.vector_service import VectorService
from sqlalchemy.orm import Session
from fastapi import Query

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")
load_dotenv()

#create postgres models (defined within models.py) before app starts
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

transcription_service = TranscriptionService(api_key=os.getenv("ASSEMBLYAI_API_KEY")) # type: ignore
cue_service = CueService(api_key=os.getenv("GPT_API_KEY")) # type: ignore
vector_service = VectorService()

def get_user_service(db: Session = Depends(database.get_db)):
    return UserService(db)

# root endpoint (can use as health check)
@app.get("/")
def root():
    return {"message": "Hello World"}

# when request hits API, FastAPI opens a temporary session with the DB, performs the action and closes the session
@app.post("/users/")
def create_user(full_name: str, email: str, service: UserService = Depends(get_user_service)):
    return service.create_user_record(full_name=full_name, email=email)

@app.post("/module_attempts/")
def create_module_attempt(user_id: uuid.UUID, module_id: uuid.UUID, stats: dict, service: UserService = Depends(get_user_service)):
    return service.save_session(user_id=user_id, module_id=module_id, session_stats=stats)

@app.websocket("/ws/transcribe")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("📱 Flutter client connected")
    
    service = TranscriptionService(api_key=os.getenv("ASSEMBLYAI_API_KEY"))
    
    loop = asyncio.get_running_loop()
    
    try:
        service.connect_to_assemblyai(websocket, loop)
    except Exception as e:
        logger.info(f"❌ Failed to connect to AssemblyAI: {e}")
        await websocket.close()
        return

    try:
        while True:
            data = await websocket.receive_bytes()
            service.feed_audio(data)
            
    except WebSocketDisconnect:
        logger.info("📱 Flutter client disconnected")
    except Exception as e:
        logger.info(f"🚨 Unexpected error in loop: {e}")
    finally:
        service.close()

@app.post("/generate_cues/")
async def generate_cues(transcription: str = Body(..., embed=True), goal: str = Body(..., embed=True)):
    return cue_service.generate_cues(transcription, goal)

@app.post("/simplify_prompt/")
async def simplify_prompt(prompt: str = Body(..., embed=True)):
    return cue_service.simplify_prompt(prompt)

@app.post("/seed_exercises/")
def seed_exercises():
    base_path = Path(__file__).parent
    file_path = base_path / "data" / "exercises.json"

    try:
        with open(file_path, "r") as f:
            sample_exercises = json.load(f)
        
        for ex in sample_exercises:
            vector_service.add_exercise(
                exercise_id=ex["id"],
                text=ex["text"],
                metadata=ex["metadata"]
            )
        return {"message": f"Successfully seeded {len(sample_exercises)} exercises from JSON"}
    
    except FileNotFoundError:
        return {"error": "exercises.json not found in data folder"}, 404
    except json.JSONDecodeError:
        return {"error": "Invalid JSON format in exercises.json"}, 400


@app.post("/find_relevant_exercise/")
async def find_exercise(transcription: str = Body(..., embed=True)):
    results = vector_service.search_exercises(query_text=transcription, n_results=2)
    
    return {
        "transcription_received": transcription,
        "matching_exercises": results["documents"],
        "metadata": results["metadatas"],
        "distances": results["distances"]
    }


@app.post("/classify_utterance/")
async def classify_utterance(
    transcription: str = Body(..., embed=True),
    threshold: float = Query(0.40, description="Maximum allowed distance for a match"),
):
    """
    Use the vector store to find the closest matching utterance.
    If the closest match is within the given distance threshold,
    return its metadata (including the `intent` field).
    """
    results = vector_service.search_exercises(query_text=transcription, n_results=1)

    # Chroma returns lists-of-lists for distances / docs / metadatas.
    # If the collection is empty (or query returns no candidates), these can be empty.
    distances = results.get("distances") or []
    metadatas = results.get("metadatas") or []
    documents = results.get("documents") or []

    if not distances or not distances[0] or not metadatas or not metadatas[0] or not documents or not documents[0]:
        return {
            "match": False,
            "reason": "no_results",
        }

    distance = distances[0][0]
    metadata = metadatas[0][0]
    document = documents[0][0]

    logger.info(
        f"Classify utterance: '{transcription}' -> distance={distance}, metadata={metadata}"
    )

    if distance > threshold:
        return {
            "match": False,
            "distance": distance,
            "reason": "no_close_match",
        }

    return {
        "match": True,
        "distance": distance,
        "metadata": metadata,
        "intent": metadata.get("intent"),
        "text": document,
    }
