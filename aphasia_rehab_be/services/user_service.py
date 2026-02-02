from __future__ import annotations
from sqlalchemy.orm import Session
from database import models
import uuid

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def create_user_record(self, full_name: str, email: str):
        user_id = uuid.uuid4()
        new_user = models.User(
            user_id=user_id, 
            full_name=full_name, 
            email=email
        )
        
        self.db.add(new_user)
        self.db.commit()
        self.db.refresh(new_user)
        return new_user

    def save_session(self, module_id: uuid.UUID, user_id: uuid.UUID, session_stats: dict):
        session_id = uuid.uuid4()

        new_attempt = models.ModuleAttempt(
            id=session_id,
            user_id=user_id,
            module_id=module_id,
            cues_used=session_stats.get('cues_used', 0),
            duration_seconds=session_stats.get('audio_length', 0)
        )
        
        self.db.add(new_attempt)
        self.db.commit()
        return new_attempt