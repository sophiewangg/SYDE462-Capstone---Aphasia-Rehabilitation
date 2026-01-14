from sqlalchemy.orm import Session
import models
import uuid

def create_user_record(db: Session, full_name: str, email: str):
    user_id = uuid.uuid4()

    new_user = models.User(user_id=user_id, full_name=full_name, email=email)
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

def save_session(db: Session, user_id: uuid.UUID, analysis_results: dict):
    #TODO: implementation

    new_attempt = models.ModuleAttempt(
        user_id=user_id,
        module_name="Word Finding - Level 1",
        stutter_count=analysis_results['disfluency_total'],
        filler_words=analysis_results['filler_counts'],
        cues_used=analysis_results['cues_triggered'],
        duration_seconds=analysis_results['audio_length']
    )
    
    db.add(new_attempt)
    db.commit()