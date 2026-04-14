#!/usr/bin/env bash
# rollback.sh — emergency rollback for backend and/or dashboard
# Usage:
#   ./rollback.sh                    # rollback both in production
#   ./rollback.sh staging            # rollback both in staging
#   ./rollback.sh production backend # rollback only backend in production
set -euo pipefail

NAMESPACE=${1:-production}
SERVICE=${2:-all}

rollback() {
  local svc=$1
  echo "⏪  Rolling back $svc in namespace $NAMESPACE..."
  kubectl -n "$NAMESPACE" rollout undo "deployment/$svc"
  kubectl -n "$NAMESPACE" rollout status "deployment/$svc" --timeout=60s
  echo "✅  $svc rolled back."
}

if [[ "$SERVICE" == "all" ]]; then
  rollback backend
  rollback dashboard
else
  rollback "$SERVICE"
fi
