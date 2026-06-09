from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID

from app.database import get_db
from app.models import Notification, User, Parent, Teacher, Administrator, ParentStudent, Student, UserRole
from app.dependencies import get_current_user, require_admin
from app.services.notification_service import NotificationService, _get_profile_and_prefs

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


@router.get("/all-types", response_model=List[NotificationResponse])
def get_all_notifications(
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all notification types (in-app, sms, email) for the current user"""
    return db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
    ).order_by(Notification.created_at.desc()).limit(limit).all()


@router.get("/sms-history", response_model=List[NotificationResponse])
def get_sms_history(
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get SMS notification history for the current user"""
    return db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
        Notification.notification_type == "sms"
    ).order_by(Notification.created_at.desc()).limit(limit).all()


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


@router.get("/preferences")
def get_notification_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get notification preferences for current user (any role)"""
    _, prefs, phone, email = _get_profile_and_prefs(db, current_user)
    return {
        "preferences": prefs,
        "phone": phone,
        "email": email,
        "role": current_user.role.value,
        "sms_enabled": bool(phone),
    }


@router.put("/preferences")
def update_notification_preferences(
    prefs: NotificationPrefsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update notification preferences for any role (parent, teacher, admin)"""
    profile = None

    if current_user.role == UserRole.parent and current_user.profile_id:
        profile = db.query(Parent).filter(Parent.id == current_user.profile_id).first()
    elif current_user.role == UserRole.teacher and current_user.profile_id:
        profile = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
    elif current_user.role == UserRole.admin and current_user.profile_id:
        profile = db.query(Administrator).filter(Administrator.id == current_user.profile_id).first()

    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    if not hasattr(profile, 'notification_preferences'):
        raise HTTPException(status_code=400, detail="This profile does not support notification preferences")

    current_prefs = dict(profile.notification_preferences or {})
    updates = prefs.model_dump(exclude_none=True)
    current_prefs.update(updates)
    profile.notification_preferences = current_prefs
    db.commit()
    return {"message": "Preferences updated", "preferences": current_prefs}


@router.post("/send-test")
def send_test_notification(
    phone: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send a test SMS/email notification to verify configuration"""
    svc = NotificationService()
    results = {}
    
    # Determine phone number based on role
    _, _, profile_phone, profile_email = _get_profile_and_prefs(db, current_user)
    target_phone = phone or profile_phone
    
    # Send test SMS
    if target_phone:
        results["sms"] = svc.send_sms(
            target_phone,
            f"✅ Test SMS from AttendanceAI. Your SMS notifications are working correctly! ({current_user.role.value})"
        )
    else:
        results["sms"] = {"status": "skipped", "reason": "No phone number available. Add one to your profile."}
    
    # Send test email
    target_email = profile_email or current_user.email
    if target_email:
        results["email"] = svc.send_email(
            target_email,
            "Test Notification - AttendanceAI",
            f"This is a test notification from the AttendanceAI system. Your email notifications are working correctly! (Role: {current_user.role.value})"
        )
    else:
        results["email"] = {"status": "skipped", "reason": "No email address available"}
    
    return {
        "results": results,
        "phone_used": target_phone,
        "email_used": target_email,
        "role": current_user.role.value,
    }
