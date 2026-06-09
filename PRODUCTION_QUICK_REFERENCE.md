# Production Quick Reference Card

## 🚨 Emergency Contacts & Procedures

### System Down
```bash
# Check all services
kubectl get pods -n production

# Check logs
kubectl logs -n production deploy/backend --tail=100

# Restart services
kubectl rollout restart -n production deploy/backend
kubectl rollout restart -n production deploy/dashboard
```

### Database Issues
```bash
# Check connections
curl https://shadomfacepro.duckdns.org/api/v1/metrics

# Restore from backup
./scripts/restore-backup.sh <timestamp> production
```

### Disk Full
```bash
# Check storage
curl -H "Authorization: Bearer $TOKEN" \
  https://shadomfacepro.duckdns.org/api/v1/health/storage

# Clean old clips
kubectl exec -n production deploy/backend -- \
  find /var/attendance_clips -mtime +7 -delete
```

## 📊 Monitoring URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Status Page | https://status.shadomfacepro.duckdns.org | Uptime monitoring |
| Health Check | https://shadomfacepro.duckdns.org/api/v1/health/detailed | Service health |
| Metrics | https://shadomfacepro.duckdns.org/api/v1/metrics | System metrics |
| Error Tracking | https://glitchtip.shadomfacepro.duckdns.org | Error logs |
| API Docs | https://shadomfacepro.duckdns.org/docs | API documentation |

## 🔐 Security Checklist

- [x] SECRET_KEY is secure (64+ chars)
- [x] Security headers enabled
- [x] HTTPS enforced
- [x] Rate limiting active
- [x] App version enforcement
- [ ] 2FA enabled for admins
- [ ] Penetration test completed
- [ ] Security audit done

## 💾 Backup & Recovery

### Create Backup
```bash
# Manual backup
./scripts/automated-backup.sh

# Check last backup
ls -lth backups/ | head -5
```

### Restore Backup
```bash
# List backups
ls -1 backups/

# Restore (CAUTION: overwrites data!)
./scripts/restore-backup.sh 20260430_020000 production
```

### Backup Schedule
- **Frequency**: Daily at 2 AM
- **Retention**: 30 days
- **Location**: `/backups` + S3 (if configured)
- **Verification**: Automatic

## 🔧 Common Tasks

### Deploy New Version
```bash
# Push to main branch triggers CI/CD
git push origin main

# Monitor deployment
kubectl rollout status -n production deploy/backend
kubectl rollout status -n production deploy/dashboard
```

### Run Database Migration
```bash
# Automatic on deploy, or manual:
kubectl exec -n production deploy/backend -- alembic upgrade head
```

### Scale Services
```bash
# Scale backend
kubectl scale -n production deploy/backend --replicas=3

# Scale dashboard
kubectl scale -n production deploy/dashboard --replicas=2
```

### View Logs
```bash
# Backend logs
kubectl logs -n production deploy/backend -f

# Dashboard logs
kubectl logs -n production deploy/dashboard -f

# All pods
kubectl logs -n production -l app=backend --tail=100
```

## 📱 Mobile App Management

### Update Minimum Version
Edit `attendance-system/app/routes/version.py`:
```python
MIN_ANDROID_VERSION = "1.1.0"
MIN_IOS_VERSION = "1.1.0"
```

### Check App Versions in Use
```bash
# Check logs for version headers
kubectl logs -n production deploy/backend | grep "X-App-Version"
```

## 🔔 Notification System

### Test Notifications
```bash
# Test SMS
curl -X POST https://shadomfacepro.duckdns.org/api/v1/notifications/test-sms \
  -H "Authorization: Bearer $TOKEN"

# Test Push
curl -X POST https://shadomfacepro.duckdns.org/api/v1/notifications/test-push \
  -H "Authorization: Bearer $TOKEN"
```

### Check Notification Status
```bash
# Failed notifications
kubectl exec -n production deploy/postgres -- \
  psql -U postgres attendance_db -c \
  "SELECT * FROM notifications WHERE status='failed' ORDER BY created_at DESC LIMIT 10;"
```

## 📈 Performance Monitoring

### Check System Resources
```bash
# CPU/Memory/Disk
curl -H "Authorization: Bearer $TOKEN" \
  https://shadomfacepro.duckdns.org/api/v1/metrics | jq '.system'

# Database connections
curl -H "Authorization: Bearer $TOKEN" \
  https://shadomfacepro.duckdns.org/api/v1/metrics | jq '.database.connections'
```

### Check Active Streams
```bash
# WebSocket connections
curl https://shadomfacepro.duckdns.org/api/v1/health | jq '.websocket_connections'

# Video streams
curl https://shadomfacepro.duckdns.org/api/v1/health | jq '.video_streaming'
```

## 🎯 Key Metrics to Watch

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Response Time | <200ms | 200-500ms | >500ms |
| Error Rate | <0.1% | 0.1-1% | >1% |
| Uptime | >99.9% | 99-99.9% | <99% |
| Disk Usage | <70% | 70-85% | >85% |
| Memory Usage | <70% | 70-85% | >85% |
| DB Connections | <50% | 50-80% | >80% |

## 🐛 Troubleshooting

### Backend Won't Start
```bash
# Check logs
kubectl logs -n production deploy/backend

# Common issues:
# - SECRET_KEY validation failed → Set secure key
# - Database migration failed → Check DB connectivity
# - Redis connection failed → Check Redis pod
```

### CompreFace Not Working
```bash
# Check CompreFace health
curl http://compreface-api:8080/api/v1/recognition/subjects

# Restart CompreFace
kubectl rollout restart -n production deploy/compreface-api
kubectl rollout restart -n production deploy/compreface-core
```

### Push Notifications Not Sending
```bash
# Check Firebase credentials
kubectl exec -n production deploy/backend -- \
  ls -la /app/firebase-service-account.json

# Check logs
kubectl logs -n production deploy/backend | grep -i firebase
```

### Chatbot Not Responding
```bash
# Check Ollama
curl http://ollama:11434/api/tags

# Check Redis (chat history)
kubectl exec -n production deploy/redis -- redis-cli KEYS "chatbot:*"

# Restart Ollama
kubectl rollout restart -n production deploy/ollama
```

## 📞 Escalation Path

1. **Check monitoring**: https://status.shadomfacepro.duckdns.org
2. **Check logs**: `kubectl logs -n production deploy/backend`
3. **Check health**: `curl .../api/v1/health/detailed`
4. **Restart service**: `kubectl rollout restart ...`
5. **Restore backup**: `./scripts/restore-backup.sh`
6. **Contact team**: Slack #production-alerts

## 🔄 Maintenance Windows

- **Backups**: Daily 2:00-2:15 AM (minimal impact)
- **Updates**: Sundays 2:00-4:00 AM
- **Database maintenance**: Monthly, first Sunday 3:00-5:00 AM

## 📝 Change Log Location

- **Backend**: `attendance-system/CHANGELOG.md`
- **Dashboard**: `attendance-dashboard/CHANGELOG.md`
- **Infrastructure**: `CHANGELOG.md`

## 🎓 Training Resources

- **API Docs**: https://shadomfacepro.duckdns.org/docs
- **Architecture**: `docs/ARCHITECTURE.md`
- **Deployment**: `docs/DEPLOYMENT.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`

## ⚡ Quick Commands

```bash
# Health check
curl https://shadomfacepro.duckdns.org/api/v1/health/detailed | jq

# Backup now
./scripts/automated-backup.sh

# Restart all
kubectl rollout restart -n production deploy/backend deploy/dashboard

# Scale up
kubectl scale -n production deploy/backend --replicas=3

# View metrics
kubectl top pods -n production

# Check disk
df -h

# Check memory
free -h

# Check processes
ps aux | grep python
```
