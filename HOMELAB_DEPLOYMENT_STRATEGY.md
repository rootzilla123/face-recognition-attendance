# Homelab Deployment Strategy

## Business Model

**Deployment Type**: On-Premise Homelab with Remote Management

### What We Provide
- Physical server/homelab hardware to the school
- Pre-configured software stack (Docker-based)
- Remote management and support
- Updates and maintenance

### What School Provides
- Physical space for server
- Power supply
- Internet connection
- Day-to-day user management

### Revenue Model
- **Hardware**: $500-1500 one-time (server cost)
- **Software License**: $2000-5000 one-time
- **Monthly Support**: $99-299/month (remote management, updates, monitoring)

---

## Technical Architecture

### Current Status: 60-65% Ready for Prototype

**What Works**:
- ✅ Docker Compose deployment
- ✅ All services containerized
- ✅ Face recognition pipeline
- ✅ Attendance tracking
- ✅ Notifications (SMS/Email)
- ✅ Dashboard and mobile app
- ✅ Backup scripts
- ✅ Monitoring (Uptime Kuma)

**Critical Blockers** (3.5 hours to fix):
1. ❌ CompreFace API key invalid (5 min)
2. ❌ No face enrollment endpoint (2 hrs)
3. ❌ Notification retry missing (1 hr)
4. ❌ Environment validation missing (30 min)

---

## Prototype Readiness Plan

### Phase 1: Fix Critical Bugs (This Week - 3.5 hours)

**Priority 1: CompreFace API Key** ⏱️ 5 minutes
- Access CompreFace UI at http://localhost:8080
- Create Recognition Service (NOT Detection)
- Copy new API key to `.env`
- Restart backend

**Priority 2: Face Enrollment Endpoint** ⏱️ 2 hours
- Create `POST /api/v1/students/{id}/enroll-face`
- Accept photo upload
- Call CompreFace subject creation
- Store embedding ID in database

**Priority 3: Notification Retry** ⏱️ 1 hour
- Implement exponential backoff
- Store failed notifications
- Background job for retry

**Priority 4: Environment Validation** ⏱️ 30 minutes
- Startup validation for critical vars
- Fail fast if CHANGE_ME values present
- Clear error messages

---

### Phase 2: Homelab Deployment Package (Next Week - 8 hours)

**1. Installation Script** ⏱️ 2 hours
```bash
# install.sh - One-command setup
curl -sSL https://yoursite.com/install.sh | bash
```
- Install Docker
- Pull all images
- Generate secure passwords
- Start all services
- Print access URLs

**2. Cloudflare Tunnel Setup** ⏱️ 1 hour
- Expose dashboard: `https://school1.yourapp.com`
- Expose API: `https://api-school1.yourapp.com`
- Remote access without VPN

**3. Remote Monitoring** ⏱️ 2 hours
- Uptime Kuma alerts to your email
- Health check endpoints
- Auto-restart on failure

**4. Setup Wizard** ⏱️ 4 hours
- First-time configuration page
- School admin account creation
- Camera setup
- Notification configuration
- Face recognition test

---

### Phase 3: First School Deployment (Week 3)

**Deployment Process**:
1. Buy/build homelab server (or repurpose old PC)
2. Install Ubuntu Server
3. Run installation script
4. Configure Cloudflare Tunnel
5. Ship server to school
6. School plugs in: power + ethernet + cameras
7. Remote configuration via Cloudflare Tunnel
8. School admin completes setup wizard
9. Training and go-live

---

## Minimum Viable Prototype Requirements

### Must Work for Demo
1. ✅ Student walks in front of camera
2. ✅ Face recognized by CompreFace (<0.5s)
3. ✅ Attendance recorded in database
4. ✅ Parent receives SMS/Email notification
5. ✅ Dashboard shows real-time attendance
6. ✅ System handles 50+ concurrent users

### Can Skip for Prototype
- ❌ Multi-tenancy (each school has own server)
- ❌ Billing integration (manual invoicing)
- ❌ SaaS infrastructure
- ❌ Cloud hosting
- ❌ 2FA/MFA
- ❌ GDPR compliance
- ❌ Advanced analytics
- ❌ iOS app (Android APK sufficient)

---

## Remote Management Strategy

### Access Methods
1. **Cloudflare Tunnel** - HTTPS access to dashboard/API
2. **SSH** - Direct server access for debugging
3. **Monitoring Dashboard** - Uptime Kuma for health checks

### Auto-Recovery Features
- Docker restart policies (already configured)
- Watchdog service for crashed services
- Auto-reboot on kernel panic
- Daily automated backups
- Health check monitoring

### Support Workflow
1. School reports issue
2. You check monitoring dashboard
3. Remote access via Cloudflare Tunnel
4. Fix issue or SSH in for debugging
5. Update documentation

---

## Success Criteria

### Prototype Ready When:
1. ✅ Can ship server to school
2. ✅ School plugs in (power + internet)
3. ✅ Remote access via Cloudflare Tunnel works
4. ✅ School admin completes setup wizard
5. ✅ Face recognition works end-to-end
6. ✅ Can monitor/fix issues remotely
7. ✅ System runs for 7 days without intervention

### Production Ready When:
1. ✅ All prototype criteria met
2. ✅ Automated backups deployed
3. ✅ Load tested with 100+ users
4. ✅ Video clips backed up to cloud
5. ✅ Centralized logging (Loki)
6. ✅ Complete API documentation
7. ✅ Security audit passed
8. ✅ Disaster recovery tested

---

## Timeline Estimate

### Week 1: Critical Fixes
- Fix 4 critical bugs (3.5 hrs)
- Test end-to-end flow (2 hrs)
- **Total: 5.5 hours**

### Week 2: Deployment Package
- Installation script (2 hrs)
- Cloudflare Tunnel (1 hr)
- Remote monitoring (2 hrs)
- Setup wizard (4 hrs)
- Testing (3 hrs)
- **Total: 12 hours**

### Week 3: First School Deployment
- Server preparation (4 hrs)
- Shipping and setup (1 day)
- Remote configuration (2 hrs)
- Training (2 hrs)
- **Total: 8 hours + shipping time**

### Week 4: Production Hardening
- Automated backups (1 hr)
- Load testing (4 hrs)
- Security audit (4 hrs)
- Documentation (3 hrs)
- **Total: 12 hours**

**Total Development Time: ~37.5 hours**

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| CompreFace fails under load | CRITICAL | Load test early, add manual fallback |
| Parents don't receive notifications | HIGH | Add retry + delivery tracking |
| Data loss | CRITICAL | Deploy backup system immediately |
| System crashes at school | HIGH | Health monitoring + auto-restart |
| Face recognition accuracy low | MEDIUM | Tune threshold, add manual override |
| Remote access blocked | HIGH | Multiple access methods (Cloudflare + SSH) |
| Hardware failure | MEDIUM | Spare server + quick replacement process |

---

## Next Steps

### Immediate Actions (Today)
1. Fix CompreFace API key (5 min)
2. Add face enrollment endpoint (2 hrs)
3. Add notification retry (1 hr)
4. Add environment validation (30 min)

### This Week
5. Create installation script (2 hrs)
6. Setup Cloudflare Tunnel (1 hr)
7. Add remote monitoring (2 hrs)
8. Build setup wizard (4 hrs)

### Next Week
9. Test on fresh Ubuntu install (2 hrs)
10. Deploy to first school
11. Monitor and iterate

---

## Future Enhancements (Post-Launch)

### Month 2-3
- Centralized logging (Loki)
- Advanced analytics dashboard
- Mobile app improvements
- Video clip cloud backup

### Month 4-6
- 2FA for admin accounts
- GDPR compliance features
- Multi-language support
- Custom branding per school

### Month 6+
- SaaS option for small schools
- API for third-party integrations
- Advanced reporting
- AI-powered insights

---

## Notes

- This strategy focuses on **on-premise deployment** with **remote management**
- Each school gets their own isolated server
- Data stays on school premises (privacy)
- You maintain remote access for support
- SaaS model can be added later if needed
- Current codebase is well-suited for this model
