from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.database import get_db
from app.models import User, UserRole, Student, Teacher, Parent
from app.services.auth import (
    hash_password, authenticate_user, create_access_token, get_user_by_email
)
from app.dependencies import get_current_user

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


# ---------- Schemas ----------

class RegisterStudent(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    student_id: str
    grade_level: str
    section: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None

class RegisterParent(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: Optional[str] = None

class RegisterTeacher(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    employee_id: str
    department: Optional[str] = None
    phone: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    full_name: str

class UserProfile(BaseModel):
    id: UUID
    email: str
    role: str
    full_name: str
    is_active: bool
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ---------- Routes ----------

@router.post("/register/student", status_code=201)
@limiter.limit("5/minute")
def register_student(request: Request, data: RegisterStudent, db: Session = Depends(get_db)):
    """Self-registration for students"""
    if get_user_by_email(db, data.email):
        raise HTTPException(status_code=409, detail="Email already registered")

    # Check student_id not taken
    if db.query(Student).filter(Student.student_id == data.student_id).first():
        raise HTTPException(status_code=409, detail="Student ID already exists")

    # Create student profile
    student = Student(
        student_id=data.student_id,
        full_name=data.full_name,
        grade_level=data.grade_level,
        section=data.section,
        parent_phone=data.parent_phone,
        parent_email=data.parent_email,
    )
    db.add(student)
    db.flush()

    # Create user account
    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.student,
        full_name=data.full_name,
        profile_id=student.id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "Student registered successfully", "user_id": str(user.id)}


@router.post("/register/parent", status_code=201)
@limiter.limit("5/minute")
def register_parent(request: Request, data: RegisterParent, db: Session = Depends(get_db)):
    """Self-registration for parents"""
    if get_user_by_email(db, data.email):
        raise HTTPException(status_code=409, detail="Email already registered")

    parent = Parent(
        full_name=data.full_name,
        email=data.email,
        phone=data.phone,
    )
    db.add(parent)
    db.flush()

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.parent,
        full_name=data.full_name,
        profile_id=parent.id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "Parent registered successfully", "user_id": str(user.id)}


@router.post("/register/teacher", status_code=201)
async def register_teacher(
    data: RegisterTeacher,
    db: Session = Depends(get_db),
    _: User = Depends(__import__("app.dependencies", fromlist=["require_admin"]).require_admin)
):
    """Admin-only: create a teacher account"""
    if get_user_by_email(db, data.email):
        raise HTTPException(status_code=409, detail="Email already registered")

    if db.query(Teacher).filter(Teacher.employee_id == data.employee_id).first():
        raise HTTPException(status_code=409, detail="Employee ID already exists")

    teacher = Teacher(
        employee_id=data.employee_id,
        full_name=data.full_name,
        email=data.email,
        phone=data.phone,
        department=data.department,
    )
    db.add(teacher)
    db.flush()

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.teacher,
        full_name=data.full_name,
        profile_id=teacher.id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Also create in PocketBase so the teacher can log in
    import httpx
    PB_URL = "http://localhost:8090"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.post(
                f"{PB_URL}/api/collections/users/records",
                json={
                    "email": data.email,
                    "password": data.password,
                    "passwordConfirm": data.password,
                    "name": data.full_name,
                    "role": "teacher",
                    "emailVisibility": True,
                    "verified": True,
                }
            )
            if r.status_code not in (200, 201):
                raise HTTPException(status_code=500, detail=f"PocketBase error: {r.text}")
    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Could not reach PocketBase: {e}")

    return {"message": "Teacher created successfully", "user_id": str(user.id)}


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login with email + password, returns JWT"""
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        user_id=str(user.id),
        full_name=user.full_name,
    )


@router.get("/me", response_model=UserProfile)
def get_me(current_user: User = Depends(get_current_user)):
    """Get current logged-in user profile"""
    return current_user


@router.post("/register/admin", status_code=201)
def register_first_admin(data: RegisterTeacher, db: Session = Depends(get_db)):
    """
    Bootstrap: create the first admin if none exists.
    Once an admin exists, this endpoint is locked.
    """
    admin_exists = db.query(User).filter(User.role == UserRole.admin).first()
    if admin_exists:
        raise HTTPException(status_code=403, detail="Admin already exists. Contact your system admin.")

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.admin,
        full_name=data.full_name,
        is_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"message": "Admin account created", "user_id": str(user.id)}


class PasswordResetRequest(BaseModel):
    email: str

@router.post("/reset-password")
async def send_password_reset(
    data: PasswordResetRequest,
    _=Depends(__import__("app.dependencies", fromlist=["require_admin"]).require_admin)
):
    """Admin: trigger password reset email via PocketBase"""
    import httpx
    PB_URL = "http://localhost:8091"
    async with httpx.AsyncClient(timeout=10.0) as client:
        r = await client.post(
            f"{PB_URL}/api/collections/users/request-password-reset",
            json={"email": data.email}
        )
    return {"message": "Reset email sent if account exists"}
