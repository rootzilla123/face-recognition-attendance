from fastapi import APIRouter, Depends, HTTPException, UploadFile, File as FastAPIFile
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import StudentMark, Student, Teacher, User, UserRole, GradingScheme, TeacherSubject, Parent, ParentStudent
from app.dependencies import get_current_user, require_teacher_or_admin
from app.services.notification_service import NotificationService
from pydantic import BaseModel
from typing import List, Optional, Dict
from decimal import Decimal
from datetime import datetime
import csv
import io

router = APIRouter()

# ── Utilities ────────────────────────────────────────────────────────────────

def get_grade(percentage: float, db: Session) -> Optional[str]:
    """Calculate grade based on percentage using active grading scheme."""
    scheme = db.query(GradingScheme).filter(
        GradingScheme.is_active == True,
        GradingScheme.min_score_percent <= percentage
    ).order_by(GradingScheme.min_score_percent.desc()).first()
    return scheme.grade if scheme else None

def check_teacher_restriction(teacher_id: str, subject: str, student_id: str, db: Session):
    """Verify teacher is allowed to record marks for this subject and student."""
    # Get student's class
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        return False
    
    # Check if teacher is linked to this subject and class
    link = db.query(TeacherSubject).filter(
        TeacherSubject.teacher_id == teacher_id,
        TeacherSubject.subject == subject,
        TeacherSubject.class_name == student.grade_level  # Assuming grade_level is used for class_name
    ).first()
    
    return link is not None

# ── Schemas ───────────────────────────────────────────────────────────────────

class MarkCreate(BaseModel):
    student_id: str
    subject: str
    term: str
    score: float
    max_score: float = 100.0
    remarks: Optional[str] = None

class MarkUpdate(BaseModel):
    score: Optional[float] = None
    max_score: Optional[float] = None
    remarks: Optional[str] = None
    is_published: Optional[bool] = None

class MarkResponse(BaseModel):
    id: str
    student_id: str
    student_name: str
    subject: str
    term: str
    score: float
    max_score: float
    percentage: float
    grade: Optional[str]
    remarks: Optional[str]
    is_published: bool
    created_at: str

class ConsolidatedReport(BaseModel):
    student_id: str
    student_name: str
    term: str
    marks: List[MarkResponse]
    total_score: float
    total_max: float
    overall_percentage: float
    overall_grade: Optional[str]

# ── Teacher Endpoints ─────────────────────────────────────────────────────────

@router.post("/marks", response_model=MarkResponse)
def create_mark(
    data: MarkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Teacher creates a mark entry for a student."""
    student = db.query(Student).filter(Student.student_id == data.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    if current_user.role == UserRole.teacher:
        teacher = db.query(Teacher).filter(Teacher.id == current_user.profile_id).first()
        if not teacher:
            raise HTTPException(status_code=404, detail="Teacher profile not found")
        
        # Check restriction (Skip for admins)
        if not check_teacher_restriction(teacher.id, data.subject, student.id, db):
             # For now, let's just log or allow if no links exist (legacy support)
             links_count = db.query(TeacherSubject).filter(TeacherSubject.teacher_id == teacher.id).count()
             if links_count > 0:
                 raise HTTPException(status_code=403, detail=f"You are not assigned to {data.subject} for this class")
        
        teacher_id = teacher.id
    else:
        teacher = db.query(Teacher).first()
        teacher_id = teacher.id if teacher else None

    percentage = (data.score / data.max_score) * 100
    grade = get_grade(percentage, db)
    
    mark = StudentMark(
        student_id=student.id,
        teacher_id=teacher_id,
        subject=data.subject,
        term=data.term,
        score=Decimal(str(data.score)),
        max_score=Decimal(str(data.max_score)),
        grade=grade,
        remarks=data.remarks,
        is_published=False
    )
    
    db.add(mark)
    db.commit()
    db.refresh(mark)
    
    return MarkResponse(
        id=str(mark.id),
        student_id=student.student_id,
        student_name=student.full_name,
        subject=mark.subject,
        term=mark.term,
        score=float(mark.score),
        max_score=float(mark.max_score),
        percentage=round(percentage, 2),
        grade=mark.grade,
        remarks=mark.remarks,
        is_published=mark.is_published,
        created_at=mark.created_at.isoformat() if mark.created_at else None
    )

@router.post("/marks/bulk")
async def bulk_upload_marks(
    file: UploadFile = FastAPIFile(...),
    term: str = "Term 1 2026",
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Bulk upload marks via CSV."""
    content = await file.read()
    df = csv.DictReader(io.StringIO(content.decode('utf-8')))
    
    teacher_id = current_user.profile_id if current_user.role == UserRole.teacher else None
    results = {"success": 0, "failed": 0, "errors": []}

    for row in df:
        try:
            student_id = row.get('student_id')
            subject = row.get('subject')
            score = float(row.get('score', 0))
            max_score = float(row.get('max_score', 100))
            
            student = db.query(Student).filter(Student.student_id == student_id).first()
            if not student:
                results["failed"] += 1
                results["errors"].append(f"Student {student_id} not found")
                continue
            
            percentage = (score / max_score) * 100
            grade = get_grade(percentage, db)

            mark = StudentMark(
                student_id=student.id,
                teacher_id=teacher_id or db.query(Teacher).first().id,
                subject=subject,
                term=term,
                score=Decimal(str(score)),
                max_score=Decimal(str(max_score)),
                grade=grade,
                remarks=row.get('remarks'),
                is_published=False
            )
            db.add(mark)
            results["success"] += 1
        except Exception as e:
            results["failed"] += 1
            results["errors"].append(str(e))
    
    db.commit()
    return results

@router.post("/marks/{mark_id}/publish")
def publish_mark(
    mark_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Publish mark and notify parents/students."""
    from app.services.notification_service import _save
    
    mark = db.query(StudentMark).filter(StudentMark.id == mark_id).first()
    if not mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    mark.is_published = True
    db.commit()

    # Trigger Notifications
    student = db.query(Student).filter(Student.id == mark.student_id).first()
    if student:
        notif_msg = f"Examination results for {mark.subject} ({mark.term}) are now available. Score: {mark.score}/{mark.max_score}."
        subject_line = "Results Published"
        
        # Notify Student (In-App)
        student_user = db.query(User).filter(User.profile_id == student.id, User.role == UserRole.student).first()
        if student_user:
            _save(db, "in_app", student.parent_email or student_user.email, subject_line, notif_msg,
                  None, student.id, student_user.id, "sent")

        # Notify Parent
        parent_links = db.query(ParentStudent).filter(ParentStudent.student_id == student.id).all()
        svc = NotificationService()
        for link in parent_links:
            parent = db.query(Parent).filter(Parent.id == link.parent_id).first()
            if parent:
                parent_user = db.query(User).filter(User.email == parent.email).first()
                if parent_user:
                    _save(db, "in_app", parent.email, f"Results: {student.full_name}", notif_msg,
                          None, student.id, parent_user.id, "sent")
                
                # Send SMS if enabled
                prefs = parent.notification_preferences or {}
                if prefs.get("sms", True) and parent.phone:
                    result = svc.send_sms(parent.phone, f"School Alert: {notif_msg}")
                    _save(db, "sms", parent.phone, subject_line, notif_msg,
                          None, student.id, parent_user.id if parent_user else None, result["status"])
        
        db.commit()

    return {"message": "Mark published and notifications queued"}

@router.get("/marks/analytics/subject", response_model=Dict)
def get_subject_analytics(
    subject: str,
    term: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Get performance analytics for a specific subject."""
    stats = db.query(
        func.count(StudentMark.id).label("count"),
        func.avg(StudentMark.score / StudentMark.max_score * 100).label("avg_percent"),
        func.max(StudentMark.score / StudentMark.max_score * 100).label("max_percent"),
        func.min(StudentMark.score / StudentMark.max_score * 100).label("min_percent")
    ).filter(
        StudentMark.subject == subject,
        StudentMark.term == term,
        StudentMark.is_published == True
    ).first()

    return {
        "subject": subject,
        "term": term,
        "student_count": stats.count,
        "average_percentage": round(float(stats.avg_percent or 0), 2),
        "highest_percentage": round(float(stats.max_percent or 0), 2),
        "lowest_percentage": round(float(stats.min_percent or 0), 2)
    }

@router.get("/marks/consolidated/{student_id}", response_model=ConsolidatedReport)
def get_consolidated_report(
    student_id: str,
    term: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate a consolidated term report for a student."""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    marks = db.query(StudentMark).filter(
        StudentMark.student_id == student.id,
        StudentMark.term == term,
        StudentMark.is_published == True
    ).all()

    if not marks:
        raise HTTPException(status_code=404, detail="No published marks for this term")

    total_score = sum(float(m.score) for m in marks)
    total_max = sum(float(m.max_score) for m in marks)
    overall_percentage = (total_score / total_max) * 100 if total_max > 0 else 0
    
    return ConsolidatedReport(
        student_id=student.student_id,
        student_name=student.full_name,
        term=term,
        marks=[
            MarkResponse(
                id=str(m.id),
                student_id=student.student_id,
                student_name=student.full_name,
                subject=m.subject,
                term=m.term,
                score=float(m.score),
                max_score=float(m.max_score),
                percentage=round((float(m.score) / float(m.max_score)) * 100, 2),
                grade=m.grade,
                remarks=m.remarks,
                is_published=m.is_published,
                created_at=m.created_at.isoformat()
            ) for m in marks
        ],
        total_score=total_score,
        total_max=total_max,
        overall_percentage=round(overall_percentage, 2),
        overall_grade=get_grade(overall_percentage, db)
    )

# ── Standard CRUD (Updated) ──────────────────────────────────────────────────

@router.get("/marks", response_model=List[MarkResponse])
def list_marks(
    student_id: Optional[str] = None,
    term: Optional[str] = None,
    subject: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Teacher lists all marks (with teacher restrictions)."""
    query = db.query(StudentMark).join(Student)
    
    if current_user.role == UserRole.teacher:
        # Restriction: Only show marks this teacher recorded or for subjects they teach
        query = query.filter(StudentMark.teacher_id == current_user.profile_id)
    
    if student_id:
        student = db.query(Student).filter(Student.student_id == student_id).first()
        if student:
            query = query.filter(StudentMark.student_id == student.id)
    
    if term:
        query = query.filter(StudentMark.term == term)
    
    if subject:
        query = query.filter(StudentMark.subject == subject)
    
    marks = query.order_by(StudentMark.created_at.desc()).all()
    
    return [
        MarkResponse(
            id=str(m.id),
            student_id=db.query(Student).filter(Student.id == m.student_id).first().student_id,
            student_name=db.query(Student).filter(Student.id == m.student_id).first().full_name,
            subject=m.subject,
            term=m.term,
            score=float(m.score),
            max_score=float(m.max_score),
            percentage=round((float(m.score) / float(m.max_score)) * 100, 2),
            grade=m.grade,
            remarks=m.remarks,
            is_published=m.is_published,
            created_at=m.created_at.isoformat() if m.created_at else None
        )
        for m in marks
    ]

@router.put("/marks/{mark_id}", response_model=MarkResponse)
def update_mark(
    mark_id: str,
    data: MarkUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Teacher updates a mark entry with automatic re-grading."""
    mark = db.query(StudentMark).filter(StudentMark.id == mark_id).first()
    if not mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    if current_user.role == UserRole.teacher and mark.teacher_id != current_user.profile_id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this mark")

    if data.score is not None:
        mark.score = Decimal(str(data.score))
    if data.max_score is not None:
        mark.max_score = Decimal(str(data.max_score))
    if data.remarks is not None:
        mark.remarks = data.remarks
    if data.is_published is not None:
        mark.is_published = data.is_published
    
    # Re-calculate grade
    mark.grade = get_grade((float(mark.score) / float(mark.max_score)) * 100, db)
    
    db.commit()
    db.refresh(mark)
    
    student = db.query(Student).filter(Student.id == mark.student_id).first()
    
    return MarkResponse(
        id=str(mark.id),
        student_id=student.student_id,
        student_name=student.full_name,
        subject=mark.subject,
        term=mark.term,
        score=float(mark.score),
        max_score=float(mark.max_score),
        percentage=round((float(mark.score) / float(mark.max_score)) * 100, 2),
        grade=mark.grade,
        remarks=mark.remarks,
        is_published=mark.is_published,
        created_at=mark.created_at.isoformat() if mark.created_at else None
    )

@router.delete("/marks/{mark_id}")
def delete_mark(
    mark_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    """Teacher deletes a mark entry."""
    mark = db.query(StudentMark).filter(StudentMark.id == mark_id).first()
    if not mark:
        raise HTTPException(status_code=404, detail="Mark not found")
    
    if current_user.role == UserRole.teacher and mark.teacher_id != current_user.profile_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this mark")
    
    db.delete(mark)
    db.commit()
    return {"message": "Mark deleted"}

# ── Student/Parent Endpoints (Already exist, but inherited benefits) ──────────

@router.get("/my-marks", response_model=List[MarkResponse])
def get_my_marks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Student views their own published marks."""
    if current_user.role != UserRole.student:
        raise HTTPException(status_code=403, detail="Only students can access this")
    
    student = db.query(Student).filter(Student.id == current_user.profile_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    
    marks = db.query(StudentMark).filter(
        StudentMark.student_id == student.id,
        StudentMark.is_published == True
    ).order_by(StudentMark.created_at.desc()).all()
    
    return [
        MarkResponse(
            id=str(m.id),
            student_id=student.student_id,
            student_name=student.full_name,
            subject=m.subject,
            term=m.term,
            score=float(m.score),
            max_score=float(m.max_score),
            percentage=round((float(m.score) / float(m.max_score)) * 100, 2),
            grade=m.grade,
            remarks=m.remarks,
            is_published=m.is_published,
            created_at=m.created_at.isoformat() if m.created_at else None
        )
        for m in marks
    ]

@router.get("/child-marks/{student_id}", response_model=List[MarkResponse])
def get_child_marks(
    student_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Parent views their child's published marks."""
    if current_user.role != UserRole.parent:
        raise HTTPException(status_code=403, detail="Only parents can access this")
    
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    if student.parent_email != current_user.email:
        raise HTTPException(status_code=403, detail="Not your child")
    
    marks = db.query(StudentMark).filter(
        StudentMark.student_id == student.id,
        StudentMark.is_published == True
    ).order_by(StudentMark.created_at.desc()).all()
    
    return [
        MarkResponse(
            id=str(m.id),
            student_id=student.student_id,
            student_name=student.full_name,
            subject=m.subject,
            term=m.term,
            score=float(m.score),
            max_score=float(m.max_score),
            percentage=round((float(m.score) / float(m.max_score)) * 100, 2),
            grade=m.grade,
            remarks=m.remarks,
            is_published=m.is_published,
            created_at=m.created_at.isoformat() if m.created_at else None
        )
        for m in marks
    ]
