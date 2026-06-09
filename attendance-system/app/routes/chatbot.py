"""
AI-powered attendance chatbot using Ollama (llama3.2).

Strategy:
  1. Pull live data from the DB (attendance, students, cameras, marks).
  2. Inject it as structured context into the system prompt.
  3. Send the user's message to Ollama — the LLM reasons over real data.

This means the AI can answer anything: comparisons, trends, natural follow-ups,
multi-step questions — not just keyword matching.
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import date, datetime, timedelta
from typing import Optional
import httpx
import logging
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.database import get_db
from app.models import AttendanceRecord, Student, StudentMark, Camera, User, UserRole
from app.dependencies import get_current_user
from app.config import settings as _settings

logger = logging.getLogger(__name__)
router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

OLLAMA_URL = _settings.ollama_url.rstrip("/") + "/api/chat"
MODEL = _settings.ollama_model

# Conversation history storage key prefix
HISTORY_KEY_PREFIX = "chatbot:history:"
MAX_HISTORY = 10  # keep last 10 turns
HISTORY_TTL = 86400  # 24 hours


class ChatRequest(BaseModel):
    message: str
    clear_history: bool = False


class ChatResponse(BaseModel):
    reply: str


# ── Context builder ───────────────────────────────────────────────────────────

def _build_context(db: Session, user: User) -> str:
    """Pull live DB data and format it as context for the LLM."""
    today = date.today()
    start = datetime.combine(today, datetime.min.time())
    end = datetime.combine(today, datetime.max.time())

    # Today's attendance
    total_students = db.query(Student).filter(Student.is_active == True).count()
    present_ids = {
        r for r, in db.query(AttendanceRecord.student_id).filter(
            AttendanceRecord.timestamp >= start,
            AttendanceRecord.timestamp <= end,
        ).distinct()
    }
    present = len(present_ids)
    absent = total_students - present
    rate = round(present / total_students * 100, 1) if total_students else 0

    # Absent students (up to 20)
    absent_students = db.query(Student).filter(
        Student.is_active == True,
        Student.id.notin_(present_ids),
    ).order_by(Student.grade_level, Student.full_name).limit(20).all()
    absent_list = ", ".join(f"{s.full_name} ({s.grade_level})" for s in absent_students)

    # Late arrivals (after 8am)
    from sqlalchemy import func as sqlfunc
    late_records = db.query(AttendanceRecord, Student).join(
        Student, AttendanceRecord.student_id == Student.id
    ).filter(
        AttendanceRecord.timestamp >= start,
        AttendanceRecord.timestamp <= end,
        sqlfunc.extract("hour", AttendanceRecord.timestamp) >= 8,
    ).order_by(AttendanceRecord.timestamp).all()
    seen = set()
    late_list = []
    for r, s in late_records:
        if s.id not in seen:
            seen.add(s.id)
            late_list.append(f"{s.full_name} at {r.timestamp.strftime('%H:%M')}")

    # 7-day trend
    trend_lines = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        ds = datetime.combine(day, datetime.min.time())
        de = datetime.combine(day, datetime.max.time())
        p = db.query(AttendanceRecord.student_id).filter(
            AttendanceRecord.timestamp >= ds,
            AttendanceRecord.timestamp <= de,
        ).distinct().count()
        r_val = round(p / total_students * 100, 1) if total_students else 0
        trend_lines.append(f"  {day.strftime('%a %d %b')}: {p}/{total_students} present ({r_val}%)")

    # Camera status
    cameras = db.query(Camera).filter(Camera.is_active == True).all()
    online_cams = [c.name for c in cameras if c.status == "online"]
    offline_cams = [c.name for c in cameras if c.status != "online"]

    # Grade breakdown
    all_students = db.query(Student).filter(Student.is_active == True).all()
    grade_map: dict[str, dict] = {}
    for s in all_students:
        g = s.grade_level
        if g not in grade_map:
            grade_map[g] = {"total": 0, "present": 0}
        grade_map[g]["total"] += 1
        if s.id in present_ids:
            grade_map[g]["present"] += 1
    grade_lines = [
        f"  {g}: {v['present']}/{v['total']} present ({round(v['present']/v['total']*100,1) if v['total'] else 0}%)"
        for g, v in sorted(grade_map.items())
    ]

    # Role-specific context
    role_ctx = ""
    if user.role == UserRole.student:
        student = db.query(Student).filter(Student.id == user.profile_id).first()
        if student:
            my_records = db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == student.id,
                AttendanceRecord.timestamp >= datetime.combine(today - timedelta(days=30), datetime.min.time()),
            ).order_by(AttendanceRecord.timestamp.desc()).limit(10).all()
            days_present = len({r.timestamp.date() for r in my_records})
            my_marks = db.query(StudentMark).filter(
                StudentMark.student_id == student.id,
                StudentMark.is_published == True,
            ).order_by(StudentMark.created_at.desc()).limit(10).all()
            marks_lines = [
                f"  {m.subject} ({m.term}): {m.score}/{m.max_score} — {m.grade or str(round(float(m.score)/float(m.max_score)*100,1))+'%'}"
                for m in my_marks
            ]
            role_ctx = f"""
CURRENT USER (Student):
  Name: {student.full_name}
  ID: {student.student_id}
  Grade: {student.grade_level}{', Section ' + student.section if student.section else ''}
  Days present (last 30 days): {days_present}
  Published marks:
{chr(10).join(marks_lines) if marks_lines else '  None yet'}
"""
    elif user.role == UserRole.parent:
        from app.models import ParentStudent, Parent
        parent = db.query(Parent).filter(Parent.id == user.profile_id).first()
        if parent:
            links = db.query(ParentStudent).filter(ParentStudent.parent_id == parent.id).all()
            children_info = []
            for link in links:
                child = db.query(Student).filter(Student.id == link.student_id).first()
                if child:
                    child_present = child.id in present_ids
                    children_info.append(f"  {child.full_name} ({child.grade_level}) — {'Present' if child_present else 'Absent'} today")
            role_ctx = f"""
CURRENT USER (Parent): {parent.full_name}
Children:
{chr(10).join(children_info) if children_info else '  No children linked'}
"""

    context = f"""TODAY: {today.strftime('%A, %d %B %Y')}

ATTENDANCE SUMMARY (Today):
  Total students: {total_students}
  Present: {present} ({rate}%)
  Absent: {absent}
  Absent students: {absent_list or 'None'}
  Late arrivals (after 08:00): {', '.join(late_list) if late_list else 'None'}

ATTENDANCE BY GRADE:
{chr(10).join(grade_lines) if grade_lines else '  No data'}

7-DAY TREND:
{chr(10).join(trend_lines)}

CAMERAS:
  Online ({len(online_cams)}): {', '.join(online_cams) or 'None'}
  Offline ({len(offline_cams)}): {', '.join(offline_cams) or 'None'}
{role_ctx}"""

    return context


# ── System prompt ─────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are an intelligent attendance assistant for ShadomFacePro, a school face recognition attendance system.

You have access to live school data provided below. Use it to answer questions accurately and helpfully.

Guidelines:
- Be concise but complete. Use bullet points for lists.
- When showing numbers, be precise — use the exact figures from the data.
- If asked about something not in the data, say so honestly.
- You can do comparisons, spot trends, and give recommendations.
- Be friendly and professional — you're talking to school staff, teachers, parents, or students.
- Never make up student names or numbers not in the data.
- Format responses clearly using markdown (bold, bullets, etc.).

LIVE SCHOOL DATA:
{context}"""


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
@limiter.limit("20/minute")
async def chat(
    request: Request,
    req: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.main import redis_client
    
    user_id = str(current_user.id)
    history_key = f"{HISTORY_KEY_PREFIX}{user_id}"

    # Clear history if requested
    if req.clear_history:
        redis_client.delete(history_key)

    # Build live context
    try:
        context = _build_context(db, current_user)
    except Exception as e:
        logger.error(f"Context build failed: {e}")
        context = f"TODAY: {date.today()}\n(Could not load live data)"

    # Get conversation history from Redis
    history = []
    try:
        import json
        history_json = redis_client.get(history_key)
        if history_json:
            history = json.loads(history_json)
    except Exception as e:
        logger.warning(f"Failed to load chat history from Redis: {e}")

    # Build messages for Ollama
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT.format(context=context)},
        *history,
        {"role": "user", "content": req.message},
    ]

    # Call Ollama
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                OLLAMA_URL,
                json={
                    "model": MODEL,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": 0.3,   # factual, not creative
                        "num_predict": 512,   # keep responses concise
                    },
                },
            )
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail=f"Ollama error: {response.text}")

            data = response.json()
            reply = data["message"]["content"].strip()

    except httpx.ConnectError:
        raise HTTPException(
            status_code=503,
            detail="Ollama is not running. Start it with: ollama serve",
        )
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="AI response timed out. Try a shorter question.")

    # Update history (keep last MAX_HISTORY turns)
    history.append({"role": "user", "content": req.message})
    history.append({"role": "assistant", "content": reply})
    if len(history) > MAX_HISTORY * 2:
        history = history[-(MAX_HISTORY * 2):]
    
    # Save to Redis
    try:
        import json
        redis_client.setex(history_key, HISTORY_TTL, json.dumps(history))
    except Exception as e:
        logger.warning(f"Failed to save chat history to Redis: {e}")

    return ChatResponse(reply=reply)
