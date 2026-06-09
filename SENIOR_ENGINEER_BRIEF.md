# Senior Software Engineer Brief: Attendance System Prototype

## Executive Summary

You've been brought in as a senior software engineer to take a partially-built attendance system from 60% to production-ready for the first school deployment. The system has solid backend infrastructure but critical gaps in frontend applications and deployment readiness. Your job is to fix the blockers, complete the core applications, and ensure the system is reliable enough for a school to depend on.

**Timeline**: 4-5 weeks to working prototype
**Deployment Model**: Homelab on-premise with remote management
**First School**: Ready to deploy in 4 weeks

---

## Current State

### ✅ What Works
- **Backend API** (FastAPI): 70% complete, core attendance flow implemented
- **Database** (PostgreSQL): Schema complete, migrations working
- **Face Recognition** (CompreFace): Integrated but API key invalid
- **Notifications** (Twilio + Resend): Implemented but retry logic missing
- **Video Streaming** (MJPEG): Working, 10-second clips captured
- **Docker/Kubernetes**: Configured, ready for deployment
- **Monitoring** (Uptime Kuma): Configured, health checks in place
- **Backup System**: Scripts created, not deployed

### ❌ Critical Blockers (3.5 hours to fix)
1. **CompreFace API Key Invalid** (5 min)
   - Current key doesn't exist
   - Face recognition completely broken
   - Fix: Create Recognition Service in CompreFace UI, update .env

2. **No Face Enrollment Endpoint** (2 hrs)
   - Students can't upload photos for face recognition
   - System is unusable without this
   - Fix: Create POST /api/v1/students/{id}/enroll-face endpoint

3. **Notification Retry Missing** (1 hr)
   - Failed SMS/Email not retried
   - Parents don't receive alerts
   - Fix: Add exponential backoff retry logic

4. **Environment Validation Missing** (30 min)
   - System starts with invalid config
   - Fails silently in production
   - Fix: Add startup validation, fail fast on bad config

### ❌ Major Gaps (160-200 hours to complete)
- **Admin Dashboard** (Web): 20% complete, needs real-time monitoring
- **Mobile App** (Flutter): 40% complete, needs notification handling
- **Desktop App** (Flutter): 5% complete, needs entire application

---

## Architecture Overview

### Three Separate Applications

**1. Admin Dashboard (Web - Next.js)**
- Purpose: School admin monitors and manages system
- Users: School Admin, Principal
- Features: System health, real-time attendance, camera management, user management, alerts, reports
- Status: 20% complete (skeleton exists)
- Estimated: 40-50 hours to complete

**2. Mobile App (Flutter)**
- Purpose: Students/parents view attendance and receive notifications
- Users: Students, Parents
- Platforms: iOS, Android, Web
- Features: Attendance history, notifications, preferences, offline mode
- Status: 40% complete (structure exists)
- Estimated: 30-40 hours to complete

**3. Desktop App (Flutter)**
- Purpose: Teachers verify attendance and manage classes
- Users: Teachers
- Platforms: Windows, Linux, macOS
- Features: Live camera feed, attendance verification, manual marking, offline mode
- Status: 5% complete (build scripts only)
- Estimated: 50-60 hours to complete

### Deployment Model

**Homelab On-Premise with Remote Management**:
- You provide physical server to school
- School provides: power + internet + physical space
- You manage remotely via Cloudflare Tunnel
- Each school has isolated server (no multi-tenancy)
- Data stays on-premise (privacy)

---

## Your Mission

### Phase 1: Fix Critical Blockers (This Week - 3.5 hours)
**Goal**: Get face recognition working end-to-end

**Tasks**:
1. Fix CompreFace API key (5 min)
   - Access CompreFace UI
   - Create Recognition Service (NOT Detection)
   - Copy new key to .env
   - Restart backend
   - Verify face recognition works

2. Add face enrollment endpoint (2 hrs)
   - Create POST /api/v1/students/{id}/enroll-face
   - Accept photo upload
   - Validate photo quality (face detected, not blurry)
   - Call CompreFace to create subject
   - Store embedding ID in database
   - Return clear error messages

3. Add notification retry (1 hr)
   - Distinguish permanent vs transient failures
   - Implement exponential backoff (1s, 2s, 4s)
   - Store failed notifications for manual review
   - Don't retry permanent failures (invalid key, bad phone)
   - Retry transient failures (network timeout, 5xx errors)

4. Add environment validation (30 min)
   - Validate required vars exist at startup
   - Check format (URLs, UUIDs, phone numbers)
   - Test connectivity (database, CompreFace, Twilio)
   - Fail fast with clear error messages
   - Document all required environment variables

**Success Criteria**:
- ✅ Face recognition works end-to-end
- ✅ Can enroll student photos
- ✅ Attendance recorded automatically
- ✅ Parent receives SMS notification
- ✅ System handles network failures gracefully

---

### Phase 2: Admin Dashboard (Week 1 - 40-50 hours)
**Goal**: School admin can monitor system remotely

**Must-Have Features**:
1. System Health Dashboard
   - CPU, memory, disk usage
   - Service status (API, Database, CompreFace, Redis)
   - Network connectivity
   - Last successful face recognition
   - Real-time updates via WebSocket

2. Real-Time Attendance Counter
   - Students present today
   - Students absent today
   - Attendance rate (%)
   - Live updates as students arrive

3. Camera Management
   - List all cameras
   - Camera status (online/offline)
   - Last frame captured
   - Stream health (FPS, resolution)
   - Add/remove cameras

4. User Management
   - List all users (teachers, students, parents)
   - Add/remove users
   - Assign roles
   - Reset passwords
   - View user activity

5. Alerts & Notifications
   - System alerts (service down, disk full, etc.)
   - Notification delivery status
   - Failed notifications (for retry)
   - Alert history

6. Basic Reports
   - Daily attendance report
   - Weekly attendance trends
   - Camera usage statistics
   - System uptime

**Technical Requirements**:
- Real-time updates via WebSocket
- Responsive design (desktop + tablet)
- Dark/light theme
- Clear error messages
- Graceful degradation (works if services down)

**Success Criteria**:
- ✅ Admin can see system health in real-time
- ✅ Admin can see live attendance counter
- ✅ Admin can manage users and cameras
- ✅ Admin receives alerts for issues
- ✅ System works remotely via Cloudflare Tunnel

---

### Phase 3: Mobile App (Week 2 - 30-40 hours)
**Goal**: Students/parents can view attendance and receive notifications

**Must-Have Features**:
1. Attendance History
   - List of all attendance records
   - Date, time, status (present/absent)
   - Filter by date range
   - Search functionality

2. Notification Display
   - Show all received notifications
   - Mark as read/unread
   - Delete notifications
   - Notification preferences (SMS/Email/Push)

3. Student Profile
   - View own profile
   - Edit preferences
   - View enrolled face photo
   - Change password

4. Parent Features
   - View child's attendance
   - Manage multiple children
   - Set notification preferences per child

5. Offline Mode
   - Cache attendance data locally
   - Show cached data when offline
   - Sync when back online
   - Clear indication of offline status

**Technical Requirements**:
- Push notification handling (Firebase)
- Local caching (Shared Preferences)
- Offline-first architecture
- Dark/light theme
- Works on iOS, Android, Web

**Success Criteria**:
- ✅ Can view attendance history
- ✅ Receives push notifications
- ✅ Works offline with cached data
- ✅ Syncs when back online
- ✅ Preferences persist

---

### Phase 4: Desktop App (Week 3 - 50-60 hours)
**Goal**: Teachers can verify attendance and manage classes

**Must-Have Features**:
1. Real-Time Camera Feed
   - Display live MJPEG stream
   - Multiple camera support
   - Full-screen mode
   - Zoom/pan controls

2. Attendance Verification
   - Show detected faces
   - Approve/reject attendance
   - Manual override
   - Reason for rejection

3. Manual Attendance Marking
   - Search student by name/ID
   - Mark present/absent
   - Bulk marking
   - Undo functionality

4. Class Management
   - View class roster
   - Filter by class
   - View attendance summary
   - Export attendance

5. Offline Mode
   - Cache class data locally
   - Mark attendance offline
   - Sync when back online
   - Conflict resolution

**Technical Requirements**:
- System tray integration
- Keyboard shortcuts
- Offline-first architecture
- Auto-sync when online
- Works on Windows, Linux, macOS

**Success Criteria**:
- ✅ Can see live camera feed
- ✅ Can verify/reject attendance
- ✅ Can mark attendance manually
- ✅ Works offline
- ✅ Syncs when back online

---

## Critical Success Factors

### 1. Reliability Over Features
- System must not crash
- Auto-recovery from failures
- Clear error messages
- Graceful degradation

### 2. Remote Manageability
- You can access system remotely
- You can restart services
- You can view logs
- You can diagnose issues

### 3. Support Call Reduction
- Auto-recovery from transient failures
- Clear status indicators
- Health monitoring dashboard
- Proactive alerts

### 4. Offline Capability
- Mobile app works offline
- Desktop app works offline
- Data syncs when back online
- No data loss

### 5. Security
- Environment validation (no hardcoded secrets)
- Secure API key management
- HTTPS everywhere
- Rate limiting on auth endpoints

---

## Technical Decisions You Need to Make

### 1. Admin Dashboard
- **Question**: Real-time updates via WebSocket or polling?
- **Recommendation**: WebSocket for low latency, fallback to polling
- **Question**: How often to refresh metrics?
- **Recommendation**: 5-second intervals for health, 1-second for attendance

### 2. Mobile App
- **Question**: Offline-first or online-first?
- **Recommendation**: Offline-first (cache everything, sync on change)
- **Question**: How much data to cache?
- **Recommendation**: Last 30 days of attendance + current settings

### 3. Desktop App
- **Question**: Electron or Flutter Desktop?
- **Recommendation**: Flutter Desktop (consistent with mobile app)
- **Question**: How to handle camera stream?
- **Recommendation**: MJPEG over HTTP (no special codecs needed)

### 4. Error Handling
- **Question**: How to distinguish permanent vs transient failures?
- **Recommendation**: HTTP status codes (4xx = permanent, 5xx = transient)
- **Question**: How many retries?
- **Recommendation**: 3 retries with exponential backoff

### 5. Monitoring
- **Question**: What metrics to track?
- **Recommendation**: CPU, memory, disk, service status, API latency, notification delivery
- **Question**: Alert thresholds?
- **Recommendation**: CPU >80%, Memory >85%, Disk >90%, Service down, API latency >1s

---

## Deployment Checklist

Before shipping to first school:

### Environment Validation
- [ ] All required environment variables present
- [ ] No "CHANGE_ME" values in production config
- [ ] API keys are valid and tested
- [ ] Database is accessible
- [ ] CompreFace is accessible
- [ ] Twilio/Resend credentials work

### System Health
- [ ] All services start successfully
- [ ] Health check endpoints respond
- [ ] WebSocket connections work
- [ ] Database migrations complete
- [ ] Backup system operational

### Feature Testing
- [ ] Face recognition works end-to-end
- [ ] Attendance recorded correctly
- [ ] Notifications sent and received
- [ ] Admin dashboard shows real-time data
- [ ] Mobile app displays attendance
- [ ] Desktop app shows camera feed

### Reliability Testing
- [ ] System recovers from service crash
- [ ] System recovers from network failure
- [ ] Notifications retry on failure
- [ ] Offline mode works
- [ ] Data syncs correctly

### Security Testing
- [ ] HTTPS enforced
- [ ] API keys not exposed
- [ ] Secrets not in logs
- [ ] Rate limiting works
- [ ] Authentication required

### Documentation
- [ ] Installation guide complete
- [ ] Configuration guide complete
- [ ] Troubleshooting guide complete
- [ ] API documentation complete
- [ ] User guides for each app

---

## Success Metrics

### Week 1 (Critical Fixes + Admin Dashboard)
- ✅ Face recognition working
- ✅ Admin dashboard shows system health
- ✅ Real-time attendance counter working
- ✅ Can manage users and cameras
- ✅ Alerts working

### Week 2 (Mobile App)
- ✅ Mobile app shows attendance history
- ✅ Notifications working
- ✅ Offline mode working
- ✅ Preferences persist

### Week 3 (Desktop App)
- ✅ Desktop app shows camera feed
- ✅ Attendance verification working
- ✅ Manual marking working
- ✅ Offline mode working

### Week 4 (Testing + Deployment)
- ✅ All systems tested
- ✅ Documentation complete
- ✅ Ready for first school deployment
- ✅ Support procedures documented

---

## What You Should NOT Do

❌ Don't add features beyond MVP
❌ Don't optimize prematurely
❌ Don't skip error handling
❌ Don't hardcode configuration
❌ Don't skip testing
❌ Don't ignore security
❌ Don't build without documentation
❌ Don't assume things work (test everything)

---

## What You SHOULD Do

✅ Fix blockers first
✅ Build incrementally
✅ Test as you go
✅ Document decisions
✅ Handle errors gracefully
✅ Make things observable (logs, metrics)
✅ Assume things will fail (design for recovery)
✅ Think about the school admin (reduce support calls)

---

## Resources

### Documentation
- `HOMELAB_DEPLOYMENT_STRATEGY.md` - Deployment model and strategy
- `APP_ARCHITECTURE_AUDIT.md` - Three applications breakdown
- `CRITICAL_FIXES_IMPLEMENTED.md` - What's already been fixed
- `COMPREFACE_SETUP.md` - Face recognition setup
- `CAMERA_SETUP_GUIDE.md` - Camera configuration

### Code Locations
- Backend API: `attendance-system/app/main.py`
- Database Models: `attendance-system/app/models.py`
- Face Recognition: `attendance-system/app/services/face_recognition.py`
- Notifications: `attendance-system/app/services/notification_service.py`
- Admin Dashboard: `attendance-dashboard/app/`
- Mobile App: `mobile_app/lib/`
- Docker: `attendance-system/Dockerfile`, `attendance-dashboard/Dockerfile`
- Kubernetes: `k8s/base/`, `k8s/production/`

### External Services
- CompreFace: http://localhost:8080 (local) or configured URL
- Twilio: SMS notifications
- Resend: Email notifications
- Firebase: Push notifications
- Cloudflare Tunnel: Remote access

---

## Questions to Ask Before Starting

1. **What's the first school's size?** (affects load testing)
2. **How many cameras?** (affects bandwidth)
3. **What's the internet speed?** (affects streaming quality)
4. **Do they have IT staff?** (affects support model)
5. **What's the timeline?** (affects priority)
6. **What's the budget?** (affects infrastructure)
7. **What's the success criteria?** (affects testing)

---

## Final Notes

- This is a **prototype for the first school**, not a production SaaS platform
- Focus on **reliability and support reduction**, not features
- Every decision should be made with **"will this cause support calls?"** in mind
- **Test everything** - assume nothing works until proven
- **Document everything** - you won't remember why you made decisions
- **Fail fast** - catch errors early, not in production
- **Think like a school admin** - what would make your life easier?

You've got this. The foundation is solid. Now make it bulletproof.

---

## Timeline Summary

| Week | Focus | Hours | Deliverable |
|------|-------|-------|-------------|
| 1 | Critical fixes + Admin Dashboard | 50 | Working face recognition + monitoring |
| 2 | Mobile App | 40 | Attendance history + notifications |
| 3 | Desktop App | 60 | Camera feed + verification |
| 4 | Testing + Deployment | 50 | Production-ready system |
| **Total** | | **200** | **First school deployment** |

---

**You're the senior engineer now. Make it right.**
