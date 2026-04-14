from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID

from app.database import get_db
from app.models import Announcement, User, UserRole
from app.dependencies import get_current_user, require_teacher_or_admin

router = APIRouter()


class AnnouncementCreate(BaseModel):
    title: str
    content: str
    target_roles: Optional[List[str]] = ["student", "parent", "teacher", "admin"]

class AnnouncementUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    target_roles: Optional[List[str]] = None
    is_published: Optional[bool] = None

class AnnouncementResponse(BaseModel):
    id: UUID
    title: str
    content: str
    author_id: UUID
    author_name: Optional[str] = None
    target_roles: list
    is_published: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


@router.post("/", response_model=AnnouncementResponse, status_code=201)
def create_announcement(
    data: AnnouncementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    announcement = Announcement(
        title=data.title,
        content=data.content,
        author_id=current_user.id,
        target_roles=data.target_roles,
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)

    # Trigger notifications to all targeted users (in-app + email for parents)
    try:
        from app.services.notification_service import notify_users_of_announcement, NotificationService
        notify_users_of_announcement(db, announcement, NotificationService())
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Notification dispatch failed: {e}")

    return announcement


@router.get("/", response_model=List[AnnouncementResponse])
def list_announcements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Returns announcements targeted at the current user's role"""
    role = current_user.role.value
    all_announcements = db.query(Announcement).filter(
        Announcement.is_published == True
    ).order_by(Announcement.created_at.desc()).all()

    result = []
    for a in all_announcements:
        if role in (a.target_roles or []):
            author = db.query(User).filter(User.id == a.author_id).first()
            item = AnnouncementResponse(
                id=a.id, title=a.title, content=a.content, author_id=a.author_id,
                author_name=author.full_name if author else None,
                target_roles=a.target_roles or [], is_published=a.is_published,
                created_at=a.created_at, updated_at=a.updated_at
            )
            result.append(item)
    return result


@router.get("/{announcement_id}", response_model=AnnouncementResponse)
def get_announcement(
    announcement_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    if current_user.role.value not in (announcement.target_roles or []):
        raise HTTPException(status_code=403, detail="Access denied")
    return announcement


@router.put("/{announcement_id}", response_model=AnnouncementResponse)
def update_announcement(
    announcement_id: UUID,
    data: AnnouncementUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    # Teachers can only edit their own announcements; admins can edit any
    if current_user.role == UserRole.teacher and announcement.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own announcements")

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(announcement, field, value)
    db.commit()
    db.refresh(announcement)
    return announcement


@router.delete("/{announcement_id}", status_code=204)
def delete_announcement(
    announcement_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin)
):
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    if current_user.role == UserRole.teacher and announcement.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only delete your own announcements")
    db.delete(announcement)
    db.commit()
