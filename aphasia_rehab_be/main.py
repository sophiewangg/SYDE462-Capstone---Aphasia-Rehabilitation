import uuid
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
import database
import models
import service

#create postgres models (defined within models.py) before app starts
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

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
