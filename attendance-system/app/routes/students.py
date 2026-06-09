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
from app.routes.admin import write_audit
import cv2
import numpy as np

router = APIRouter()
logger = logging.getLogger(__name__)

MAX_PHOTO_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB
MIN_FACE_PROBABILITY = 0.80
MIN_FACE_WIDTH = 80
MIN_FACE_HEIGHT = 80
MIN_BLUR_VARIANCE = 80.0


async def _validate_face_photo(photo: UploadFile, photo_bytes: bytes):
    """Validate uploaded face photo quality before enrollment."""
    if not photo.content_type or not photo.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="Uploaded file must be an image.")
    if len(photo_bytes) == 0:
        raise HTTPException(status_code=422, detail="Uploaded image is empty.")
    if len(photo_bytes) > MAX_PHOTO_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="Uploaded image exceeds 5MB limit.")

    # Basic blur detection using variance of Laplacian.
    image = cv2.imdecode(np.frombuffer(photo_bytes, np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise HTTPException(status_code=422, detail="Invalid image file.")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur_variance = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if blur_variance < MIN_BLUR_VARIANCE:
        raise HTTPException(status_code=422, detail="Image is too blurry. Please upload a clearer photo.")

    # Validate detectable face quality via CompreFace detection service.
    async with httpx.AsyncClient(timeout=30.0) as client:
        detection_response = await client.post(
            f"{settings.comprefore_url}/api/v1/detection/detect",
            headers={"x-api-key": settings.comprefore_detection_api_key},
            files={"file": (photo.filename or "face.jpg", photo_bytes, photo.content_type)},
        )
    if detection_response.status_code in (401, 403):
        raise HTTPException(status_code=500, detail="CompreFace detection API key is invalid.")
    if detection_response.status_code != 200:
        raise HTTPException(status_code=503, detail="Face detection service unavailable.")

    payload = detection_response.json()
    results = payload.get("result") or []
    if not results:
        raise HTTPException(status_code=422, detail="No face found in the uploaded image.")
    if len(results) > 1:
        raise HTTPException(status_code=422, detail="Multiple faces detected. Upload a photo with only one face.")

    box = results[0].get("box") or {}
    probability = float(box.get("probability", 0.0))
    face_width = int(box.get("x_max", 0)) - int(box.get("x_min", 0))
    face_height = int(box.get("y_max", 0)) - int(box.get("y_min", 0))

    if probability < MIN_FACE_PROBABILITY:
        raise HTTPException(status_code=422, detail="Face detection confidence is too low. Use a clearer, front-facing photo.")
    if face_width < MIN_FACE_WIDTH or face_height < MIN_FACE_HEIGHT:
        raise HTTPException(status_code=422, detail="Detected face is too small. Move closer to the camera and retry.")


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
        await _validate_face_photo(photo, photo_bytes)
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


@router.post("/{student_id}/enroll-face")
async def enroll_face(
    student_id: str,
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
    _=Depends(require_teacher_or_admin)
):
    """Re-enroll / update face photo for an existing student"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    photo_bytes = await photo.read()
    try:
        await _validate_face_photo(photo, photo_bytes)
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Delete old faces for this subject first
            await client.delete(
                f"{settings.comprefore_url}/api/v1/recognition/faces",
                params={"subject": student_id},
                headers={"x-api-key": settings.comprefore_api_key}
            )
            # Enroll new face
            response = await client.post(
                f"{settings.comprefore_url}/api/v1/recognition/faces",
                data={"subject": student_id},
                headers={"x-api-key": settings.comprefore_api_key},
                files={"file": (photo.filename, photo_bytes, photo.content_type)}
            )
            if response.status_code not in [200, 201]:
                if "No face is found" in response.text:
                    raise HTTPException(status_code=422, detail="No face found in the uploaded image.")
                raise HTTPException(status_code=500, detail=f"CompreFace error: {response.text}")
            data = response.json()
    except HTTPException:
        raise
    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Face recognition service unavailable.")

    # Update or create embedding record
    embedding = db.query(FaceEmbedding).filter(FaceEmbedding.student_id == student.id).first()
    if embedding:
        embedding.comprefore_embedding_id = data.get("image_id", "")
    else:
        db.add(FaceEmbedding(
            student_id=student.id,
            comprefore_subject_id=student_id,
            comprefore_embedding_id=data.get("image_id", ""),
        ))
    db.commit()
    write_audit(db, _, action="enroll_face", target_type="student", target_id=student_id)
    return {"message": "Face enrolled successfully", "image_id": data.get("image_id")}


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
