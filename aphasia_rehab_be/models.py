from datetime import datetime
import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(255), nullable=False)
    email = Column(String(225), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    attempts = relationship("ModuleAttempt", back_populates="user")

class Module(Base):
    __tablename__ = "modules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    difficulty_level = Column(Integer, nullable=False)

class ModuleAttempt(Base):
    __tablename__ = "module_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    module_id = Column(String(100), ForeignKey("modules.id"), nullable=False)
    
    stutter_count = Column(Integer, default=0)
    filler_words = Column(Integer, default=0)
    cues_used = Column(JSON, nullable=False)
    
    duration_seconds = Column(Numeric(precision=10, scale=2), nullable=False)
    completed_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="attempts")