#!/usr/bin/env bash
# automated-backup.sh — Comprehensive backup script with retention and monitoring
# Schedule via cron: 0 2 * * * /path/to/scripts/automated-backup.sh
# Or use k8s CronJob for cloud deployments

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
NAMESPACE=${NAMESPACE:-production}
BACKUP_ROOT=${BACKUP_ROOT:-./backups}
RETENTION_DAYS=${RETENTION_DAYS:-30}
S3_BUCKET=${S3_BUCKET:-}  # Optional: s3://your-bucket/attendance-backups
ALERT_WEBHOOK=${ALERT_WEBHOOK:-}  # Optional: Slack/Discord webhook for alerts

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
LOG_FILE="$BACKUP_ROOT/backup.log"

# ── Functions ─────────────────────────────────────────────────────────────────
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    log "ALERT: $message"
    
    if [ -n "$ALERT_WEBHOOK" ]; then
        curl -X POST "$ALERT_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🚨 Backup Alert: $message\"}" \
            2>/dev/null || true
    fi
}

cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \;
    log "Cleanup complete"
}

verify_backup() {
    local file="$1"
    local type="$2"
    
    if [ ! -f "$file" ]; then
        alert "Backup file missing: $file"
        return 1
    fi
    
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ "$size" -lt 1024 ]; then
        alert "Backup file too small (${size} bytes): $file"
        return 1
    fi
    
    # Verify gzip integrity
    if [[ "$file" == *.gz ]]; then
        if ! gzip -t "$file" 2>/dev/null; then
            alert "Corrupted gzip file: $file"
            return 1
        fi
    fi
    
    log "✓ $type backup verified: $(du -h "$file" | cut -f1)"
    return 0
}

upload_to_s3() {
    if [ -z "$S3_BUCKET" ]; then
        return 0
    fi
    
    log "Uploading to S3: $S3_BUCKET"
    
    if command -v aws &> /dev/null; then
        aws s3 sync "$BACKUP_DIR" "$S3_BUCKET/$TIMESTAMP/" --quiet
        log "✓ S3 upload complete"
    elif command -v rclone &> /dev/null; then
        rclone copy "$BACKUP_DIR" "$S3_BUCKET/$TIMESTAMP/" --quiet
        log "✓ S3 upload complete (via rclone)"
    else
        log "⚠ No S3 upload tool found (aws-cli or rclone)"
    fi
}

# ── Main Backup Process ───────────────────────────────────────────────────────
main() {
    log "========================================="
    log "Starting backup for namespace: $NAMESPACE"
    log "========================================="
    
    mkdir -p "$BACKUP_DIR"
    
    # 1. Backup main Postgres database
    log "📦 Backing up main Postgres database..."
    if kubectl -n "$NAMESPACE" exec deploy/postgres -- \
        pg_dump -U postgres attendance_db | gzip > "$BACKUP_DIR/postgres.sql.gz"; then
        verify_backup "$BACKUP_DIR/postgres.sql.gz" "Postgres"
    else
        alert "Postgres backup failed"
        exit 1
    fi
    
    # 2. Backup CompreFace database
    log "📦 Backing up CompreFace database..."
    if kubectl -n "$NAMESPACE" exec deploy/compreface-postgres-db -- \
        pg_dump -U postgres frs | gzip > "$BACKUP_DIR/compreface.sql.gz"; then
        verify_backup "$BACKUP_DIR/compreface.sql.gz" "CompreFace DB"
    else
        alert "CompreFace backup failed"
        exit 1
    fi
    
    # 3. Backup PocketBase data
    log "📦 Backing up PocketBase data..."
    if kubectl -n "$NAMESPACE" exec deploy/pocketbase -- \
        tar czf - /pb/pb_data 2>/dev/null > "$BACKUP_DIR/pocketbase.tar.gz"; then
        verify_backup "$BACKUP_DIR/pocketbase.tar.gz" "PocketBase"
    else
        alert "PocketBase backup failed"
        exit 1
    fi
    
    # 4. Backup Redis data (optional, for chat history)
    log "📦 Backing up Redis data..."
    if kubectl -n "$NAMESPACE" exec deploy/redis -- \
        redis-cli --rdb /tmp/dump.rdb save && \
       kubectl -n "$NAMESPACE" exec deploy/redis -- \
        cat /tmp/dump.rdb > "$BACKUP_DIR/redis.rdb"; then
        verify_backup "$BACKUP_DIR/redis.rdb" "Redis"
    else
        log "⚠ Redis backup failed (non-critical)"
    fi
    
    # 5. Backup video clips (if using persistent volume)
    log "📦 Backing up video clips..."
    if kubectl -n "$NAMESPACE" exec deploy/backend -- \
        tar czf - /var/attendance_clips 2>/dev/null > "$BACKUP_DIR/clips.tar.gz"; then
        verify_backup "$BACKUP_DIR/clips.tar.gz" "Video clips"
    else
        log "⚠ Video clips backup failed (may not exist)"
    fi
    
    # 6. Create backup manifest
    log "📝 Creating backup manifest..."
    cat > "$BACKUP_DIR/manifest.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "namespace": "$NAMESPACE",
  "date": "$(date -Iseconds)",
  "files": [
    "postgres.sql.gz",
    "compreface.sql.gz",
    "pocketbase.tar.gz",
    "redis.rdb",
    "clips.tar.gz"
  ],
  "sizes": {
    "postgres": "$(du -h "$BACKUP_DIR/postgres.sql.gz" | cut -f1)",
    "compreface": "$(du -h "$BACKUP_DIR/compreface.sql.gz" | cut -f1)",
    "pocketbase": "$(du -h "$BACKUP_DIR/pocketbase.tar.gz" | cut -f1)",
    "total": "$(du -sh "$BACKUP_DIR" | cut -f1)"
  }
}
EOF
    
    # 7. Upload to S3 (if configured)
    upload_to_s3
    
    # 8. Cleanup old backups
    cleanup_old_backups
    
    # 9. Success notification
    log "========================================="
    log "✅ Backup complete: $BACKUP_DIR"
    log "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
    log "========================================="
    
    if [ -n "$ALERT_WEBHOOK" ]; then
        curl -X POST "$ALERT_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"✅ Backup successful: $TIMESTAMP ($(du -sh "$BACKUP_DIR" | cut -f1))\"}" \
            2>/dev/null || true
    fi
}

# ── Error Handling ────────────────────────────────────────────────────────────
trap 'alert "Backup script failed at line $LINENO"' ERR

# ── Run ───────────────────────────────────────────────────────────────────────
main "$@"
