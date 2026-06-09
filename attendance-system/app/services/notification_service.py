from twilio.rest import Client
import resend
from sqlalchemy.orm import Session
from app.config import settings
import logging
from datetime import datetime, timedelta
from collections import defaultdict
from app.services.push_notification_service import PushNotificationService
import time

logger = logging.getLogger(__name__)

resend.api_key = settings.resend_api_key


class NotificationService:
    _sms_rate_limit: dict = defaultdict(list)
    _max_sms_per_hour: int = 20
    _max_retry_attempts: int = 3
    _backoff_seconds: tuple = (1, 2, 4)

    def __init__(self):
        self._twilio = None
        self._push_service = PushNotificationService()
        try:
            if (settings.twilio_account_sid and
                    not settings.twilio_account_sid.startswith('your') and
                    settings.twilio_auth_token and
                    not settings.twilio_auth_token.startswith('your')):
                self._twilio = Client(settings.twilio_account_sid, settings.twilio_auth_token)
                logger.info("Twilio client initialized successfully")
        except Exception as e:
            logger.warning(f"Twilio init failed (SMS disabled): {e}")

    def send_sms(self, phone: str, message: str) -> dict:
        if not self._twilio:
            logger.info(f"SMS skipped (Twilio not configured) to {phone}")
            return {"status": "skipped", "reason": "Twilio not configured"}
        if not phone or not phone.startswith('+'):
            logger.warning(f"SMS skipped – invalid phone format: {phone}")
            return {"status": "failed", "error": "Phone must be in E.164 format (e.g. +1234567890)"}

        # Rate limiting
        now = datetime.utcnow()
        recent = [t for t in self._sms_rate_limit[phone] if now - t < timedelta(hours=1)]
        self._sms_rate_limit[phone] = recent
        if len(recent) >= self._max_sms_per_hour:
            logger.warning(f"SMS rate-limited for {phone}")
            return {"status": "rate_limited", "reason": "Too many SMS sent in the last hour"}

        last_error = None
        for attempt in range(self._max_retry_attempts):
            try:
                msg = self._twilio.messages.create(
                    body=message,
                    from_=settings.twilio_phone_number,
                    to=phone
                )
                self._sms_rate_limit[phone].append(now)
                logger.info(f"SMS sent to {phone}, SID: {msg.sid}")
                return {"status": "sent", "sid": msg.sid, "retry_count": attempt}
            except Exception as e:
                last_error = str(e)
                failure_type = self._classify_failure(e)
                logger.error(
                    f"SMS failed to {phone} (attempt {attempt + 1}/{self._max_retry_attempts}, {failure_type}): {e}"
                )
                if failure_type == "permanent":
                    return {
                        "status": "failed",
                        "error": last_error,
                        "retry_count": attempt,
                        "failure_type": "permanent",
                        "needs_manual_review": True,
                    }
                if attempt < self._max_retry_attempts - 1:
                    time.sleep(self._backoff_seconds[min(attempt, len(self._backoff_seconds) - 1)])

        return {
            "status": "failed",
            "error": last_error or "Unknown SMS failure",
            "retry_count": self._max_retry_attempts,
            "failure_type": "transient",
            "needs_manual_review": True,
        }

    def send_email(self, email: str, subject: str, message: str) -> dict:
        if not email:
            return {"status": "skipped", "reason": "No email address"}
        last_error = None
        for attempt in range(self._max_retry_attempts):
            try:
                resend.Emails.send({
                    "from": settings.resend_from_email,
                    "to": email,
                    "subject": subject,
                    "text": message,
                })
                return {"status": "sent", "retry_count": attempt}
            except Exception as e:
                last_error = str(e)
                failure_type = self._classify_failure(e)
                logger.error(
                    f"Email failed to {email} (attempt {attempt + 1}/{self._max_retry_attempts}, {failure_type}): {e}"
                )
                if failure_type == "permanent":
                    return {
                        "status": "failed",
                        "error": last_error,
                        "retry_count": attempt,
                        "failure_type": "permanent",
                        "needs_manual_review": True,
                    }
                if attempt < self._max_retry_attempts - 1:
                    time.sleep(self._backoff_seconds[min(attempt, len(self._backoff_seconds) - 1)])

        return {
            "status": "failed",
            "error": last_error or "Unknown email failure",
            "retry_count": self._max_retry_attempts,
            "failure_type": "transient",
            "needs_manual_review": True,
        }

    @staticmethod
    def _classify_failure(error: Exception) -> str:
        """Classify provider errors into permanent/transient for retry policy."""
        text = str(error).lower()
        permanent_markers = [
            "invalid",
            "unauthorized",
            "authentication",
            "forbidden",
            "permission",
            "bad request",
            "not a valid",
            "unverified",
        ]
        transient_markers = [
            "timeout",
            "temporar",
            "connection",
            "rate limit",
            "too many requests",
            "503",
            "502",
            "500",
            "gateway",
        ]
        if any(marker in text for marker in permanent_markers):
            return "permanent"
        if any(marker in text for marker in transient_markers):
            return "transient"
        return "transient"


# ── Helper: get profile + preferences for any role ──────────────

def _get_profile_and_prefs(db, user):
    """Return (profile_obj, prefs_dict, phone, email) for any user role."""
    from app.models import Parent, Teacher, Administrator, UserRole

    profile = None
    prefs = {"sms": True, "email": True, "in_app": True, "language": "en"}
    phone = None
    email = user.email

    if user.role == UserRole.parent and user.profile_id:
        profile = db.query(Parent).filter(Parent.id == user.profile_id).first()
        if profile:
            prefs = profile.notification_preferences or prefs
            phone = profile.phone
            email = profile.email or email

    elif user.role == UserRole.teacher and user.profile_id:
        profile = db.query(Teacher).filter(Teacher.id == user.profile_id).first()
        if profile:
            prefs = profile.notification_preferences or prefs
            phone = profile.phone
            email = profile.email or email

    elif user.role == UserRole.admin and user.profile_id:
        profile = db.query(Administrator).filter(Administrator.id == user.profile_id).first()
        if profile:
            prefs = profile.notification_preferences or prefs
            phone = getattr(profile, 'phone', None)
            email = profile.email or email

    return profile, prefs, phone, email


# ── Notification dispatchers ────────────────────────────────────

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
    location = attendance_record.camera_location.replace('_', ' ').title()
    
    message = (
        f"Attendance Alert: {student.full_name} checked in at "
        f"{location} at {timestamp_str}."
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

        # Send SMS notification
        if prefs.get("sms", True) and parent.phone:
            result = notification_svc.send_sms(parent.phone, message)
            _save_notification(db, "sms", parent.phone, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id if parent_user else None,
                               result.get("status", "failed"),
                               failed_reason=result.get("error"),
                               retry_count=result.get("retry_count", 0))

        # Send Email notification
        if prefs.get("email", True) and parent.email:
            result = notification_svc.send_email(parent.email, subject, message)
            _save_notification(db, "email", parent.email, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id if parent_user else None,
                               result.get("status", "failed"),
                               failed_reason=result.get("error"),
                               retry_count=result.get("retry_count", 0))

        # Send In-App notification
        if prefs.get("in_app", True) and parent_user:
            _save_notification(db, "in_app", parent.email, subject, message,
                               attendance_record.id, student.id,
                               parent_user.id, "sent")
        
        # Send Push notification
        if prefs.get("push", True) and parent_user:
            result = notification_svc._push_service.send_to_user(
                parent_user, subject, message,
                data={"type": "attendance", "student_id": str(student.id)}
            )
            if result.get("status") == "sent":
                _save_notification(db, "push", parent.email, subject, message,
                                   attendance_record.id, student.id,
                                   parent_user.id, "sent")

    db.commit()


def notify_users_of_announcement(db: Session, announcement, notification_svc: NotificationService = None):
    """Send announcement notifications to all targeted roles via in-app, SMS, and email."""
    from app.models import User, UserRole

    if notification_svc is None:
        notification_svc = NotificationService()

    target_roles = announcement.target_roles or []
    users = db.query(User).filter(
        User.is_active == True,
        User.role.in_(target_roles)
    ).all()

    sms_body = f"{announcement.title}: {announcement.content}"

    for user in users:
        profile, prefs, phone, email = _get_profile_and_prefs(db, user)

        # In-app notification for all users
        if prefs.get("in_app", True):
            _save_notification(
                db, "in_app", user.email,
                announcement.title, announcement.content,
                None, None, user.id, "sent",
                announcement_id=announcement.id
            )

        # SMS notification (all roles)
        if prefs.get("sms", True) and phone:
            result = notification_svc.send_sms(phone, sms_body)
            _save_notification(
                db, "sms", phone,
                announcement.title, announcement.content,
                None, None, user.id, result.get("status", "failed"),
                announcement_id=announcement.id,
                failed_reason=result.get("error"),
                retry_count=result.get("retry_count", 0),
            )

        # Email notification (all roles)
        if prefs.get("email", True) and email:
            result = notification_svc.send_email(email, announcement.title, announcement.content)
            _save_notification(
                db, "email", email,
                announcement.title, announcement.content,
                None, None, user.id, result.get("status", "failed"),
                announcement_id=announcement.id,
                failed_reason=result.get("error"),
                retry_count=result.get("retry_count", 0),
            )

    db.commit()


def notify_teacher_of_student_absence(
    db: Session,
    teacher,
    student,
    date,
    notification_svc: NotificationService = None
):
    """Notify teacher when a student is absent"""
    from app.models import User, UserRole
    
    if notification_svc is None:
        notification_svc = NotificationService()
    
    message = f"Absence Alert: {student.full_name} from {student.grade_level} was not present on {date}."
    subject = f"Student Absence - {student.full_name}"
    
    teacher_user = db.query(User).filter(
        User.profile_id == teacher.id,
        User.role == UserRole.teacher
    ).first()

    prefs = teacher.notification_preferences or {"sms": True, "email": True, "in_app": True}
    
    # SMS notification
    if prefs.get("sms", True) and teacher.phone:
        result = notification_svc.send_sms(teacher.phone, message)
        _save_notification(db, "sms", teacher.phone, subject, message,
                           None, student.id, teacher_user.id if teacher_user else None,
                           result.get("status", "failed"),
                           failed_reason=result.get("error"),
                           retry_count=result.get("retry_count", 0))

    # Email notification
    if prefs.get("email", True) and teacher.email:
        result = notification_svc.send_email(teacher.email, subject, message)
        _save_notification(db, "email", teacher.email, subject, message,
                           None, student.id, teacher_user.id if teacher_user else None,
                           result.get("status", "failed"),
                           failed_reason=result.get("error"),
                           retry_count=result.get("retry_count", 0))

    # In-app notification
    if prefs.get("in_app", True) and teacher_user:
        _save_notification(db, "in_app", teacher.email, subject, message,
                           None, student.id, teacher_user.id, "sent")
    
    db.commit()


def notify_admin_of_system_event(
    db: Session,
    event_type: str,
    message: str,
    notification_svc: NotificationService = None
):
    """Notify admins of system events (camera offline, errors, etc.) via in-app, SMS, and email."""
    from app.models import User, Administrator, UserRole
    
    if notification_svc is None:
        notification_svc = NotificationService()
    
    admins = db.query(User).filter(
        User.role == UserRole.admin,
        User.is_active == True
    ).all()
    
    subject = f"System Alert: {event_type}"
    critical_events = ["Camera Offline", "System Error", "Security Alert"]
    
    for admin in admins:
        profile, prefs, phone, email = _get_profile_and_prefs(db, admin)

        # In-app notification (always)
        if prefs.get("in_app", True):
            _save_notification(db, "in_app", admin.email, subject, message,
                               None, None, admin.id, "sent")
        
        # Email for all system events
        if prefs.get("email", True) and email:
            result = notification_svc.send_email(email, subject, message)
            _save_notification(db, "email", email, subject, message,
                               None, None, admin.id, result.get("status", "failed"),
                               failed_reason=result.get("error"),
                               retry_count=result.get("retry_count", 0))

        # SMS for critical events
        if event_type in critical_events and prefs.get("sms", True) and phone:
            result = notification_svc.send_sms(phone, f"[URGENT] {subject}: {message}")
            _save_notification(db, "sms", phone, subject, message,
                               None, None, admin.id, result.get("status", "failed"),
                               failed_reason=result.get("error"),
                               retry_count=result.get("retry_count", 0))
    
    db.commit()


def _save_notification(
    db, notif_type, recipient, title, message,
    attendance_record_id, student_id, recipient_user_id,
    status, announcement_id=None, failed_reason=None, retry_count=0
):
    from app.models import Notification
    from datetime import datetime

    notif = Notification(
        notification_type=notif_type,
        recipient=recipient or "",
        title=title,
        message=message,
        attendance_record_id=attendance_record_id,
        student_id=student_id,
        recipient_user_id=recipient_user_id,
        announcement_id=announcement_id,
        status=status,
        sent_at=datetime.utcnow() if status == "sent" else None,
        failed_reason=failed_reason,
        retry_count=retry_count,
    )
    db.add(notif)


# ── Notification cleanup ──────────────────────────────────────────────────────

async def notification_cleanup_loop(retention_days: int = 30):
    """
    Background task — deletes read in-app notifications older than retention_days
    and sent/failed SMS/email records older than retention_days.
    Runs once per day.
    """
    import asyncio
    from datetime import datetime, timedelta

    while True:
        await asyncio.sleep(86400)
        try:
            from app.database import SessionLocal
            from app.models import Notification
            db = SessionLocal()
            cutoff = datetime.utcnow() - timedelta(days=retention_days)
            deleted = db.query(Notification).filter(
                Notification.created_at < cutoff,
                Notification.notification_type.in_(["sms", "email"])
            ).delete(synchronize_session=False)
            # For in-app, only delete read ones
            deleted += db.query(Notification).filter(
                Notification.created_at < cutoff,
                Notification.notification_type == "in_app",
                Notification.is_read == True,
            ).delete(synchronize_session=False)
            db.commit()
            db.close()
            if deleted:
                logger.info(f"Notification cleanup: removed {deleted} old records")
        except Exception as e:
            logger.error(f"Notification cleanup failed: {e}")
