import requests
import json
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from database.models import Prompt, ScenarioStep, SkillPracticed 
from google.cloud import storage
from datetime import timedelta
from dotenv import load_dotenv
from uuid import UUID

class PromptService:

    def __init__(self, db: Session):
        load_dotenv()
        self.db = db
        self.storage_client = storage.Client()

    def next_prompt(self, scenario_step_description: str):
        # 1. Use self.db (the one from __init__)
        # 2. Make sure Prompt and ScenarioStep are imported above
        statement = (
            select(Prompt)
            .join(ScenarioStep)
            .where(ScenarioStep.description == scenario_step_description)
        )

        # Use self.db here!
        result = self.db.execute(statement).scalar_one_or_none()

        if result is None:
            raise HTTPException(
                status_code=404, 
                detail="Prompt not found for the given scenario step description"
            )
        print(result.audio_url)

        result.image_speaking_url = self.generate_signed_url('speakeasy_characters', result.image_speaking_url)
        result.image_listening_url = self.generate_signed_url('speakeasy_characters', result.image_listening_url)
        result.image_confused_url = self.generate_signed_url('speakeasy_characters', result.image_confused_url)
        result.audio_url = self.generate_signed_url('speakeasy_voice_audios', result.audio_url)

        return result

    def generate_signed_url(self, bucket_name, blob_name):
        """Generates a v4 signed URL for downloading a blob."""
        bucket = self.storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_name)

        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(minutes=15),  # URL valid for 15 mins
            method="GET",
        )

        return url

    def get_skill_name(self, skillId: str):
        try:
            # Convert string to UUID object
            uuid_obj = UUID(skillId)
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail="Invalid UUID format"
            )

        statement = select(SkillPracticed).where(SkillPracticed.id == uuid_obj)
        result = self.db.execute(statement).scalar_one_or_none()

        if result is None:
            raise HTTPException(
                status_code=404, 
                detail="Skill not found for the given skill ID"
            )
        
        return result.skill_name