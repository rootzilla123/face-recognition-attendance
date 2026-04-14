from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID

from app.database import get_db
from app.models import Notification, User, Parent, ParentStudent, Student
from app.dependencies import get_current_user, require_admin
from app.services.notification_service import NotificationService

router = APIRouter()


class NotificationResponse(BaseModel):
    id: UUID
    notification_type: str
    recipient: str
    title: Optional[str]
    message: str
    status: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationPrefsUpdate(BaseModel):
    sms: Optional[bool] = None
    email: Optional[bool] = None
    in_app: Optional[bool] = None
    language: Optional[str] = None


@router.get("/", response_model=List[NotificationResponse])
def get_my_notifications(
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get in-app notifications for the current user"""
    query = db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
        Notification.notification_type == "in_app"
    )
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).limit(50).all()


@router.post("/{notification_id}/read")
def mark_as_read(
    notification_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.recipient_user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    return {"message": "Marked as read"}


@router.post("/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
        Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"message": "All notifications marked as read"}


@router.get("/unread-count")
def unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    count = db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
        Notification.notification_type == "in_app",
        Notification.is_read == False
    ).count()
    return {"unread_count": count}


@router.put("/preferences")
def update_notification_preferences(
    prefs: NotificationPrefsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update notification preferences for parents"""
    from app.models import UserRole
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can update notification preferences")

    parent = db.query(Parent).filter(Parent.id == current_user.profile_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="Parent profile not found")

    current_prefs = dict(parent.notification_preferences or {})
    updates = prefs.model_dump(exclude_none=True)
    current_prefs.update(updates)
    parent.notification_preferences = current_prefs
    db.commit()
    return {"message": "Preferences updated", "preferences": current_prefs}


@router.post("/send-test")
def send_test_notification(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Admin only: send a test notification to verify SMS/email config"""
    svc = NotificationService()
    results = {}
    results["email"] = svc.send_email(
        current_user.email,
        "Test Notification",
        "This is a test notification from the attendance system."
    )
    return {"results": results}


@router.get("/preferences")
def get_notification_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from app.models import UserRole
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access preferences")
    parent = db.query(Parent).filter(Parent.id == current_user.profile_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="Parent profile not found")
    return {"preferences": parent.notification_preferences or {}}
