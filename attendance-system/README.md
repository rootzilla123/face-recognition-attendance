# Face Recognition Attendance System - Backend

FastAPI backend for the face recognition attendance system.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Start services with Docker:
```bash
docker-compose up -d
```

3. Update `.env` with your credentials

4. Run the application:
```bash
uvicorn app.main:app --reload
```

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Endpoints

- `POST /api/v1/attendance/` - Mark attendance
- `GET /api/v1/attendance/today` - Get today's attendance
- `GET /api/v1/attendance/stats` - Get attendance statistics
- `POST /api/v1/students/` - Create student
- `GET /api/v1/students/` - List students
- `GET /api/v1/students/{student_id}` - Get student details
- `DELETE /api/v1/students/{student_id}` - Delete student

## Services

- PostgreSQL: localhost:5432
- Redis: localhost:6379
- CompreFace: localhost:8000 (API), localhost:3000 (UI)
