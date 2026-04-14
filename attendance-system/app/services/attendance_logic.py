from datetime import datetime, timedelta, date
from sqlalchemy.orm import Session
from app.models import AttendanceRecord, Student
from app.config import settings
import redis

class AttendanceService:
    def __init__(self, db: Session):
        self.db = db
        self.redis_client = redis.from_url(settings.redis_url)
    
    def mark_attendance(
        self,
        student_id: str,
        camera_location: str,
        confidence: float,
        timestamp: datetime = None
    ):
        """Mark attendance with duplicate detection"""
        if timestamp is None:
            timestamp = datetime.now()
        
        # Get student
        student = self.db.query(Student).filter(Student.student_id == student_id).first()
        if not student:
            return None
        
        # Check for duplicate in Redis
        cache_key = f"attendance:recent:{student.id}:{camera_location}"
        if self.redis_client.exists(cache_key):
            return None  # Duplicate within time window
        
        # Create attendance record
        record = AttendanceRecord(
            student_id=student.id,
            camera_location=camera_location,
            timestamp=timestamp,
            confidence_score=confidence
        )
        
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        
        # Cache in Redis with TTL
        ttl = settings.duplicate_window_minutes * 60
        self.redis_client.setex(cache_key, ttl, str(record.id))
        
        return record
    
    def get_today_attendance(self):
        """Get today's attendance records"""
        today = date.today()
        records = self.db.query(AttendanceRecord).filter(
            AttendanceRecord.timestamp >= datetime.combine(today, datetime.min.time())
        ).order_by(AttendanceRecord.timestamp.desc()).all()
        return records
    
    def get_daily_stats(self, date_param: date):
        """Calculate daily attendance statistics"""
        total_students = self.db.query(Student).filter(Student.is_active == True).count()
        
        present_students = self.db.query(AttendanceRecord.student_id).filter(
            AttendanceRecord.timestamp >= datetime.combine(date_param, datetime.min.time()),
            AttendanceRecord.timestamp < datetime.combine(date_param, datetime.max.time())
        ).distinct().count()
        
        absent_students = total_students - present_students
        attendance_percentage = (present_students / total_students * 100) if total_students > 0 else 0
        
        return {
            "total_students": total_students,
            "present_students": present_students,
            "absent_students": absent_students,
            "attendance_percentage": round(attendance_percentage, 2),
            "date": datetime.combine(date_param, datetime.min.time())
        }
    
    def get_attendance_by_date_range(self, start_date: date, end_date: date):
        """Get attendance records within a date range with student information"""
        from sqlalchemy import and_
        
        start_datetime = datetime.combine(start_date, datetime.min.time())
        end_datetime = datetime.combine(end_date, datetime.max.time())
        
        records = self.db.query(
            AttendanceRecord, Student
        ).join(
            Student, AttendanceRecord.student_id == Student.id
        ).filter(
            and_(
                AttendanceRecord.timestamp >= start_datetime,
                AttendanceRecord.timestamp <= end_datetime
            )
        ).order_by(AttendanceRecord.timestamp.desc()).all()
        
        return [
            {
                "id": str(record.id),
                "student_id": student.student_id,
                "student_name": student.full_name,
                "camera_location": record.camera_location,
                "timestamp": record.timestamp.isoformat(),
                "confidence_score": float(record.confidence_score)
            }
            for record, student in records
        ]
