# Senior Backend Engineer Brief: Attendance System API

## Executive Summary

You've been brought in as a senior backend engineer to take the core API from 70% complete to production-ready. The face recognition pipeline, attendance tracking, and notifications are partially working, but there are critical gaps in data integrity, error handling, resilience, and scalability.

Your job is to:
1. Fix 4 critical blockers (3.5 hours)
2. Build missing endpoints and services (40-50 hours)
3. Implement robust error handling and observability (20-30 hours)
4. Ensure reliability and security (20-30 hours)
5. Deploy and monitor (10-20 hours)

**Timeline**: 4 weeks to production-ready backend
**Tech Stack**: FastAPI (Python), PostgreSQL, Redis, CompreFace, Twilio, Resend
**Deployment**: Docker on homelab server with remote management via Cloudflare Tunnel

---

## Current State

### ✅ What Works (70% Complete)
- **Core API**: FastAPI with role-based access control
- **Database**: PostgreSQL schema complete, Alembic migrations
- **Face Recognition Pipeline**: CompreFace integration (but API key invalid)
- **Attendance Tracking**: Recording system working
- **Notifications**: Twilio (SMS) and Resend (Email) integrated
- **WebSocket**: Real-time updates implemented
- **Video Streaming**: MJPEG from cameras
- **Authentication**: JWT + PocketBase hybrid system
- **Backup**: Scripts created but not deployed

### ❌ Critical Blockers (3.5 hours to fix)
1. **CompreFace API Key Invalid** (5 min)
   - Face recognition completely broken
   - Fix: Create Recognition Service in CompreFace UI

2. **No Face Enrollment Endpoint** (2 hrs)
   - Students can't upload photos
   - Fix: POST /api/v1/students/{id}/enroll-face

3. **Notification Retry Missing** (1 hr)
   - Failed SMS/Email not retried
   - Fix: Add exponential backoff retry logic

4. **Environment Validation Missing** (30 min)
   - System starts with invalid config
   - Fix: Add startup validation with clear errors

### ❌ Major Gaps (40-50 hours to complete)
- **Missing Endpoints**: Face enrollment, attendance verification, camera health, notification status
- **Error Handling**: Generic 500 errors, no validation, no circuit breakers
- **Observability**: Limited logging, no metrics, no tracing
- **Resilience**: No retries, no fallbacks, no timeouts
- **Security**: Limited input validation, no rate limiting on critical endpoints
- **Testing**: No integration tests, no end-to-end tests
- **Documentation**: API docs incomplete

---

## Architecture Overview

### API Structure

```
FastAPI Server
├── Routes
│   ├── /api/v1/auth/ (Login, register, token refresh)
│   ├── /api/v1/students/ (CRUD, enrollment)
│   ├── /api/v1/teachers/ (CRUD, class management)
│   ├── /api/v1/parents/ (CRUD, child management)
│   ├── /api/v1/attendance/ (Recording, verification, export)
│   ├── /api/v1/cameras/ (CRUD, health check, stream)
│   ├── /api/v1/notifications/ (Send, status, preferences)
│   ├── /api/v1/reports/ (Attendance, analytics)
│   └── /health (Health check endpoint)
├── Services
│   ├── FaceRecognitionService (CompreFace integration)
│   ├── AttendanceService (Logic for marking)
│   ├── NotificationService (Twilio, Resend, Firebase)
│   ├── CameraService (RTSP, HTTP streams)
│   ├── VideoService (Clip recording, retention)
│   └── ReportService (Analytics, exports)
├── Models
│   ├── Student, Teacher, Parent
│   ├── Attendance, Camera, FaceEmbedding
│   ├── Notification, NotificationPreference
│   └── VideoClip
├── Database
│   ├── PostgreSQL (persistent data)
│   ├── Redis (cache, queues)
│   └── Alembic (migrations)
├── WebSocket
│   └── Real-time updates (attendance, alerts)
└── Background Jobs
    ├── Video clip retention
    ├── Notification retry
    ├── Backup system
    └── Monitoring/health checks
```

### Data Flow

```
Camera (RTSP)
    ↓
Frame Capture
    ↓
Face Detection (CompreFace)
    ↓
Face Recognition (CompreFace)
    ↓
Attendance Recording (PostgreSQL)
    ↓
Notification Service (Twilio/Resend/Firebase)
    ↓
Parent Receives SMS/Email/Push
    ↓
Mobile/Desktop App Updates (WebSocket)
```

---

## Your Mission

### Phase 1: Fix Critical Blockers (This Week - 3.5 hours)

**Task 1: Fix CompreFace API Key** (5 minutes)
- Access CompreFace UI at http://localhost:8080
- Create Recognition Service (NOT Detection Service)
- Copy new API key
- Update `.env` file
- Restart backend
- Verify face recognition works

**Task 2: Add Face Enrollment Endpoint** (2 hours)
```
POST /api/v1/students/{student_id}/enroll-face
- Accept photo upload (multipart/form-data)
- Validate photo quality (face detected, not blurry)
- Call CompreFace to create subject
- Store embedding ID in database
- Return clear error messages
```

**Endpoint Spec**:
```python
# Request
POST /api/v1/students/{student_id}/enroll-face
Content-Type: multipart/form-data
Authorization: Bearer {token}

photo: <image file>

# Response (200 OK)
{
  "success": true,
  "message": "Face enrolled successfully",
  "data": {
    "student_id": "uuid",
    "embedding_id": "compreface_subject_id",
    "enrolled_at": "2024-01-15T10:30:00Z"
  }
}

# Response (400 Bad Request)
{
  "success": false,
  "error": "face_not_detected",
  "message": "No face detected in photo. Please upload a clear photo.",
  "details": {
    "suggestion": "Ensure face is clearly visible, well-lit, and centered"
  }
}
```

**Implementation Considerations**:
- Validate image format (JPEG, PNG)
- Validate image size (<5MB)
- Check face quality (face must be >100px)
- Handle CompreFace errors gracefully
- Log enrollment attempts
- Return clear error messages to client

**Task 3: Add Notification Retry** (1 hour)
```
Implement exponential backoff retry logic for failed notifications
```

**Retry Strategy**:
- Store failed notifications in database with retry count
- Retry on transient failures (5xx, timeouts)
- Don't retry permanent failures (invalid key, bad phone)
- Exponential backoff: 1s, 2s, 4s, 8s
- Max 3 retries (total ~15 seconds)
- Log all retry attempts

**Implementation**:
```python
# Notification model
class Notification:
    id: UUID
    recipient: str  # phone or email
    message: str
    status: str  # pending, sent, failed, permanent_failure
    retry_count: int = 0
    last_retry_at: Optional[datetime]
    error_message: Optional[str]
    created_at: datetime

# Retry service
async def retry_failed_notifications():
    # Run every 5 minutes
    failed = await db.query(
        Notification
    ).filter(
        status == "failed",
        retry_count < 3,
        last_retry_at < now() - backoff_delay(retry_count)
    )
    
    for notif in failed:
        try:
            await send_notification(notif)
            notif.status = "sent"
        except TransientError:
            notif.retry_count += 1
            notif.last_retry_at = now()
            notif.status = "failed"
        except PermanentError as e:
            notif.status = "permanent_failure"
            notif.error_message = str(e)
```

**Task 4: Add Environment Validation** (30 minutes)
```
Validate all critical environment variables at startup
```

**Validation Levels**:

Level 1: Existence (fast)
```python
REQUIRED_VARS = [
    "SECRET_KEY",
    "DATABASE_URL",
    "COMPREFACE_API_KEY",
    "TWILIO_ACCOUNT_SID",
    "RESEND_API_KEY"
]

for var in REQUIRED_VARS:
    value = os.getenv(var)
    if not value or value == "CHANGE_ME":
        raise ConfigError(f"Missing or invalid {var}")
```

Level 2: Format (fast)
```python
# Validate UUID format
if not is_valid_uuid(COMPREFACE_API_KEY):
    raise ConfigError("COMPREFACE_API_KEY must be valid UUID")

# Validate URL format
if not is_valid_url(DATABASE_URL):
    raise ConfigError("DATABASE_URL must be valid URL")
```

Level 3: Connectivity (slow, optional)
```python
# Test database connection
try:
    async with engine.connect() as conn:
        await conn.exec_driver_sql("SELECT 1")
except Exception as e:
    raise ConfigError(f"Cannot connect to database: {e}")

# Test CompreFace connection
try:
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{COMPREFACE_URL}/status")
        resp.raise_for_status()
except Exception as e:
    raise ConfigError(f"Cannot reach CompreFace: {e}")
```

**Success Criteria**:
- ✅ Face recognition works end-to-end
- ✅ Can enroll student photos
- ✅ Attendance recorded automatically
- ✅ Parent receives SMS notification
- ✅ System handles network failures gracefully

---

### Phase 2: Build Missing Endpoints (Week 1 - 30 hours)

**Priority 1: Attendance Endpoints** (12 hours)

1. **GET /api/v1/attendance/today** (2 hours)
   - Get today's attendance summary
   - Return present count, absent count, rate
   - Real-time updates via WebSocket
   - Cache for 30 seconds

2. **POST /api/v1/attendance/verify** (4 hours)
   - Verify or reject detected attendance
   - Accept approval/rejection with reason
   - Update database
   - Notify parent if changed
   - Log audit trail

3. **GET /api/v1/attendance/history** (2 hours)
   - Get attendance history for student
   - Filter by date range
   - Pagination (20 records per page)
   - Sort by date

4. **POST /api/v1/attendance/export** (2 hours)
   - Export attendance to PDF/Excel
   - For date range
   - Async job (return job ID)
   - Store file for download

5. **GET /api/v1/attendance/stats** (2 hours)
   - Get attendance statistics
   - Present/absent counts
   - Weekly/monthly trends
   - Per-class statistics

**Priority 2: Camera Endpoints** (8 hours)

1. **GET /api/v1/cameras/health** (3 hours)
   - Check all cameras are online
   - Get last frame timestamp
   - FPS and resolution
   - Connection status
   - Return before/after for comparison

2. **POST /api/v1/cameras/{id}/restart** (2 hours)
   - Restart camera connection
   - Update status
   - Log restart reason

3. **GET /api/v1/cameras/{id}/stream** (2 hours)
   - Get MJPEG stream URL
   - Validate authentication
   - Rate limit (1 per IP per 5s)
   - Return 404 if offline

4. **GET /api/v1/cameras/stats** (1 hour)
   - Bandwidth usage
   - Uptime statistics
   - Frame drop rate

**Priority 3: Notification Endpoints** (10 hours)

1. **GET /api/v1/notifications/status** (3 hours)
   - Get notification delivery status
   - For date range
   - Filter by type (SMS/Email/Push)
   - Return success/failed counts

2. **POST /api/v1/notifications/preferences** (4 hours)
   - Update notification preferences per user
   - SMS enabled/disabled
   - Email enabled/disabled
   - Push enabled/disabled
   - Do not disturb hours
   - Validate changes

3. **GET /api/v1/notifications/failed** (2 hours)
   - List failed notifications
   - For admin dashboard
   - Return reason for failure
   - Pagination

4. **POST /api/v1/notifications/retry** (1 hour)
   - Manually retry failed notification
   - Admin only
   - Return status

**Success Criteria**:
- ✅ All endpoints working
- ✅ Error handling implemented
- ✅ Input validation in place
- ✅ Documentation complete
- ✅ Integration tests written

---

### Phase 3: Implement Error Handling & Observability (Week 2 - 25 hours)

**Error Handling** (10 hours)

1. **Custom Exception Classes** (2 hours)
   ```python
   class AttendanceError(Exception): pass
   class FaceRecognitionError(Exception): pass
   class NotificationError(Exception): pass
   class CameraError(Exception): pass
   class ValidationError(Exception): pass
   ```

2. **Global Error Handler** (3 hours)
   - Catch all exceptions
   - Return structured error response
   - Include error ID for tracking
   - Log stack trace
   - Don't expose internal details

   ```python
   @app.exception_handler(Exception)
   async def general_exception_handler(request, exc):
       error_id = str(uuid.uuid4())
       logger.error(f"Error {error_id}: {exc}", exc_info=True)
       return JSONResponse(
           status_code=500,
           content={
               "success": False,
               "error": "internal_error",
               "message": "Something went wrong",
               "error_id": error_id
           }
       )
   ```

3. **Specific Error Handlers** (3 hours)
   - Validation errors (400)
   - Authentication errors (401)
   - Authorization errors (403)
   - Not found errors (404)
   - Conflict errors (409)
   - Rate limit errors (429)
   - Server errors (500)

4. **Retry Logic** (2 hours)
   - Exponential backoff for external APIs
   - Circuit breaker for CompreFace
   - Timeout handling
   - Graceful degradation

**Observability** (15 hours)

1. **Logging** (5 hours)
   - Structured logging (JSON format)
   - Log levels (DEBUG, INFO, WARNING, ERROR)
   - Request/response logging
   - Correlation IDs for tracing
   - Sensitive data masking

   ```python
   import structlog
   
   logger = structlog.get_logger()
   
   @app.middleware("http")
   async def logging_middleware(request, call_next):
       request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
       structlog.contextvars.clear_contextvars()
       structlog.contextvars.bind_contextvars(request_id=request_id)
       
       logger.info("request_start", method=request.method, path=request.url.path)
       response = await call_next(request)
       logger.info("request_end", status_code=response.status_code)
       
       return response
   ```

2. **Metrics** (5 hours)
   - API response time (histogram)
   - Request count (counter)
   - Error count (counter)
   - Database query time (histogram)
   - Face recognition latency (histogram)
   - Notification delivery time (histogram)
   - System resources (CPU, memory, disk)

   ```python
   from prometheus_client import Counter, Histogram
   
   request_count = Counter("requests_total", "Total requests", ["method", "endpoint"])
   request_duration = Histogram("request_duration_seconds", "Request duration")
   
   @app.middleware("http")
   async def metrics_middleware(request, call_next):
       with request_duration.time():
           response = await call_next(request)
       request_count.labels(method=request.method, endpoint=request.url.path).inc()
       return response
   ```

3. **Health Checks** (3 hours)
   - Database connectivity
   - Redis connectivity
   - CompreFace availability
   - Twilio API status
   - Resend API status
   - Disk space

   ```python
   @app.get("/health")
   async def health_check():
       return {
           "status": "healthy",
           "checks": {
               "database": await check_database(),
               "redis": await check_redis(),
               "compreface": await check_compreface(),
               "disk_space": get_disk_space()
           }
       }
   ```

4. **Alerting** (2 hours)
   - High error rate (>5%)
   - API latency (>1s)
   - Service down
   - Disk space low (<10GB)
   - Database connection failing

**Success Criteria**:
- ✅ Comprehensive error handling
- ✅ Structured logging
- ✅ Metrics exposed
- ✅ Health checks working
- ✅ Alerts configured

---

### Phase 4: Security & Reliability (Week 3 - 25 hours)

**Security** (12 hours)

1. **Input Validation** (4 hours)
   - Validate all user inputs
   - Sanitize file uploads
   - Prevent SQL injection
   - Prevent XSS
   - Rate limiting on auth endpoints

   ```python
   from pydantic import BaseModel, EmailStr, Field
   
   class StudentCreate(BaseModel):
       name: str = Field(..., min_length=1, max_length=100)
       email: EmailStr
       phone: str = Field(..., regex=r"^\+?1?\d{9,15}$")
   ```

2. **Authentication & Authorization** (3 hours)
   - Validate JWT tokens
   - Check token expiration
   - Refresh token mechanism
   - Role-based access control
   - Audit logging for sensitive operations

3. **Data Protection** (3 hours)
   - Hash passwords securely
   - Encrypt sensitive fields (API keys)
   - HTTPS everywhere
   - CORS configuration
   - CSRF protection if needed

4. **API Security** (2 hours)
   - Rate limiting (100 req/min per IP)
   - API key rotation
   - Request signing for critical endpoints
   - IP whitelist for admin endpoints
   - DDoS protection (Cloudflare)

**Reliability** (13 hours)

1. **Database Reliability** (4 hours)
   - Connection pooling
   - Automatic reconnection
   - Query timeout (30s)
   - Transaction handling
   - Deadlock recovery

   ```python
   from sqlalchemy.pool import QueuePool
   
   engine = create_async_engine(
       DATABASE_URL,
       poolclass=QueuePool,
       pool_size=10,
       max_overflow=20,
       pool_pre_ping=True,
       echo=False
   )
   ```

2. **External API Resilience** (4 hours)
   - Timeout handling (10s)
   - Retry logic with exponential backoff
   - Circuit breaker pattern
   - Fallback strategies
   - Error rate monitoring

   ```python
   from tenacity import retry, stop_after_attempt, wait_exponential
   
   @retry(
       stop=stop_after_attempt(3),
       wait=wait_exponential(multiplier=1, min=1, max=10)
   )
   async def call_compreface(image_data):
       # Call CompreFace with retry
       pass
   ```

3. **Cache Strategy** (3 hours)
   - Redis for session storage
   - Cache attendance stats (5 min)
   - Cache camera status (1 min)
   - Cache user data (10 min)
   - Invalidate on updates

4. **Graceful Degradation** (2 hours)
   - If CompreFace down: Mark as pending, require manual verification
   - If notification service down: Queue and retry
   - If database slow: Return cached data
   - If camera offline: Show last frame + timestamp

**Success Criteria**:
- ✅ Input validation comprehensive
- ✅ Security audit passed
- ✅ Reliability tested under load
- ✅ Graceful degradation working
- ✅ All sensitive data protected

---

### Phase 5: Testing & Documentation (Week 4 - 20 hours)

**Integration Tests** (10 hours)

1. **Attendance Flow** (3 hours)
   - Mark attendance
   - Verify attendance
   - Reject attendance
   - Export attendance

2. **Face Recognition Flow** (3 hours)
   - Enroll student face
   - Detect face in camera
   - Match with enrolled face
   - Handle no match

3. **Notification Flow** (2 hours)
   - Send SMS
   - Send Email
   - Handle failure
   - Retry mechanism

4. **Camera Flow** (2 hours)
   - Connect to camera
   - Get MJPEG stream
   - Record video clip
   - Handle disconnect

**End-to-End Tests** (4 hours)

1. **Complete Attendance Cycle**
   - Student walks in front of camera
   - Face recognized
   - Attendance recorded
   - Parent notified
   - Visible in dashboard

2. **Error Scenarios**
   - CompreFace down
   - Notification service down
   - Database connection lost
   - Camera offline

**Documentation** (6 hours)

1. **API Documentation** (3 hours)
   - OpenAPI/Swagger spec
   - All endpoints documented
   - Request/response examples
   - Error codes explained
   - Authentication requirements

2. **Setup Guide** (2 hours)
   - Environment variables
   - Database setup
   - CompreFace setup
   - Twilio setup
   - Resend setup
   - Redis setup

3. **Operations Guide** (1 hour)
   - Deployment steps
   - Monitoring setup
   - Troubleshooting guide
   - Support procedures

**Success Criteria**:
- ✅ All tests passing
- ✅ API docs complete
- ✅ Setup guide written
- ✅ Operations guide written
- ✅ Ready for production

---

## API Specification Summary

### Authentication
```
POST /api/v1/auth/login
- Request: email, password
- Response: access_token, refresh_token, user_data

POST /api/v1/auth/refresh
- Request: refresh_token
- Response: new_access_token
```

### Students
```
POST /api/v1/students/ (Admin only)
GET /api/v1/students/
GET /api/v1/students/{id}
PUT /api/v1/students/{id}
DELETE /api/v1/students/{id}

POST /api/v1/students/{id}/enroll-face
GET /api/v1/students/{id}/attendance
```

### Attendance
```
POST /api/v1/attendance/mark
- Request: student_id, face_image OR manual_mark
- Response: attendance_record

GET /api/v1/attendance/today
GET /api/v1/attendance/history
GET /api/v1/attendance/{id}
POST /api/v1/attendance/{id}/verify
POST /api/v1/attendance/export
GET /api/v1/attendance/stats
```

### Cameras
```
POST /api/v1/cameras/ (Admin only)
GET /api/v1/cameras/
GET /api/v1/cameras/{id}
PUT /api/v1/cameras/{id}
DELETE /api/v1/cameras/{id}

GET /api/v1/cameras/{id}/stream
GET /api/v1/cameras/health
GET /api/v1/cameras/stats
```

### Notifications
```
POST /api/v1/notifications/
GET /api/v1/notifications/status
POST /api/v1/notifications/preferences
GET /api/v1/notifications/failed
POST /api/v1/notifications/{id}/retry
```

### Reports
```
GET /api/v1/reports/attendance
GET /api/v1/reports/analytics
POST /api/v1/reports/export
```

### Health & Admin
```
GET /health
GET /api/v1/health
GET /api/v1/metrics
```

---

## Critical Success Factors

### 1. Data Integrity
- Every attendance record has audit trail
- No lost data on failure
- Transactions for multi-step operations
- Backup system operational

### 2. Error Resilience
- Transient failures automatically retried
- Permanent failures handled gracefully
- Clear error messages to clients
- Logging for debugging

### 3. Security
- Input validation on all endpoints
- Authentication required
- Authorization checked
- Sensitive data protected
- Rate limiting in place

### 4. Performance
- API response time <500ms (p99)
- Database queries optimized (indexes)
- Caching strategy implemented
- Batch operations where possible

### 5. Observability
- Structured logging
- Metrics exposed
- Health checks working
- Alerts configured
- Tracing for debugging

---

## Implementation Checklist

### Phase 1: Critical Fixes
- [ ] CompreFace API key fixed
- [ ] Face enrollment endpoint working
- [ ] Notification retry implemented
- [ ] Environment validation added
- [ ] End-to-end test passing

### Phase 2: Missing Endpoints
- [ ] Attendance endpoints complete
- [ ] Camera endpoints complete
- [ ] Notification endpoints complete
- [ ] All endpoints tested
- [ ] Documentation updated

### Phase 3: Error Handling & Observability
- [ ] Custom exceptions defined
- [ ] Global error handler implemented
- [ ] Structured logging working
- [ ] Metrics exposed
- [ ] Health checks passing

### Phase 4: Security & Reliability
- [ ] Input validation comprehensive
- [ ] Authentication working
- [ ] Authorization enforced
- [ ] Database resilient
- [ ] External APIs resilient

### Phase 5: Testing & Deployment
- [ ] Integration tests written and passing
- [ ] E2E tests written and passing
- [ ] API documentation complete
- [ ] Setup guide written
- [ ] Operations guide written

---

## Deployment Checklist

Before shipping to first school:

### Configuration
- [ ] All environment variables present
- [ ] No hardcoded secrets
- [ ] Database backups scheduled
- [ ] Redis persistence enabled
- [ ] CompreFace volume mounted

### Security
- [ ] HTTPS enforced
- [ ] API keys rotated
- [ ] Secrets encrypted
- [ ] Rate limiting configured
- [ ] CORS properly configured

### Monitoring
- [ ] Health checks working
- [ ] Metrics collection working
- [ ] Logging centralized
- [ ] Alerts configured
- [ ] Backup verified

### Testing
- [ ] All endpoints tested
- [ ] Error scenarios tested
- [ ] Load tested (100 concurrent users)
- [ ] Offline mode tested
- [ ] Backup/restore tested

### Documentation
- [ ] API docs complete
- [ ] Setup guide complete
- [ ] Troubleshooting guide complete
- [ ] Operations guide complete
- [ ] Support procedures documented

---

## Timeline Summary

| Week | Focus | Hours | Deliverable |
|------|-------|-------|-------------|
| 1 | Critical fixes + Missing endpoints | 50 | Working API with all endpoints |
| 2 | Error handling + Observability | 25 | Robust error handling and logging |
| 3 | Security + Reliability | 25 | Secure, resilient system |
| 4 | Testing + Deployment | 20 | Production-ready, documented |
| **Total** | | **120** | **Production-ready backend** |

---

## Key Reminders

1. **Fix blockers first** - Face recognition is broken, fix it immediately
2. **Handle errors gracefully** - Users shouldn't see 500 errors
3. **Log everything** - You'll need logs to debug production issues
4. **Test thoroughly** - Write tests as you go
5. **Document as you go** - Don't leave documentation for the end
6. **Monitor from day one** - You can't manage what you can't measure
7. **Think about failures** - Design for failure, not success
8. **Protect user data** - Validate input, encrypt sensitive data
9. **Make it observable** - Logs, metrics, health checks
10. **Be paranoid** - Assume things will fail and design accordingly

---

**Build it right. Build it resilient. Build it observable.**

