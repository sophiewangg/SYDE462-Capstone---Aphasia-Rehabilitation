import asyncio
import json
import logging
import os
from pathlib import Path
import uuid

from database import database, models
from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, WebSocket, WebSocketDisconnect
from services import (CueService, TranscriptionService, UserService, VectorService, DisfluencyDetectionService)
from services.vector_service import VectorService
from sqlalchemy.orm import Session
from fastapi import Query
from fastapi.staticfiles import StaticFiles
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")
load_dotenv() # Loads API key from your .env file

#create postgres models (defined within models.py) before app starts
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()
app.mount("/detections", StaticFiles(directory="detections"), name="detections")

transcription_service = TranscriptionService(api_key=os.getenv("ASSEMBLYAI_API_KEY")) # type: ignore
cue_service = CueService(api_key=os.getenv("GPT_API_KEY")) # type: ignore
vector_service = VectorService()
disfluency_detection_service = DisfluencyDetectionService()

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

    # Create a unique filename for the backend recording
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    raw_filename = f"recordings/session_{timestamp}.raw"
    wav_filename = f"recordings/session_{timestamp}.wav"    
    os.makedirs("recordings", exist_ok=True)
    # Use get_running_loop for better compatibility with FastAPI
    loop = asyncio.get_running_loop()
    
    try:
        service.connect_to_assemblyai(websocket, loop)
    except Exception as e:
        logger.info(f"❌ Failed to connect to AssemblyAI: {e}")
        await websocket.close()
        return

    # Open the file in 'append binary' mode
    with open(raw_filename, "wb") as audio_file:
        try:
            while True:
                # Receive binary audio from Flutter
                data = await websocket.receive_bytes()
                
                # ACTION A: Write to the backend file
                audio_file.write(data)
                
                # ACTION B: Send to AssemblyAI
                transcription_service.feed_audio(data)
                
        except WebSocketDisconnect:
            logger.info("📱 Flutter client disconnected")
        except Exception as e:
            logger.error(f"🚨 Unexpected error in loop: {e}")
        finally:
            transcription_service.close()
            if os.path.exists(raw_filename):
                disfluency_detection_service.detect_disfluencies(os.path.abspath(raw_filename))
                logger.info(f"🚀 Handed off {raw_filename} to Celery pipeline")

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


@app.get("/list_detections")
async def list_detections():
    detection_dir = "detections"
    if not os.path.exists(detection_dir):
        return []
    
    # Get all .wav files in the folder
    files = [f for f in os.listdir(detection_dir) if f.endswith(".wav")]
    # Sort by name (which is timestamped) so newest are at the top
    files.sort(reverse=True)
    return files