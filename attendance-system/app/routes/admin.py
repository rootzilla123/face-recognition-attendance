from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db, get_connection_stats
from app.models import User, Teacher, TeacherCamera, Camera, Student, StudentFee, GradingScheme, TeacherSubject
from app.dependencies import require_admin, get_current_user
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

@router.get("/users")
def list_users(db: Session = Depends(get_db), _=Depends(require_admin)):
    users = db.query(User).order_by(User.created_at.desc()).all()
    return [
        {"id": str(u.id), "email": u.email, "full_name": u.full_name,
         "role": u.role.value, "is_active": u.is_active,
         "created_at": u.created_at.isoformat() if u.created_at else None}
        for u in users
    ]

@router.post("/users/{user_id}/toggle")
def toggle_user(user_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    db.commit()
    return {"is_active": user.is_active}

# --- Teacher camera assignment ---

class AssignCameraRequest(BaseModel):
    camera_ids: List[int]

@router.get("/teachers")
def list_teachers(db: Session = Depends(get_db), _=Depends(require_admin)):
    teachers = db.query(Teacher).filter(Teacher.is_active == True).all()
    result = []
    for t in teachers:
        assigned = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == t.id).all()]
        result.append({
            "id": str(t.id), "employee_id": t.employee_id,
            "full_name": t.full_name, "email": t.email,
            "department": t.department, "class_name": t.class_name,
            "assigned_camera_ids": assigned,
        })
    return result

@router.put("/teachers/{teacher_id}/cameras")
def assign_cameras(
    teacher_id: str,
    data: AssignCameraRequest,
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """Replace a teacher's camera assignments"""
    teacher = db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    # Remove existing
    db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).delete()

    # Add new
    for cam_id in data.camera_ids:
        cam = db.query(Camera).filter(Camera.id == cam_id).first()
        if cam:
            db.add(TeacherCamera(teacher_id=teacher.id, camera_id=cam_id))

    db.commit()
    return {"message": "Cameras assigned", "camera_ids": data.camera_ids}

# --- Teacher self-profile ---
@router.get("/teacher/me")
def get_teacher_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from app.models import UserRole
    if current_user.role != UserRole.teacher:
        raise HTTPException(status_code=403, detail="Teachers only")
    teacher = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher profile not found")
    assigned_ids = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).all()]
    cameras = db.query(Camera).filter(Camera.id.in_(assigned_ids)).all() if assigned_ids else []
    return {
        "id": str(teacher.id), "employee_id": teacher.employee_id,
        "full_name": teacher.full_name, "email": teacher.email,
        "department": teacher.department, "class_name": teacher.class_name,
        "phone": teacher.phone,
        "assigned_camera_ids": assigned_ids,
        "cameras": [{"id": c.id, "name": c.name, "location": c.location, "status": c.status} for c in cameras],
    }


# --- Face enrollment status ---
@router.get("/students/enrollment-status")
async def get_enrollment_status(
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """Admin: see which students have face photos enrolled in CompreFace"""
    from app.models import Student, FaceEmbedding

    students = db.query(Student).filter(Student.is_active == True).all()
    enrolled_ids = {str(e.student_id) for e in db.query(FaceEmbedding).all()}
    enrolled = sum(1 for s in students if str(s.id) in enrolled_ids)

    return {
        "total": len(students),
        "enrolled": enrolled,
        "not_enrolled": len(students) - enrolled,
        "students": [
            {
                "id": str(s.id),
                "student_id": s.student_id,
                "full_name": s.full_name,
                "grade_level": s.grade_level,
                "section": s.section,
                "face_enrolled": str(s.id) in enrolled_ids,
            }
            for s in students
        ]
    }


# --- Student Fees ---

class FeeRequest(BaseModel):
    fee_type: str
    amount: float
    due_date: Optional[str] = None   # ISO date string
    term: Optional[str] = None
    notes: Optional[str] = None
    is_paid: bool = False


@router.get("/students/{student_id}/fees")
def get_student_fees(student_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    fees = db.query(StudentFee).filter(StudentFee.student_id == student.id).order_by(StudentFee.due_date).all()
    return [
        {
            "id": str(f.id), "fee_type": f.fee_type, "amount": float(f.amount),
            "due_date": f.due_date.isoformat() if f.due_date else None,
            "is_paid": f.is_paid, "paid_at": f.paid_at.isoformat() if f.paid_at else None,
            "term": f.term, "notes": f.notes,
        }
        for f in fees
    ]


@router.post("/students/{student_id}/fees")
def add_student_fee(student_id: str, data: FeeRequest, db: Session = Depends(get_db), _=Depends(require_admin)):
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    fee = StudentFee(
        student_id=student.id,
        fee_type=data.fee_type,
        amount=data.amount,
        due_date=datetime.fromisoformat(data.due_date) if data.due_date else None,
        term=data.term,
        notes=data.notes,
        is_paid=data.is_paid,
    )
    db.add(fee)
    db.commit()
    db.refresh(fee)
    return {"id": str(fee.id), "message": "Fee added"}


@router.patch("/fees/{fee_id}")
def update_fee(fee_id: str, data: FeeRequest, db: Session = Depends(get_db), _=Depends(require_admin)):
    fee = db.query(StudentFee).filter(StudentFee.id == fee_id).first()
    if not fee:
        raise HTTPException(status_code=404, detail="Fee not found")
    fee.fee_type = data.fee_type
    fee.amount = data.amount
    fee.due_date = datetime.fromisoformat(data.due_date) if data.due_date else None
    fee.term = data.term
    fee.notes = data.notes
    if data.is_paid and not fee.is_paid:
        fee.paid_at = datetime.utcnow()
    fee.is_paid = data.is_paid
    db.commit()
    return {"message": "Fee updated"}


@router.delete("/fees/{fee_id}")
def delete_fee(fee_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    fee = db.query(StudentFee).filter(StudentFee.id == fee_id).first()
    if not fee:
        raise HTTPException(status_code=404, detail="Fee not found")
    db.delete(fee)
    db.commit()
    return {"message": "Fee deleted"}


# ── System settings (recognition threshold, etc.) ─────────────────────────────
from app.config import settings as _settings
from pydantic import BaseModel as _BaseModel

class SystemSettingsUpdate(_BaseModel):
    recognition_threshold: float = None
    duplicate_window_minutes: int = None

@router.get("/system-settings")
def get_system_settings(_=Depends(require_admin)):
    return {
        "recognition_threshold": _settings.recognition_threshold,
        "duplicate_window_minutes": _settings.duplicate_window_minutes,
    }

@router.put("/system-settings")
def update_system_settings(data: SystemSettingsUpdate, _=Depends(require_admin)):
    """Update runtime recognition settings without restart."""
    if data.recognition_threshold is not None:
        if not 0.5 <= data.recognition_threshold <= 1.0:
            raise HTTPException(status_code=400, detail="Threshold must be between 0.5 and 1.0")
        _settings.recognition_threshold = data.recognition_threshold
    if data.duplicate_window_minutes is not None:
        _settings.duplicate_window_minutes = data.duplicate_window_minutes
    return {
        "recognition_threshold": _settings.recognition_threshold,
        "duplicate_window_minutes": _settings.duplicate_window_minutes,
    }

@router.get("/db-connections")
def get_db_connections(_=Depends(require_admin)):
    """Get current database connection statistics for monitoring."""
    return get_connection_stats()


# ── Audit logs ────────────────────────────────────────────────────────────────
from app.models import AuditLog
from fastapi import Request

def write_audit(db, actor, action: str, target_type: str = None, target_id: str = None, detail: dict = None, ip: str = None):
    """Helper to write an audit log entry."""
    try:
        log = AuditLog(
            actor_id=actor.id if actor else None,
            actor_email=actor.email if actor else None,
            action=action,
            target_type=target_type,
            target_id=str(target_id) if target_id else None,
            detail=detail or {},
            ip_address=ip,
        )
        db.add(log)
        db.commit()
    except Exception:
        pass  # Never let audit logging break the main flow

@router.get("/audit-logs")
def get_audit_logs(
    limit: int = 100,
    action: str = None,
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    # Temporary: return empty until audit_logs table is created
    try:
        q = db.query(AuditLog).order_by(AuditLog.created_at.desc())
        if action:
            q = q.filter(AuditLog.action == action)
        logs = q.limit(limit).all()
    except:
        return []
    return [
        {
            "id": str(l.id),
            "actor": l.actor_email,
            "action": l.action,
            "target_type": l.target_type,
            "target_id": l.target_id,
            "detail": l.detail,
            "ip": l.ip_address,
            "timestamp": l.created_at.isoformat() if l.created_at else None,
        }
        for l in logs
    ]

# ── Grading Scheme & Teacher Subjects ────────────────────────────────────────

class GradingSchemeRequest(BaseModel):
    name: str
    min_score_percent: float
    grade: str
    is_active: bool = True

@router.get("/grading-schemes")
def list_grading_schemes(db: Session = Depends(get_db), _=Depends(require_admin)):
    return db.query(GradingScheme).all()

@router.post("/grading-schemes")
def create_grading_scheme(data: GradingSchemeRequest, db: Session = Depends(get_db), _=Depends(require_admin)):
    scheme = GradingScheme(**data.dict())
    db.add(scheme)
    db.commit()
    db.refresh(scheme)
    return scheme

@router.delete("/grading-schemes/{scheme_id}")
def delete_grading_scheme(scheme_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    db.query(GradingScheme).filter(GradingScheme.id == scheme_id).delete()
    db.commit()
    return {"message": "Scheme deleted"}

class TeacherSubjectRequest(BaseModel):
    subject: str
    class_name: str

@router.get("/teachers/{teacher_id}/subjects")
def list_teacher_subjects(teacher_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    return db.query(TeacherSubject).filter(TeacherSubject.teacher_id == teacher_id).all()

@router.post("/teachers/{teacher_id}/subjects")
def assign_teacher_subject(teacher_id: str, data: TeacherSubjectRequest, db: Session = Depends(get_db), _=Depends(require_admin)):
    assignment = TeacherSubject(teacher_id=teacher_id, **data.dict())
    db.add(assignment)
    db.commit()
    db.refresh(assignment)
    return assignment

@router.delete("/teacher-subjects/{assignment_id}")
def unassign_teacher_subject(assignment_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    db.query(TeacherSubject).filter(TeacherSubject.id == assignment_id).delete()
    db.commit()
    return {"message": "Subject unassigned"}
