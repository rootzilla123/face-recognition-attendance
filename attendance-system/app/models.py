from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey, Text, DECIMAL, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.database import Base
import uuid
import enum

class UserRole(str, enum.Enum):
    admin = "admin"
    teacher = "teacher"
    student = "student"
    parent = "parent"

class User(Base):
    """Central auth table for all roles"""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(SAEnum(UserRole), nullable=False)
    full_name = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    last_login = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    # Optional link to role-specific profile
    profile_id = Column(UUID(as_uuid=True), nullable=True)  # links to Student/Teacher/Parent/Administrator id
    # Device tokens for push notifications (FCM/APNs)
    device_tokens = Column(JSONB, default=[])

class Student(Base):
    __tablename__ = "students"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(String(50), unique=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    grade_level = Column(String(20), nullable=False)
    section = Column(String(50))
    parent_name = Column(String(255))
    parent_phone = Column(String(20))
    parent_email = Column(String(255))
    notification_preferences = Column(JSONB, default={"sms": True, "email": True, "language": "en"})
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    camera_location = Column(String(50), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    confidence_score = Column(DECIMAL(5, 4), nullable=False)
    face_image_url = Column(String(500))
    clip_path = Column(String(500))  # Path to 10-second video clip
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class FaceEmbedding(Base):
    __tablename__ = "face_embeddings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    comprefore_subject_id = Column(String(255), nullable=False)
    comprefore_embedding_id = Column(String(255), unique=True, nullable=False)
    image_url = Column(String(500))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Administrator(Base):
    __tablename__ = "administrators"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False)
    phone = Column(String(20))
    role = Column(String(20), default="viewer")
    notification_preferences = Column(JSONB, default={"sms": True, "email": True, "in_app": True, "language": "en"})
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Teacher(Base):
    __tablename__ = "teachers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_id = Column(String(50), unique=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    phone = Column(String(20))
    department = Column(String(100))
    class_name = Column(String(100))   # e.g. "Grade 10 - Section A"
    notification_preferences = Column(JSONB, default={"sms": True, "email": True, "in_app": True, "language": "en"})
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class TeacherCamera(Base):
    """Links a teacher to the cameras they are allowed to view"""
    __tablename__ = "teacher_cameras"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    teacher_id = Column(UUID(as_uuid=True), ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    camera_id = Column(Integer, ForeignKey("cameras.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Parent(Base):
    __tablename__ = "parents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    phone = Column(String(20))
    fcm_token = Column(String(500))  # Firebase Cloud Messaging token for push notifications
    # A parent can have multiple children - stored as array of student UUIDs
    notification_preferences = Column(JSONB, default={"sms": True, "email": True, "in_app": True, "push": True, "language": "en"})
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class ParentStudent(Base):
    """Links parents to their children"""
    __tablename__ = "parent_students"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("parents.id"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    # target_roles: who can see this - stored as list e.g. ["student","parent","teacher"]
    target_roles = Column(JSONB, default=["student", "parent", "teacher", "admin"])
    is_published = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    attendance_record_id = Column(UUID(as_uuid=True), ForeignKey("attendance_records.id"), nullable=True)
    announcement_id = Column(UUID(as_uuid=True), ForeignKey("announcements.id"), nullable=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=True)
    recipient_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    notification_type = Column(String(20), nullable=False)  # sms, email, in_app
    recipient = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    title = Column(String(255))
    status = Column(String(20), default="pending")  # pending, sent, failed, read
    is_read = Column(Boolean, default=False)
    sent_at = Column(DateTime(timezone=True))
    failed_reason = Column(Text)
    retry_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class StudentFee(Base):
    __tablename__ = "student_fees"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    fee_type = Column(String(100), nullable=False)   # e.g. "Tuition", "Transport", "Lunch"
    amount = Column(DECIMAL(10, 2), nullable=False)
    due_date = Column(DateTime(timezone=True), nullable=True)
    is_paid = Column(Boolean, default=False)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    term = Column(String(50), nullable=True)         # e.g. "Term 1 2026"
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class Camera(Base):
    __tablename__ = "cameras"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    location = Column(String(100), nullable=False)
    stream_url = Column(String(500), nullable=False)
    protocol = Column(String(20), nullable=False)  # rtsp, http, local
    username = Column(String(100))  # Optional authentication
    password = Column(String(100))  # Optional authentication
    status = Column(String(20), default="offline")  # online, offline, error
    is_active = Column(Boolean, default=True)
    frame_rate = Column(Integer, default=5)
    last_seen = Column(DateTime(timezone=True))
    error_message = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    actor_email = Column(String(255))
    action = Column(String(100), nullable=False)   # e.g. "manual_attendance", "enroll_face", "delete_student"
    target_type = Column(String(50))               # "student", "camera", "attendance"
    target_id = Column(String(255))
    detail = Column(JSONB, default={})
    ip_address = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class StudentMark(Base) :
    __tablename__ = "student_marks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    teacher_id = Column(UUID(as_uuid=True), ForeignKey("teachers.id"), nullable=False)
    subject = Column(String(100), nullable=False)
    term = Column(String(50), nullable=False)          # e.g. "Term 1 2026"
    score = Column(DECIMAL(5, 2), nullable=False)
    max_score = Column(DECIMAL(5, 2), nullable=False, default=100)
    grade = Column(String(5))                          # e.g. "A", "B+"
    remarks = Column(Text)
    is_published = Column(Boolean, default=False)      # teacher pushes to students/parents
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class GradingScheme(Base):
    __tablename__ = "grading_schemes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)         # e.g. "Default Scheme"
    min_score_percent = Column(DECIMAL(5, 2), nullable=False)
    grade = Column(String(5), nullable=False)          # e.g. "A+"
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class TeacherSubject(Base):
    """Restricts teachers to specific subjects and classes"""
    __tablename__ = "teacher_subjects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    teacher_id = Column(UUID(as_uuid=True), ForeignKey("teachers.id"), nullable=False)
    subject = Column(String(100), nullable=False)      # e.g. "Mathematics"
    class_name = Column(String(100), nullable=False)   # e.g. "Grade 10 - A"
    created_at = Column(DateTime(timezone=True), server_default=func.now())
