from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, UserRole
import httpx
import logging

logger = logging.getLogger(__name__)

PB_URL = "http://localhost:8090"
bearer_scheme = HTTPBearer(auto_error=False)


async def _verify_pb_token(token: str) -> dict | None:
    """Verify token against PocketBase and return user record."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.post(
                f"{PB_URL}/api/collections/users/auth-refresh",
                headers={"Authorization": f"Bearer {token}"}
            )
            if r.status_code == 200:
                return r.json().get("record")
    except Exception as e:
        logger.warning(f"PocketBase token verify failed: {e}")
    return None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not credentials:
        raise credentials_exception

    token = credentials.credentials

    # 1. Try PocketBase token first
    pb_record = await _verify_pb_token(token)
    if pb_record:
        pb_id = pb_record.get("id")
        pb_email = pb_record.get("email")
        pb_role = pb_record.get("role", "student")
        pb_name = pb_record.get("name", "")

        # Find or create matching User in our DB
        user = db.query(User).filter(User.email == pb_email).first()
        if not user:
            # Auto-create user record from PocketBase data
            try:
                role_enum = UserRole(pb_role)
            except ValueError:
                role_enum = UserRole.student

            user = User(
                email=pb_email,
                password_hash="pb_managed",
                role=role_enum,
                full_name=pb_name,
                is_active=True,
                is_verified=True,
            )
            db.add(user)
            db.commit()
            db.refresh(user)

            # Auto-link profile_id from PocketBase record
            pb_profile_id = pb_record.get("profile_id", "")
            if pb_profile_id and role_enum == UserRole.student:
                from app.models import Student
                student = db.query(Student).filter(Student.student_id == pb_profile_id).first()
                if student:
                    user.profile_id = student.id
                    db.commit()
            elif pb_profile_id and role_enum == UserRole.parent:
                from app.models import Parent
                parent = db.query(Parent).filter(Parent.email == pb_email).first()
                if parent:
                    user.profile_id = parent.id
                    db.commit()
            elif role_enum == UserRole.teacher:
                from app.models import Teacher
                teacher = db.query(Teacher).filter(Teacher.email == pb_email).first()
                if teacher:
                    user.profile_id = teacher.id
                    db.commit()

        if not user.is_active:
            raise HTTPException(status_code=403, detail="Account is disabled")
        return user

    # 2. Fall back to legacy FastAPI JWT (for backward compat)
    from app.services.auth import decode_token
    payload = decode_token(token)
    if payload:
        user_id = payload.get("sub")
        if user_id:
            user = db.query(User).filter(User.id == user_id).first()
            if user and user.is_active:
                return user

    raise credentials_exception


def require_roles(*roles: UserRole):
    async def _check(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this resource"
            )
        return current_user
    return _check


# Convenience role dependencies
require_admin = require_roles(UserRole.admin)
require_teacher_or_admin = require_roles(UserRole.teacher, UserRole.admin)
require_student = require_roles(UserRole.student)
require_parent = require_roles(UserRole.parent)
require_any = require_roles(UserRole.admin, UserRole.teacher, UserRole.student, UserRole.parent)
