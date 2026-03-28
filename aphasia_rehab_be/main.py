import asyncio
import json
import logging
import os
import re # Added for utterance chunking
from pathlib import Path
import uuid
from datetime import datetime

from database import database, models
from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, WebSocket, WebSocketDisconnect, Query
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from celery.result import AsyncResult
from worker import celery_app

from services import (CueService, TranscriptionService, UserService, VectorService, DisfluencyDetectionService, PromptService, DashboardService)


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
dashoboard_service = DashboardService(api_key=os.getenv("GPT_API_KEY"))

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
async def generate_cues(transcription: str = Body(..., embed=True), goal: str = Body(..., embed=True), ordering_step: bool = False):
    return cue_service.generate_cues(transcription, goal, ordering_step)

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
    current_step: str = Body(None, embed=True), 
    global_search: bool = Body(False, embed=True), # 👈 Added this parameter
    threshold: float = Query(0.40),
):
    """
    Splits the transcription into chunks and runs vector similarity.
    The frontend dictates whether to search globally via the global_search flag.
    """
    
    # 1. Frontend controls the filter scope
    if current_step and not global_search:
        step_filter = {"step": current_step}
        logger.info(f"🔒 Strict filter applied for step: {current_step}")
    else:
        step_filter = None
        logger.info(f"🌐 Global search executed (Step recorded as: {current_step})")

    # 2. Chunking the transcription
    raw_chunks = re.split(r'\b(?:and|with|also|then)\b|,|\.|;', transcription.lower())
    chunks = [chunk.strip() for chunk in raw_chunks if len(chunk.strip()) > 2]
    if not chunks:
        chunks = [transcription]

    detected_intents = set()
    best_distance = None
    best_metadata = None

    # 3. Querying the Vector Database
    for chunk in chunks:
        results = vector_service.search_exercises(
            query_text=chunk, 
            n_results=1,
            filter_metadata=step_filter  # Applies None or the strict dictionary
        )
        
        distances = results.get("distances") or []
        metadatas = results.get("metadatas") or []

        if distances and distances[0] and metadatas and metadatas[0]:
            distance = distances[0][0]
            metadata = metadatas[0][0]

            if distance <= threshold:
                intent = metadata.get("intent")
                if intent:
                    detected_intents.add(intent)
                    
                    if best_distance is None or distance < best_distance:
                        best_distance = distance
                        best_metadata = metadata

    is_match = len(detected_intents) > 0

    return {
        "match": is_match,
        "intents": list(detected_intents), 
        "distance": best_distance,
        "metadata": best_metadata,
        "text": transcription
    }

@app.post("/verify_order_correction/")
async def verify_order_correction(
    transcription: str = Body(..., embed=True),
    ordered_items: list[str] = Body(..., embed=True),
    served_items: list[str] = Body(..., embed=True),
    threshold: float = Query(0.40),
):
    raw_chunks = re.split(r'\b(?:and|with|also|then|but)\b|,|\.|;', transcription.lower())
    chunks = [chunk.strip() for chunk in raw_chunks if len(chunk.strip()) > 2]
    if not chunks:
        chunks = [transcription.lower()]

    negation_words = {"no", "not", "didn't", "did not", "wrong", "instead", "never"}
    affirmation_words = {"yes", "yeah", "yep", "correct", "right", "good", "fine", "okay"}
    
    detected_intents = set()
    rejected_intents = set()
    
    is_generic_no = False
    is_generic_yes = False
    
    for chunk in chunks:
        words = chunk.split()
        
        if any(word in negation_words for word in words):
            is_generic_no = True
        if any(word in affirmation_words for word in words) and not is_generic_no:
            is_generic_yes = True

        results = vector_service.search_exercises(
            query_text=chunk, 
            n_results=1,
            filter_metadata=None 
        )
        
        distances = results.get("distances") or []
        metadatas = results.get("metadatas") or []

        if distances and distances[0] and metadatas and metadatas[0]:
            distance = distances[0][0]
            metadata = metadatas[0][0]

            if distance <= threshold:
                intent = metadata.get("intent")
                if intent:
                    if intent.startswith("order_"):
                        if is_generic_no:
                            rejected_intents.add(intent)
                        else:
                            detected_intents.add(intent)
                    elif intent in ["nudge_no", "wrong_order_general"]:
                        is_generic_no = True
                    elif intent in ["nudge_yes"]:
                        is_generic_yes = True

    mentioned_correct_item = any(item in detected_intents for item in ordered_items)
    rejected_wrong_item = any(item in rejected_intents for item in served_items)
    claimed_wrong_item = any(item in detected_intents for item in served_items)
    
    # They successfully corrected the waiter if they mentioned the right item, rejected the wrong one, OR just said "No"
    is_corrected = (mentioned_correct_item or rejected_wrong_item or is_generic_no) and not claimed_wrong_item
    
    # They mistakenly accepted the wrong food if they explicitly said "Yes" or claimed the wrong item
    accepted_wrong_food = (is_generic_yes or claimed_wrong_item) and not is_corrected

    return {
        "is_corrected": is_corrected,
        "accepted_wrong_food": accepted_wrong_food, # 👈 Send this back to Flutter!
        "mentioned_correct_item": mentioned_correct_item,
        "rejected_wrong_item": rejected_wrong_item,
        "text": transcription
    }
@app.get("/list_detections")
async def list_detections(disfluency_type):
    detection_dir = "detections"
    if not os.path.exists(detection_dir + '/' + disfluency_type):
        return []
    
    # Get all .wav files in the folder
    files = [f for f in os.listdir(detection_dir + '/' + disfluency_type) if f.endswith(".wav")]
    # Sort by name (which is timestamped) so newest are at the top
    files.sort(reverse=True)
    return files

@app.post("/clear_detections")
def clear_detections():
    disfluency_detection_service.clear_detections("sound_rep")
    disfluency_detection_service.clear_detections("interjection")

@app.post("/clear_detection")
def clear_detections(filename: str, disfluency_type: str):
    disfluency_detection_service.clear_detection(filename, disfluency_type)

@app.get("/next_prompt")
def next_prompt(scenario_step_description: str, db: Session = Depends(database.get_db)):
    prompt_service = PromptService(db)
    res = prompt_service.next_prompt(scenario_step_description)
    print(res)
    return res

@app.get("/generate_signed_url")
def generate_signed_url(
    url: str, 
    bucket: str, 
    db: Session = Depends(database.get_db)
):
    prompt_service = PromptService(db)
    return prompt_service.generate_signed_url(bucket, url)

@app.get("/get_skill_name")
def get_skill_name(skill_id: str, db: Session = Depends(database.get_db)):
    prompt_service = PromptService(db)
    result =  prompt_service.get_skill_name(skill_id)
    return {"skill_name": result}

@app.post("/improve_response")
def get_skill_name(prompt: str, response: str):
    result = dashoboard_service.improve_response(prompt, response)
    return result

@app.get("/task_status/{task_id}")
async def get_task_status(task_id: str):
    # Connect to the task in Redis
    task_result = AsyncResult(task_id, app=celery_app)
    
    response = {
        "task_id": task_id,
        "status": task_result.status, # e.g., 'PENDING', 'SUCCESS', 'FAILURE'
        "result": None
    }

    if task_result.ready():
        print(task_result.result)
        # task_result.result will contain whatever your worker returned
        response["result"] = task_result.result

    return response