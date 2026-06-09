from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import AttendanceRecordCreate, AttendanceRecordResponse, AttendanceStats, ManualAttendanceCreate
from app.routes.admin import write_audit
from app.services.attendance_logic import AttendanceService
from app.services.notification_service import notify_parents_of_attendance, NotificationService
from app.models import Student, Teacher, TeacherCamera, Camera, UserRole
from app.dependencies import get_current_user, require_teacher_or_admin
from typing import List
from datetime import date

router = APIRouter()

@router.post("/manual", response_model=AttendanceRecordResponse)
def mark_manual_attendance(
    data: ManualAttendanceCreate,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Manually mark a student present (teacher/admin only) — bypasses confidence requirement"""
    student = db.query(Student).filter(Student.student_id == data.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    service = AttendanceService(db)
    record = service.mark_attendance(
        student_id=data.student_id,
        camera_location=data.location,
        confidence=1.0,
        timestamp=data.timestamp,
    )
    if not record:
        raise HTTPException(status_code=400, detail="Attendance already recorded for this student recently")
    student_obj = db.query(Student).filter(Student.id == record.student_id).first()
    if student_obj:
        try:
            notify_parents_of_attendance(db, student_obj, record, NotificationService())
        except Exception:
            pass
    write_audit(db, _, action="manual_attendance", target_type="student",
                target_id=data.student_id, detail={"location": data.location})
    return record


@router.post("/", response_model=AttendanceRecordResponse)
def mark_attendance(
    attendance: AttendanceRecordCreate,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Mark attendance for a student (teacher/admin only)"""
    service = AttendanceService(db)
    record = service.mark_attendance(
        student_id=attendance.student_id,
        camera_location=attendance.camera_location,
        confidence=attendance.confidence_score,
        timestamp=attendance.timestamp
    )

    if not record:
        raise HTTPException(status_code=400, detail="Duplicate attendance within time window")

    # Notify parents
    student = db.query(Student).filter(Student.id == record.student_id).first()
    if student:
        try:
            notify_parents_of_attendance(db, student, record, NotificationService())
        except Exception:
            pass  # Don't fail attendance marking if notification fails

    return record

@router.get("/", response_model=dict)
def get_attendance_by_date_range(
    start_date: date = Query(...),
    end_date: date = Query(...),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user=Depends(require_teacher_or_admin)
):
    if start_date > end_date:
        raise HTTPException(status_code=400, detail="Start date must be before end date")
    service = AttendanceService(db)
    records = service.get_attendance_by_date_range(start_date, end_date)

    # Filter by teacher cameras
    if current_user.role == UserRole.teacher:
        teacher = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
        if teacher:
            assigned_ids = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).all()]
            assigned_cameras = db.query(Camera).filter(Camera.id.in_(assigned_ids)).all()
            assigned_locations = {c.location for c in assigned_cameras}
            records = [r for r in records if r.get("camera_location") in assigned_locations]

    total = len(records)
    start = (page - 1) * page_size
    return {
        "total": total, "page": page, "page_size": page_size,
        "pages": (total + page_size - 1) // page_size,
        "records": records[start:start + page_size]
    }

@router.get("/today", response_model=List[AttendanceRecordResponse])
def get_today_attendance(
    db: Session = Depends(get_db),
    current_user=Depends(require_teacher_or_admin)
):
    """Get today's attendance - teachers only see records from their assigned cameras"""
    service = AttendanceService(db)
    records = service.get_today_attendance()

    from app.models import UserRole, Teacher, TeacherCamera
    if current_user.role == UserRole.teacher:
        teacher = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
        if teacher:
            assigned_ids = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).all()]
            assigned_cameras = db.query(Camera).filter(Camera.id.in_(assigned_ids)).all()
            assigned_locations = {c.location for c in assigned_cameras}
            records = [r for r in records if r.camera_location in assigned_locations]

    return records

@router.get("/stats", response_model=AttendanceStats)
def get_attendance_stats(
    date_param: date = None,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Get attendance statistics (teacher/admin only)"""
    service = AttendanceService(db)
    return service.get_daily_stats(date_param or date.today())

@router.get("/my", response_model=List[AttendanceRecordResponse])
def get_my_attendance(
    start_date: date = None,
    end_date: date = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Student: view own attendance records with optional date filtering"""
    if current_user.role != UserRole.student:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")
    student = db.query(Student).filter(Student.id == current_user.profile_id).first()
    if not student:
        # Try finding by email
        from app.models import User
        student = db.query(Student).filter(Student.parent_email == current_user.email).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    from app.models import AttendanceRecord
    from datetime import datetime
    query = db.query(AttendanceRecord).filter(AttendanceRecord.student_id == student.id)

    if start_date:
        query = query.filter(AttendanceRecord.timestamp >= datetime.combine(start_date, datetime.min.time()))
    if end_date:
        query = query.filter(AttendanceRecord.timestamp <= datetime.combine(end_date, datetime.max.time()))

    records = query.order_by(AttendanceRecord.timestamp.desc()).limit(200).all()
    return records


@router.get("/{attendance_id}/clip")
async def get_attendance_clip(
    attendance_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Stream the 10-second video clip for an attendance record."""
    from app.models import AttendanceRecord
    from fastapi.responses import FileResponse
    from pathlib import Path
    
    record = db.query(AttendanceRecord).filter(AttendanceRecord.id == attendance_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    if not record.clip_path:
        raise HTTPException(status_code=404, detail="No video clip available for this record")
    
    clip_file = Path(record.clip_path)
    if not clip_file.exists():
        raise HTTPException(status_code=404, detail="Video clip file not found")
    
    return FileResponse(
        path=str(clip_file),
        media_type="video/mp4",
        filename=f"attendance_{attendance_id}.mp4"
    )
