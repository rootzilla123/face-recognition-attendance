"""
Simple in-app messaging between users (teacher↔parent, admin↔teacher, etc.)
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID
import uuid

from app.database import get_db
from app.models import User
from app.dependencies import get_current_user

router = APIRouter()


# ── Models ────────────────────────────────────────────────────────────────────

from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.database import Base


class Message(Base):
    __tablename__ = "messages"
    id = Column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sender_id = Column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    recipient_id = Column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# ── Schemas ───────────────────────────────────────────────────────────────────

class SendMessageRequest(BaseModel):
    recipient_id: str
    content: str


class MessageResponse(BaseModel):
    id: str
    sender_id: str
    recipient_id: str
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/conversations")
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all conversations for the current user (grouped by other party)."""
    # Get all unique users this person has exchanged messages with
    sent = db.query(Message.recipient_id).filter(Message.sender_id == current_user.id).distinct()
    received = db.query(Message.sender_id).filter(Message.recipient_id == current_user.id).distinct()

    other_ids = {str(r[0]) for r in sent} | {str(r[0]) for r in received}

    conversations = []
    for other_id in other_ids:
        other_user = db.query(User).filter(User.id == other_id).first()
        if not other_user:
            continue

        # Get last message
        last_msg = db.query(Message).filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.recipient_id == other_id),
                and_(Message.sender_id == other_id, Message.recipient_id == current_user.id),
            )
        ).order_by(Message.created_at.desc()).first()

        unread = db.query(Message).filter(
            Message.sender_id == other_id,
            Message.recipient_id == current_user.id,
            Message.is_read == False,
        ).count()

        conversations.append({
            "id": other_id,  # conversation ID = other user's ID
            "other_user": {
                "id": str(other_user.id),
                "full_name": other_user.full_name,
                "role": other_user.role.value,
            },
            "last_message": {
                "content": last_msg.content,
                "created_at": last_msg.created_at.isoformat(),
                "is_mine": str(last_msg.sender_id) == str(current_user.id),
            } if last_msg else None,
            "unread_count": unread,
        })

    # Sort by last message time
    conversations.sort(
        key=lambda c: c["last_message"]["created_at"] if c["last_message"] else "",
        reverse=True,
    )
    return conversations


@router.get("/{other_user_id}")
def get_messages(
    other_user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get message thread between current user and another user."""
    messages = db.query(Message).filter(
        or_(
            and_(Message.sender_id == current_user.id, Message.recipient_id == other_user_id),
            and_(Message.sender_id == other_user_id, Message.recipient_id == current_user.id),
        )
    ).order_by(Message.created_at.asc()).all()

    # Mark received messages as read
    db.query(Message).filter(
        Message.sender_id == other_user_id,
        Message.recipient_id == current_user.id,
        Message.is_read == False,
    ).update({"is_read": True})
    db.commit()

    return [
        {
            "id": str(m.id),
            "sender_id": str(m.sender_id),
            "recipient_id": str(m.recipient_id),
            "content": m.content,
            "is_read": m.is_read,
            "created_at": m.created_at.isoformat(),
        }
        for m in messages
    ]


@router.post("")
def send_message(
    data: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send a message to another user."""
    recipient = db.query(User).filter(User.id == data.recipient_id).first()
    if not recipient:
        raise HTTPException(status_code=404, detail="Recipient not found")

    msg = Message(
        sender_id=current_user.id,
        recipient_id=recipient.id,
        content=data.content.strip(),
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return {"id": str(msg.id), "message": "Sent"}


@router.get("/users/searchable")
def get_messageable_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get list of users the current user can message."""
    from app.models import UserRole
    # Teachers/admins can message anyone; parents can message teachers/admins
    if current_user.role in (UserRole.admin, UserRole.teacher):
        users = db.query(User).filter(User.id != current_user.id, User.is_active == True).all()
    else:
        users = db.query(User).filter(
            User.id != current_user.id,
            User.is_active == True,
            User.role.in_([UserRole.teacher, UserRole.admin]),
        ).all()

    return [
        {"id": str(u.id), "full_name": u.full_name, "role": u.role.value}
        for u in users
    ]
