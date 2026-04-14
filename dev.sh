#!/bin/bash
# dev.sh — starts all services with live logs in tmux split panes
# Usage: ./dev.sh

SESSION="attendance"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/attendance-system"
DASHBOARD="$ROOT/attendance-dashboard"
PYTHON="$BACKEND/venv/bin/python"
[ ! -f "$PYTHON" ] && PYTHON="python3"

# Require tmux
if ! command -v tmux &>/dev/null; then
  echo "tmux is required. Install it with: sudo apt install tmux"
  exit 1
fi

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null

# ── Window layout ──────────────────────────────────────────────
# Pane 0 (top-left)   : PocketBase
# Pane 1 (top-right)  : FastAPI backend
# Pane 2 (bottom-left): Next.js frontend
# Pane 3 (bottom-right): Docker / CompreFace

tmux new-session -d -s "$SESSION" -x 220 -y 50

# Pane 0 — PocketBase
tmux send-keys -t "$SESSION:0.0" \
  "echo '=== PocketBase ===' && cd '$ROOT' && ./pocketbase serve --http=0.0.0.0:8090" Enter

# Pane 1 — FastAPI (split right)
tmux split-window -h -t "$SESSION:0.0"
tmux send-keys -t "$SESSION:0.1" \
  "echo '=== FastAPI Backend ===' && cd '$BACKEND' && $PYTHON -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001" Enter

# Pane 2 — Next.js (split bottom-left)
tmux split-window -v -t "$SESSION:0.0"
tmux send-keys -t "$SESSION:0.2" \
  "echo '=== Next.js Dashboard ===' && cd '$DASHBOARD' && npm run dev" Enter

# Pane 3 — Docker (split bottom-right)
tmux split-window -v -t "$SESSION:0.1"
tmux send-keys -t "$SESSION:0.3" \
  "echo '=== Docker / CompreFace ===' && cd '$BACKEND' && docker compose up" Enter

# Even out the layout
tmux select-layout -t "$SESSION" tiled

# Focus pane 1 (backend — most likely to show errors first)
tmux select-pane -t "$SESSION:0.1"

echo ""
echo "All services starting in tmux session '$SESSION'"
echo ""
echo "  Attach now  : tmux attach -t $SESSION"
echo "  Detach later: Ctrl+B then D"
echo "  Kill all    : tmux kill-session -t $SESSION"
echo ""

tmux attach -t "$SESSION"
