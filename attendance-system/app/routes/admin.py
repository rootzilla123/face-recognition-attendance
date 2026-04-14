from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Teacher, TeacherCamera, Camera, Student, StudentFee
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
    assigned = [tc.camera_id for tc in db.query(TeacherCamera).filter(TeacherCamera.teacher_id == teacher.id).all()]
    return {
        "id": str(teacher.id), "employee_id": teacher.employee_id,
        "full_name": teacher.full_name, "email": teacher.email,
        "department": teacher.department, "class_name": teacher.class_name,
        "phone": teacher.phone, "assigned_camera_ids": assigned,
    }


# --- Face enrollment status ---
@router.get("/students/enrollment-status")
def get_enrollment_status(
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """Admin: see which students have face photos enrolled in CompreFace"""
    from app.models import Student, FaceEmbedding
    students = db.query(Student).filter(Student.is_active == True).all()
    result = []
    for s in students:
        embedding = db.query(FaceEmbedding).filter(FaceEmbedding.student_id == s.id).first()
        result.append({
            "student_id": s.student_id,
            "full_name": s.full_name,
            "grade_level": s.grade_level,
            "section": s.section,
            "enrolled": embedding is not None,
            "enrolled_at": embedding.created_at.isoformat() if embedding else None,
        })
    enrolled = sum(1 for r in result if r["enrolled"])
    return {
        "total": len(result),
        "enrolled": enrolled,
        "not_enrolled": len(result) - enrolled,
        "students": result
    }


@router.get("/students/enrollment-status")
async def get_enrollment_status(
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """Admin: see which students have face photos enrolled in CompreFace"""
    import httpx
    from app.config import settings
    from app.models import Student, FaceEmbedding

    students = db.query(Student).filter(Student.is_active == True).all()
    enrolled_ids = {
        str(e.student_id)
        for e in db.query(FaceEmbedding).all()
    }

    return [
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
