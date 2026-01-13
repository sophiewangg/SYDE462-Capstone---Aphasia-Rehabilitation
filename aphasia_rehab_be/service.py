from sqlalchemy.orm import Session
import models

def create_user_record(db: Session, email: str):
    # TODO: business logic would go here (e.g. validating email)

    new_user = models.User(email=email)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user