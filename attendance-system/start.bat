@echo off
echo Starting Face Recognition Attendance System...
echo.

echo Step 1: Starting Docker services (PostgreSQL, Redis, CompreFace)...
docker-compose up -d

echo.
echo Step 2: Waiting for services to start...
timeout /t 10

echo.
echo Step 3: Starting FastAPI backend...
echo Visit http://localhost:8000/docs for API documentation
echo.
uvicorn app.main:app --reload
