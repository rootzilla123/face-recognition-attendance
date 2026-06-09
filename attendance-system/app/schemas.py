from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum
from uuid import UUID

class NotificationPreferences(BaseModel):
    sms: bool = True
    email: bool = True
    language: str = "en"

class StudentCreate(BaseModel):
    student_id: str = Field(..., min_length=1, max_length=50)
    full_name: str = Field(..., min_length=1, max_length=255)
    grade_level: str = Field(..., min_length=1, max_length=20)
    section: Optional[str] = None
    parent_name: Optional[str] = None
    parent_phone: str
    parent_email: EmailStr
    notification_preferences: NotificationPreferences = NotificationPreferences()

class StudentResponse(BaseModel):
    id: UUID
    student_id: str
    full_name: str
    grade_level: str
    section: Optional[str]
    parent_name: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None
    notification_preferences: Optional[dict] = None
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class AttendanceRecordCreate(BaseModel):
    student_id: str
    camera_location: str  # free-text — cameras use dynamic locations
    confidence_score: float = Field(..., ge=0.90, le=1.00)
    timestamp: Optional[datetime] = None

class ManualAttendanceCreate(BaseModel):
    student_id: str
    location: str = "Manual Entry"
    timestamp: Optional[datetime] = None

class AttendanceRecordResponse(BaseModel):
    id: UUID
    student_id: UUID
    camera_location: str
    timestamp: datetime
    confidence_score: float
    face_image_url: Optional[str]
    clip_path: Optional[str] = None

    class Config:
        from_attributes = True

class AttendanceStats(BaseModel):
    total_students: int
    present_students: int
    absent_students: int
    attendance_percentage: float
    date: datetime
