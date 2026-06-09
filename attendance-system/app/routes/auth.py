from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID
from slowapi import Limiter
from slowapi.util import get_remote_address
import httpx
import os

from app.database import get_db
from app.models import User, UserRole, Student, Teacher, Parent
from app.services.auth import (
    hash_password, authenticate_user, create_access_token, get_user_by_email
)
from app.dependencies import get_current_user
from app.config import settings

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
    PB_URL = os.environ.get("PB_URL", "http://localhost:8092")
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
    PB_URL = os.environ.get("PB_URL", "http://localhost:8092")
    async with httpx.AsyncClient(timeout=10.0) as client:
        r = await client.post(
            f"{PB_URL}/api/collections/users/request-password-reset",
            json={"email": data.email}
        )
    return {"message": "Reset email sent if account exists"}


# ---------- Google / Firebase Sign-In ----------

class GoogleAuthRequest(BaseModel):
    firebase_token: str
    default_role: str = "student"

PB_URL = os.environ.get("PB_URL", "http://localhost:8092")

@router.post("/google")
async def google_sign_in(data: GoogleAuthRequest):
    """
    Verify a Firebase ID token, then find-or-create the user in PocketBase
    and return a PocketBase auth token.
    """
    # 1. Verify Firebase token
    try:
        import firebase_admin
        from firebase_admin import auth as fb_auth, credentials

        # Initialise the app once (idempotent)
        if not firebase_admin._apps:
            sa_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "") or settings.google_application_credentials
            if sa_path and os.path.exists(sa_path):
                cred = credentials.Certificate(sa_path)
            else:
                cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred, {"projectId": settings.firebase_project_id})

        decoded = fb_auth.verify_id_token(data.firebase_token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {e}")

    email: str = decoded.get("email", "")
    name: str = decoded.get("name", email.split("@")[0])
    if not email:
        raise HTTPException(status_code=400, detail="Firebase token has no email")

    # 2. Find or create user in PocketBase
    async with httpx.AsyncClient(timeout=10.0) as client:
        # Get PocketBase admin token
        admin_res = await client.post(
            f"{PB_URL}/api/collections/_superusers/auth-with-password",
            json={"identity": settings.pb_admin_email, "password": settings.pb_admin_password},
        )
        if admin_res.status_code != 200:
            raise HTTPException(status_code=500, detail="PocketBase admin auth failed")
        admin_token = admin_res.json()["token"]
        admin_headers = {"Authorization": admin_token}

        # Check if user exists
        search_res = await client.get(
            f"{PB_URL}/api/collections/users/records",
            params={"filter": f'email="{email}"', "perPage": 1},
            headers=admin_headers,
        )
        items = search_res.json().get("items", [])

        if items:
            pb_user_id = items[0]["id"]
            # Auth as that user via impersonation (admin token exchange)
            auth_res = await client.post(
                f"{PB_URL}/api/collections/users/impersonate/{pb_user_id}",
                headers=admin_headers,
                json={},
            )
            if auth_res.status_code != 200:
                raise HTTPException(status_code=500, detail=f"PocketBase impersonate failed: {auth_res.text}")

            auth_data = auth_res.json()
            return {"token": auth_data["token"], "record": auth_data["record"], "is_new": False}
        else:
            # User does not exist. If we are just detecting, return now.
            if data.default_role == "detect":
                return {"is_new": True}

            # Create the user
            import secrets
            tmp_password = secrets.token_urlsafe(24)
            create_res = await client.post(
                f"{PB_URL}/api/collections/users/records",
                headers=admin_headers,
                json={
                    "email": email,
                    "password": tmp_password,
                    "passwordConfirm": tmp_password,
                    "name": name,
                    "role": data.default_role,
                    "emailVisibility": True,
                    "verified": True,
                },
            )
            if create_res.status_code not in (200, 201):
                raise HTTPException(status_code=500, detail=f"Could not create PocketBase user: {create_res.text}")
            
            pb_user_id = create_res.json()["id"]
            auth_res = await client.post(
                f"{PB_URL}/api/collections/users/impersonate/{pb_user_id}",
                headers=admin_headers,
                json={},
            )
            if auth_res.status_code != 200:
                raise HTTPException(status_code=500, detail=f"PocketBase impersonate failed post-create: {auth_res.text}")

            auth_data = auth_res.json()
            return {"token": auth_data["token"], "record": auth_data["record"], "is_new": True}


# ---------- Device Token Management ----------

class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "android"  # android or ios

@router.post("/device-token")
def register_device_token(
    data: DeviceTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Register a device token for push notifications"""
    if not data.token:
        raise HTTPException(status_code=400, detail="Token is required")
    
    # Get current tokens
    tokens = current_user.device_tokens or []
    
    # Add token if not already present
    if data.token not in tokens:
        tokens.append(data.token)
        current_user.device_tokens = tokens
        db.commit()
        return {"message": "Device token registered", "token_count": len(tokens)}
    
    return {"message": "Token already registered", "token_count": len(tokens)}

@router.delete("/device-token")
def unregister_device_token(
    data: DeviceTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove a device token (e.g., on logout)"""
    tokens = current_user.device_tokens or []
    
    if data.token in tokens:
        tokens.remove(data.token)
        current_user.device_tokens = tokens
        db.commit()
        return {"message": "Device token removed", "token_count": len(tokens)}
    
    return {"message": "Token not found", "token_count": len(tokens)}
