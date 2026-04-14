#!/usr/bin/env bash
# backup.sh — backs up Postgres and PocketBase to a local tar.gz
# Schedule via cron: 0 2 * * * /path/to/backup.sh
# For offsite: pipe to rclone / s3cmd after the tar step.
set -euo pipefail

NAMESPACE=${1:-production}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "📦  Backing up Postgres..."
kubectl -n "$NAMESPACE" exec deploy/postgres -- \
  pg_dump -U "$POSTGRES_USER" attendance_db | gzip > "$BACKUP_DIR/postgres.sql.gz"

echo "📦  Backing up PocketBase data..."
kubectl -n "$NAMESPACE" exec deploy/pocketbase -- \
  tar czf - /pb/pb_data | cat > "$BACKUP_DIR/pocketbase.tar.gz"

echo "✅  Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
