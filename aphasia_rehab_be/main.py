import asyncio
import logging
import os
import uuid

from database import database, models
from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, WebSocket, WebSocketDisconnect
from services import (CueService, TranscriptionService, UserService, VectorService)
from services.vector_service import VectorService
from sqlalchemy.orm import Session

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
    
    loop = asyncio.get_running_loop()
    
    try:
        transcription_service.connect_to_assemblyai(websocket, loop)
    except Exception as e:
        logger.info(f"❌ Failed to connect to AssemblyAI: {e}")
        await websocket.close()
        return

    try:
        while True:
            data = await websocket.receive_bytes()
            transcription_service.feed_audio(data)
            
    except WebSocketDisconnect:
        logger.info("📱 Flutter client disconnected")
    except Exception as e:
        logger.info(f"🚨 Unexpected error in loop: {e}")
    finally:
        transcription_service.close()

@app.post("/generate_cues/")
async def generate_cues(transcription: str = Body(..., embed=True), goal: str = Body(..., embed=True)):
    return cue_service.generate_cues(transcription, goal)

@app.post("/simplify_prompt/")
async def simplify_prompt(prompt: str = Body(..., embed=True)):
    return cue_service.simplify_prompt(prompt)

@app.post("/seed_exercises/")
def seed_exercises():
    sample_exercises = [
        {"id": "1", "text": "I would like to order the tomato soup", "metadata": {"type": "semantic", "target": "restaurant order"}},
        {"id": "2", "text": "I am missing a spoon", "metadata": {"type": "semantic", "target": "restaurant inquiry"}},
        {"id": "3", "text": "I would like tap water", "metadata": {"type": "semantic", "target": "beverages"}},
        {"id": "4", "text": "The cat eats the fish", "metadata": {"type": "semantic", "target": "animals"}},
    ]
    
    for ex in sample_exercises:
        vector_service.add_exercise(
            exercise_id=ex["id"],
            text=ex["text"],
            metadata=ex["metadata"]
        )
    return {"message": f"Successfully seeded {len(sample_exercises)} exercises"}


@app.post("/find_relevant_exercise/")
async def find_exercise(transcription: str = Body(..., embed=True)):
    results = vector_service.search_exercises(query_text=transcription, n_results=2)
    
    return {
        "transcription_received": transcription,
        "matching_exercises": results["documents"],
        "metadata": results["metadatas"],
        "distances": results["distances"]
    }
