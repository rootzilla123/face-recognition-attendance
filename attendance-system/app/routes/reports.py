from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import AttendanceRecord, Student
from app.dependencies import require_teacher_or_admin
from datetime import date, datetime
from typing import Optional

router = APIRouter()


@router.get("/daily-summary")
def daily_summary(
    report_date: date = Query(default=None),
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Daily attendance summary with per-student breakdown"""
    target = report_date or date.today()
    start = datetime.combine(target, datetime.min.time())
    end = datetime.combine(target, datetime.max.time())

    total_students = db.query(Student).filter(Student.is_active == True).count()

    records = db.query(AttendanceRecord, Student).join(
        Student, AttendanceRecord.student_id == Student.id
    ).filter(
        AttendanceRecord.timestamp >= start,
        AttendanceRecord.timestamp <= end
    ).all()

    present_ids = set()
    detail = []
    for record, student in records:
        if student.id not in present_ids:
            present_ids.add(student.id)
            detail.append({
                "student_id": student.student_id,
                "full_name": student.full_name,
                "grade_level": student.grade_level,
                "section": student.section,
                "first_seen": record.timestamp.isoformat(),
                "camera_location": record.camera_location,
            })

    return {
        "date": target.isoformat(),
        "total_students": total_students,
        "present": len(present_ids),
        "absent": total_students - len(present_ids),
        "attendance_rate": round(len(present_ids) / total_students * 100, 2) if total_students else 0,
        "records": detail,
    }


@router.get("/student/{student_id}")
def student_report(
    student_id: str,
    start_date: date = Query(...),
    end_date: date = Query(...),
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Full attendance history for a specific student"""
    from fastapi import HTTPException
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    start = datetime.combine(start_date, datetime.min.time())
    end = datetime.combine(end_date, datetime.max.time())

    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.student_id == student.id,
        AttendanceRecord.timestamp >= start,
        AttendanceRecord.timestamp <= end
    ).order_by(AttendanceRecord.timestamp.desc()).all()

    # Count unique days present
    days_present = len(set(r.timestamp.date() for r in records))

    return {
        "student": {
            "student_id": student.student_id,
            "full_name": student.full_name,
            "grade_level": student.grade_level,
            "section": student.section,
        },
        "period": {"start": start_date.isoformat(), "end": end_date.isoformat()},
        "days_present": days_present,
        "total_records": len(records),
        "records": [
            {
                "date": r.timestamp.date().isoformat(),
                "time": r.timestamp.strftime("%H:%M:%S"),
                "camera_location": r.camera_location,
                "confidence_score": float(r.confidence_score),
            }
            for r in records
        ]
    }


@router.get("/grade-summary")
def grade_summary(
    report_date: date = Query(default=None),
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Attendance breakdown by grade level"""
    target = report_date or date.today()
    start = datetime.combine(target, datetime.min.time())
    end = datetime.combine(target, datetime.max.time())

    all_students = db.query(Student).filter(Student.is_active == True).all()
    present_ids = {
        r for r, in db.query(AttendanceRecord.student_id).filter(
            AttendanceRecord.timestamp >= start,
            AttendanceRecord.timestamp <= end
        ).distinct()
    }

    grade_map = {}
    for s in all_students:
        g = s.grade_level
        if g not in grade_map:
            grade_map[g] = {"grade": g, "total": 0, "present": 0}
        grade_map[g]["total"] += 1
        if s.id in present_ids:
            grade_map[g]["present"] += 1

    for g in grade_map:
        t = grade_map[g]["total"]
        p = grade_map[g]["present"]
        grade_map[g]["absent"] = t - p
        grade_map[g]["rate"] = round(p / t * 100, 2) if t else 0

    return {"date": target.isoformat(), "grades": list(grade_map.values())}
