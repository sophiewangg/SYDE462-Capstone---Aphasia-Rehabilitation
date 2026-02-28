import io
from celery import Celery, group
from pydub import AudioSegment
import wave
import os
from services import DisfluencyDetectionService

# Configure Celery to use Redis as the broker and backend
celery_app = Celery(
    "worker",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/0"
)

# 1. Ensure you have the instance created at the top level
service = DisfluencyDetectionService()

@celery_app.task(name="worker.process_recording_pipeline")
def process_recording_pipeline(raw_filepath: str):
    # 1. Read the raw file
    with open(raw_filepath, "rb") as f:
        raw_data = f.read()
    
    # 2. Convert to WAV in memory
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav_f:
        wav_f.setnchannels(1)
        wav_f.setsampwidth(2) 
        wav_f.setframerate(16000)
        wav_f.writeframes(raw_data)
    
    wav_bytes = buffer.getvalue()
    
    # 3. Trigger the chunking task we wrote earlier
    # Use .delay() to keep the pipeline moving
    chunk_audio.delay(wav_bytes)
    
    # 4. Cleanup the raw file
    os.remove(raw_filepath)
    return "Pipeline started"

@celery_app.task(name="worker.classify_sound_rep_task")
def classify_sound_rep_task(audio_buffer_bytes, threshold=0.74):
    # This task receives the bytes, and hands them to the service instance
    # Notice: NO 'self' in the arguments here!
    label, confidence = service.classify_sound_rep(audio_buffer_bytes, threshold=threshold)
    
    return {"label": label, "confidence": confidence}

@celery_app.task(name="worker.classify_interjection_task")
def classify_interjection_task(audio_buffer_bytes, threshold=0.74):
    # This task receives the bytes, and hands them to the service instance
    # Notice: NO 'self' in the arguments here!
    label, confidence = service.classify_interjection(audio_buffer_bytes, threshold=threshold)
    
    return {"label": label, "confidence": confidence}

def is_audible(chunk):
    """
    Calibrated based on logs:
    - Real speech: ~ -44dB / 850 Max
    - Real silence: ~ -65dB / 90 Max
    """
    # -55.0 is a safe floor that sits between your silence (-65) and speech (-44)
    db_threshold = -55.0
    # 500 is a safe peak floor that sits between your silence (90) and speech (868)
    peak_threshold = 500

    # Use 'or' so that even a soft, long sound OR a sharp, short word triggers it
    passed = chunk.dBFS > db_threshold or chunk.max > peak_threshold
    
    print(f"DEBUG: {'PASSING' if passed else 'SKIPPING'} - dBFS: {chunk.dBFS:.2f}, Max: {chunk.max}")
    return passed

@celery_app.task(name="worker.chunk_audio")
def chunk_audio(wav_bytes: bytes):
    audio = AudioSegment.from_file(io.BytesIO(wav_bytes), format="wav")
    total_ms = len(audio)
    
    chunk_length_ms = 3000
    signatures_sound_rep = []
    signatures_interjection = []

    for i in range(0, total_ms, chunk_length_ms):
        chunk = audio[i:i + chunk_length_ms]
        
        # 1. Reject tiny fragments
        if len(chunk) < 3000:
            continue
            
        # 2. CALL THE STRICT CHECK
        # Adjust thresholds here to make it even stricter if needed
        if not is_audible(chunk):
            print(f"DEBUG: Skipping silent/noisy chunk at {i}ms")
            continue
            
        buffer = io.BytesIO()
        chunk.export(buffer, format="wav")
        chunk_data = buffer.getvalue()
        
        signatures_sound_rep.append(classify_sound_rep_task.s(chunk_data))
        signatures_interjection.append(classify_interjection_task.s(chunk_data))

    if not signatures_sound_rep:
        return {"status": "skipped", "reason": "no_audible_content"}

    job_sound_rep = group(signatures_sound_rep).apply_async()
    job_interjection = group(signatures_interjection).apply_async()
    
    return {
        "status": "fanned_out", 
        "total_chunks": len(signatures_sound_rep), 
        "sound_rep_group_id": job_sound_rep.id,
        "interjection_group_id": job_interjection.id
    }