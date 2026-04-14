from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID
from datetime import datetime

from app.database import get_db
from app.models import Parent, ParentStudent, Student, AttendanceRecord, User, UserRole, StudentFee
from app.dependencies import get_current_user, require_admin

router = APIRouter()


class ChildAttendanceResponse(BaseModel):
    student_id: str
    full_name: str
    grade_level: str
    section: Optional[str]
    attendance: List[dict]


class LinkChildRequest(BaseModel):
    student_id: str  # the student's student_id string e.g. "STU001"


@router.get("/children", response_model=List[dict])
def get_my_children(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent: get list of linked children"""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")

    links = db.query(ParentStudent).filter(
        ParentStudent.parent_id == current_user.profile_id
    ).all()

    children = []
    for link in links:
        student = db.query(Student).filter(Student.id == link.student_id).first()
        if student:
            children.append({
                "id": str(student.id),
                "student_id": student.student_id,
                "full_name": student.full_name,
                "grade_level": student.grade_level,
                "section": student.section,
            })
    return children


@router.post("/children/link")
def link_child(
    data: LinkChildRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent: link a child using student ID + verification via parent_email match"""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")

    student = db.query(Student).filter(Student.student_id == data.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Verify parent email matches what's on the student record
    if student.parent_email and student.parent_email.lower() != current_user.email.lower():
        raise HTTPException(
            status_code=403,
            detail="Your email does not match the parent email on this student's record. Contact the school admin."
        )

    existing = db.query(ParentStudent).filter(
        ParentStudent.parent_id == current_user.profile_id,
        ParentStudent.student_id == student.id
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Child already linked")

    link = ParentStudent(parent_id=current_user.profile_id, student_id=student.id)
    db.add(link)
    db.commit()
    return {"message": f"{student.full_name} linked successfully"}


@router.delete("/children/{student_id}/unlink")
def unlink_child(
    student_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent: unlink a child"""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")

    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    link = db.query(ParentStudent).filter(
        ParentStudent.parent_id == current_user.profile_id,
        ParentStudent.student_id == student.id
    ).first()
    if not link:
        raise HTTPException(status_code=404, detail="Child not linked to your account")

    db.delete(link)
    db.commit()
    return {"message": "Child unlinked"}


@router.get("/children/{student_id}/attendance")
def get_child_attendance(
    student_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent: view a linked child's attendance records"""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")

    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Verify this parent is linked to this student
    link = db.query(ParentStudent).filter(
        ParentStudent.parent_id == current_user.profile_id,
        ParentStudent.student_id == student.id
    ).first()
    if not link:
        raise HTTPException(status_code=403, detail="You are not linked to this student")

    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.student_id == student.id
    ).order_by(AttendanceRecord.timestamp.desc()).limit(100).all()

    return {
        "student": {
            "student_id": student.student_id,
            "full_name": student.full_name,
            "grade_level": student.grade_level,
            "section": student.section,
        },
        "attendance": [
            {
                "id": str(r.id),
                "camera_location": r.camera_location,
                "timestamp": r.timestamp.isoformat(),
                "confidence_score": float(r.confidence_score),
            }
            for r in records
        ]
    }


@router.get("/children/{student_id}/fees")
def get_child_fees(
    student_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent: view a linked child's fee balances"""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this endpoint")

    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    link = db.query(ParentStudent).filter(
        ParentStudent.parent_id == current_user.profile_id,
        ParentStudent.student_id == student.id
    ).first()
    if not link:
        raise HTTPException(status_code=403, detail="You are not linked to this student")

    fees = db.query(StudentFee).filter(StudentFee.student_id == student.id).order_by(StudentFee.due_date).all()

    return {
        "student_id": student.student_id,
        "full_name": student.full_name,
        "fees": [
            {
                "id": str(f.id),
                "fee_type": f.fee_type,
                "amount": float(f.amount),
                "due_date": f.due_date.isoformat() if f.due_date else None,
                "is_paid": f.is_paid,
                "paid_at": f.paid_at.isoformat() if f.paid_at else None,
                "term": f.term,
                "notes": f.notes,
            }
            for f in fees
        ],
        "total_owed": float(sum(f.amount for f in fees if not f.is_paid)),
        "total_paid": float(sum(f.amount for f in fees if f.is_paid)),
    }
