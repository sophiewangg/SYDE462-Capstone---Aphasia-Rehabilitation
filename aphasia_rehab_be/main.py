import uuid
from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect, Body
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import database
import models
import asyncio
import os
from dotenv import load_dotenv
from services import TranscriptionService, CueService, DisfluencyDetectionService, create_user_record, save_session
import logging
import os
from datetime import datetime
import wave

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")
load_dotenv() # Loads API key from your .env file

#create postgres models (defined within models.py) before app starts
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()
app.mount("/detections", StaticFiles(directory="detections"), name="detections")

# Initialize the service with API key
transcription_service = TranscriptionService(api_key=os.getenv("ASSEMBLYAI_API_KEY"))
cue_service = CueService(api_key=os.getenv("GPT_API_KEY"))
disfluency_detection_service = DisfluencyDetectionService()

# root endpoint (can use as health check)
@app.get("/")
def root():
    return {"message": "Hello World"}

# when request hits API, FastAPI opens a temporary session with the DB, performs the action and closes the session
@app.post("/users/")
def create_user(full_name: str, email: str, db: Session = Depends(database.get_db)):
    return create_user_record(db, full_name=full_name, email=email)

@app.post("/module_attempts/")
# TODO: implement

def save_session(user_id: uuid.UUID, db: Session = Depends(database.get_db)):
    session_stats = dict()
    return save_session(db, user_id = user_id, session_stats = session_stats)

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
        # FIX: Use 'transcription_service' (your instance), NOT 'service' (the file)
        transcription_service.connect_to_assemblyai(websocket, loop)
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