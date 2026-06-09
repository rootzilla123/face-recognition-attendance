#!/usr/bin/env bash
# restore-backup.sh — Restore from backup
# Usage: ./restore-backup.sh <backup-timestamp> [namespace]
# Example: ./restore-backup.sh 20260430_020000 production

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
BACKUP_TIMESTAMP=${1:-}
NAMESPACE=${2:-production}
BACKUP_ROOT=${BACKUP_ROOT:-./backups}
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_TIMESTAMP"

# ── Functions ─────────────────────────────────────────────────────────────────
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

confirm() {
    read -p "⚠️  This will OVERWRITE all data in $NAMESPACE. Continue? (yes/no): " response
    if [ "$response" != "yes" ]; then
        log "Restore cancelled"
        exit 0
    fi
}

# ── Validation ────────────────────────────────────────────────────────────────
if [ -z "$BACKUP_TIMESTAMP" ]; then
    echo "Usage: $0 <backup-timestamp> [namespace]"
    echo ""
    echo "Available backups:"
    ls -1 "$BACKUP_ROOT" | grep "^20" || echo "  No backups found"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    log "ERROR: Backup directory not found: $BACKUP_DIR"
    exit 1
fi

log "Backup directory: $BACKUP_DIR"
log "Target namespace: $NAMESPACE"
log ""
log "Backup contents:"
ls -lh "$BACKUP_DIR"
log ""

confirm

# ── Restore Process ───────────────────────────────────────────────────────────
log "========================================="
log "Starting restore from: $BACKUP_TIMESTAMP"
log "========================================="

# 1. Restore main Postgres database
log "📥 Restoring main Postgres database..."
if [ -f "$BACKUP_DIR/postgres.sql.gz" ]; then
    # Drop and recreate database
    kubectl -n "$NAMESPACE" exec deploy/postgres -- \
        psql -U postgres -c "DROP DATABASE IF EXISTS attendance_db;"
    kubectl -n "$NAMESPACE" exec deploy/postgres -- \
        psql -U postgres -c "CREATE DATABASE attendance_db;"
    
    # Restore from backup
    gunzip -c "$BACKUP_DIR/postgres.sql.gz" | \
        kubectl -n "$NAMESPACE" exec -i deploy/postgres -- \
        psql -U postgres attendance_db
    
    log "✓ Postgres restored"
else
    log "⚠ Postgres backup not found, skipping"
fi

# 2. Restore CompreFace database
log "📥 Restoring CompreFace database..."
if [ -f "$BACKUP_DIR/compreface.sql.gz" ]; then
    kubectl -n "$NAMESPACE" exec deploy/compreface-postgres-db -- \
        psql -U postgres -c "DROP DATABASE IF EXISTS frs;"
    kubectl -n "$NAMESPACE" exec deploy/compreface-postgres-db -- \
        psql -U postgres -c "CREATE DATABASE frs;"
    
    gunzip -c "$BACKUP_DIR/compreface.sql.gz" | \
        kubectl -n "$NAMESPACE" exec -i deploy/compreface-postgres-db -- \
        psql -U postgres frs
    
    log "✓ CompreFace DB restored"
else
    log "⚠ CompreFace backup not found, skipping"
fi

# 3. Restore PocketBase data
log "📥 Restoring PocketBase data..."
if [ -f "$BACKUP_DIR/pocketbase.tar.gz" ]; then
    # Stop PocketBase temporarily
    kubectl -n "$NAMESPACE" scale deploy/pocketbase --replicas=0
    sleep 5
    
    # Clear existing data
    kubectl -n "$NAMESPACE" exec deploy/pocketbase -- rm -rf /pb/pb_data/* || true
    
    # Restore from backup
    cat "$BACKUP_DIR/pocketbase.tar.gz" | \
        kubectl -n "$NAMESPACE" exec -i deploy/pocketbase -- \
        tar xzf - -C /
    
    # Restart PocketBase
    kubectl -n "$NAMESPACE" scale deploy/pocketbase --replicas=1
    
    log "✓ PocketBase restored"
else
    log "⚠ PocketBase backup not found, skipping"
fi

# 4. Restore Redis data
log "📥 Restoring Redis data..."
if [ -f "$BACKUP_DIR/redis.rdb" ]; then
    cat "$BACKUP_DIR/redis.rdb" | \
        kubectl -n "$NAMESPACE" exec -i deploy/redis -- \
        tee /tmp/dump.rdb > /dev/null
    
    kubectl -n "$NAMESPACE" exec deploy/redis -- \
        redis-cli --rdb /tmp/dump.rdb restore
    
    log "✓ Redis restored"
else
    log "⚠ Redis backup not found, skipping"
fi

# 5. Restore video clips
log "📥 Restoring video clips..."
if [ -f "$BACKUP_DIR/clips.tar.gz" ]; then
    cat "$BACKUP_DIR/clips.tar.gz" | \
        kubectl -n "$NAMESPACE" exec -i deploy/backend -- \
        tar xzf - -C /
    
    log "✓ Video clips restored"
else
    log "⚠ Video clips backup not found, skipping"
fi

# 6. Restart all services
log "🔄 Restarting services..."
kubectl -n "$NAMESPACE" rollout restart deployment/backend
kubectl -n "$NAMESPACE" rollout restart deployment/dashboard
kubectl -n "$NAMESPACE" rollout restart deployment/compreface-admin
kubectl -n "$NAMESPACE" rollout restart deployment/compreface-api

log "Waiting for services to be ready..."
kubectl -n "$NAMESPACE" rollout status deployment/backend --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/dashboard --timeout=300s

log "========================================="
log "✅ Restore complete!"
log "========================================="
log ""
log "Next steps:"
log "1. Verify data integrity"
log "2. Check application logs"
log "3. Test critical functionality"
log "4. Monitor for errors"
