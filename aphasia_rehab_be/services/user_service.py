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

def save_session(db: Session, user_id: uuid.UUID, session_stats: dict):
    #TODO: implementation
    session_id = uuid.uuid4()

    new_attempt = models.ModuleAttempt(
        id = session_id,
        user_id=user_id,
        module_name=session_stats['module_name'],
        cues_used=session_stats['cues_used'],
        duration_seconds=session_stats['audio_length']
    )
    
    db.add(new_attempt)
    db.commit()