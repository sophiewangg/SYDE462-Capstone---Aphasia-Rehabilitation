import uuid
from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
import database
import models
import service
import asyncio
import os
from dotenv import load_dotenv
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")
load_dotenv() # Loads API key from your .env file

#create postgres models (defined within models.py) before app starts
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

# Initialize the service with API key
transcription_service = service.TranscriptionService(api_key=os.getenv("ASSEMBLYAI_API_KEY"))

# root endpoint (can use as health check)
@app.get("/")
def root():
    return {"message": "Hello World"}

# when request hits API, FastAPI opens a temporary session with the DB, performs the action and closes the session
@app.post("/users/")
def create_user(full_name: str, email: str, db: Session = Depends(database.get_db)):
    return service.create_user_record(db, full_name=full_name, email=email)

@app.post("/module_attempts/")
# TODO: implement

def save_session(user_id: uuid.UUID, db: Session = Depends(database.get_db)):
    session_stats = dict()
    return service.save_session(db, user_id = user_id, session_stats = session_stats)

def create_user(email: str, db: Session = Depends(database.get_db)):
    return service.create_user_record(db, email=email)

@app.websocket("/ws/transcribe")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("📱 Flutter client connected")
    
    # Use get_running_loop for better compatibility with FastAPI
    loop = asyncio.get_running_loop()
    
    try:
        # FIX: Use 'transcription_service' (your instance), NOT 'service' (the file)
        transcription_service.connect_to_assemblyai(websocket, loop)
    except Exception as e:
        logger.info(f"❌ Failed to connect to AssemblyAI: {e}")
        await websocket.close()
        return

    try:
        while True:
            # Receive binary audio from Flutter
            data = await websocket.receive_bytes()
            transcription_service.feed_audio(data)
            
    except WebSocketDisconnect:
        logger.info("📱 Flutter client disconnected")
    except Exception as e:
        logger.info(f"🚨 Unexpected error in loop: {e}")
    finally:
        transcription_service.close()