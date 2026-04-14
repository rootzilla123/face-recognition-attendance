from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import StudentResponse
from app.models import Student, FaceEmbedding, UserRole
from app.config import settings
from app.dependencies import get_current_user, require_teacher_or_admin, require_admin
from typing import List
from uuid import UUID
import httpx
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/", response_model=StudentResponse, status_code=201)
async def create_student(
    student_id: str = Form(...),
    full_name: str = Form(...),
    grade_level: str = Form(...),
    section: str = Form(None),
    parent_phone: str = Form(...),
    parent_email: str = Form(...),
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Create a new student with face photo (teacher/admin only)"""
    existing = db.query(Student).filter(Student.student_id == student_id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Student ID already exists")

    try:
        photo_bytes = await photo.read()
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{settings.comprefore_url}/api/v1/recognition/faces",
                data={"subject": student_id},
                headers={"x-api-key": settings.comprefore_api_key},
                files={"file": (photo.filename, photo_bytes, photo.content_type)}
            )
            if response.status_code not in [200, 201]:
                if response.status_code == 400 and "No face is found" in response.text:
                    raise HTTPException(status_code=422, detail="No face found in the uploaded image.")
                raise HTTPException(status_code=500, detail=f"CompreFace error: {response.text}")
            comprefore_data = response.json()
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail="Face recognition service unavailable.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to register face: {str(e)}")

    db_student = Student(
        student_id=student_id,
        full_name=full_name,
        grade_level=grade_level,
        section=section,
        parent_phone=parent_phone,
        parent_email=parent_email
    )
    db.add(db_student)
    db.commit()
    db.refresh(db_student)

    face_embedding = FaceEmbedding(
        student_id=db_student.id,
        comprefore_subject_id=student_id,
        comprefore_embedding_id=comprefore_data.get("image_id", ""),
    )
    db.add(face_embedding)
    db.commit()
    return db_student


@router.get("/", response_model=List[StudentResponse])
def list_students(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """List all students (teacher/admin only)"""
    return db.query(Student).filter(Student.is_active == True).offset(skip).limit(limit).all()


@router.get("/me", response_model=StudentResponse)
def get_my_profile(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Student: view own profile"""
    if current_user.role != UserRole.student:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")
    student = db.query(Student).filter(Student.id == current_user.profile_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    return student


@router.get("/{student_id}", response_model=StudentResponse)
def get_student(
    student_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Get student by ID (teacher/admin only)"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


@router.put("/{student_id}", response_model=StudentResponse)
def update_student(
    student_id: str,
    data: dict,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Update student details (teacher/admin only)"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    for field in ['full_name', 'grade_level', 'section', 'parent_name', 'parent_phone', 'parent_email']:
        if field in data:
            setattr(student, field, data[field])
    db.commit()
    db.refresh(student)
    return student


@router.delete("/{student_id}")
def delete_student(
    student_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin)
):
    """Soft delete a student (admin only)"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    student.is_active = False
    db.commit()
    return {"message": "Student deleted successfully"}


@router.get("/{student_id}/photo")
async def get_student_photo(
    student_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Get student face photo from CompreFace (teacher/admin only)"""
    from fastapi.responses import StreamingResponse
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    embedding = db.query(FaceEmbedding).filter(FaceEmbedding.student_id == student.id).first()
    if not embedding:
        raise HTTPException(status_code=404, detail="No face registered")
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{settings.comprefore_url}/api/v1/recognition/faces/{embedding.comprefore_embedding_id}/img",
                headers={"x-api-key": settings.comprefore_api_key}
            )
            if response.status_code == 200:
                return StreamingResponse(
                    iter([response.content]),
                    media_type=response.headers.get("content-type", "image/jpeg")
                )
    except Exception:
        pass
    raise HTTPException(status_code=404, detail="Photo not available")
