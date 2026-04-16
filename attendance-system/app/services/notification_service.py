from twilio.rest import Client
import resend
from sqlalchemy.orm import Session
from app.config import settings
import logging

logger = logging.getLogger(__name__)

resend.api_key = settings.resend_api_key


class NotificationService:
    def __init__(self):
        self.twilio_client = Client(
            settings.twilio_account_sid,
            settings.twilio_auth_token
        )

    def send_sms(self, phone: str, message: str) -> dict:
        try:
            self.twilio_client.messages.create(
                body=message,
                from_=settings.twilio_phone_number,
                to=phone
            )
            return {"status": "sent"}
        except Exception as e:
            logger.error(f"SMS failed to {phone}: {e}")
            return {"status": "failed", "error": str(e)}

    def send_email(self, email: str, subject: str, message: str) -> dict:
        try:
            resend.Emails.send({
                "from": settings.resend_from_email,
                "to": email,
                "subject": subject,
                "text": message,
            })
            return {"status": "sent"}
        except Exception as e:
            logger.error(f"Email failed to {email}: {e}")
            return {"status": "failed", "error": str(e)}


def notify_parents_of_attendance(
    db: Session,
    student,
    attendance_record,
    notification_svc: NotificationService = None
):
    from app.models import Parent, ParentStudent, User, Notification, UserRole

    if notification_svc is None:
        notification_svc = NotificationService()

    links = db.query(ParentStudent).filter(
        ParentStudent.student_id == student.id
    ).all()

    timestamp_str = attendance_record.timestamp.strftime("%I:%M %p") if attendance_record.timestamp else "now"
    message = (
        f"Your child {student.full_name} was recorded present at "
        f"{attendance_record.camera_location.replace('_', ' ').title()} at {timestamp_str}."
    )
    subject = f"Attendance Alert - {student.full_name}"

    for link in links:
        parent = db.query(Parent).filter(Parent.id == link.parent_id).first()
        if not parent or not parent.is_active:
            continue

        prefs = parent.notification_preferences or {}
        parent_user = db.query(User).filter(
            User.profile_id == parent.id,
            User.role == UserRole.parent
        ).first()

        if prefs.get("sms", True) and parent.phone:
            result = notification_svc.send_sms(parent.phone, message)
            _save_notification(db, "sms", parent.phone, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id if parent_user else None,
                               result.get("status", "failed"))

        if prefs.get("email", True) and parent.email:
            result = notification_svc.send_email(parent.email, subject, message)
            _save_notification(db, "email", parent.email, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id if parent_user else None,
                               result.get("status", "failed"))

        if prefs.get("in_app", True) and parent_user:
            _save_notification(db, "in_app", parent.email, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id, "sent")

    db.commit()


def notify_users_of_announcement(db: Session, announcement, notification_svc: NotificationService = None):
    from app.models import User, Parent, Notification, UserRole

    if notification_svc is None:
        notification_svc = NotificationService()

    target_roles = announcement.target_roles or []
    users = db.query(User).filter(
        User.is_active == True,
        User.role.in_(target_roles)
    ).all()

    for user in users:
        _save_notification(
            db, "in_app", user.email,
            announcement.title, announcement.content,
            None, None, user.id, "sent",
            announcement_id=announcement.id
        )

        if user.role == UserRole.parent and user.profile_id:
            parent = db.query(Parent).filter(Parent.id == user.profile_id).first()
            if parent and (parent.notification_preferences or {}).get("email", True):
                notification_svc.send_email(user.email, announcement.title, announcement.content)

    db.commit()


def _save_notification(
    db, notif_type, recipient, title, message,
    attendance_record_id, student_id, recipient_user_id,
    status, announcement_id=None
):
    from app.models import Notification
    from datetime import datetime

    notif = Notification(
        notification_type=notif_type,
        recipient=recipient,
        title=title,
        message=message,
        attendance_record_id=attendance_record_id,
        student_id=student_id,
        recipient_user_id=recipient_user_id,
        announcement_id=announcement_id,
        status=status,
        sent_at=datetime.utcnow() if status == "sent" else None,
    )
    db.add(notif)
