#!/bin/bash

# Start services in tmux with split panes for better monitoring

echo "Starting services in tmux split-pane layout..."

# Kill existing session if it exists
tmux kill-session -t attendance 2>/dev/null

# Create new tmux session
tmux new-session -d -s attendance

# Split into 4 panes
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v

# Pane 0 (top-left): Docker containers
tmux select-pane -t 0
tmux send-keys 'echo "=== DOCKER CONTAINERS ===" && cd attendance-system && docker-compose up' C-m

# Pane 1 (bottom-left): PocketBase
tmux select-pane -t 1
tmux send-keys 'echo "=== POCKETBASE ===" && sleep 5 && ./pocketbase serve --http=0.0.0.0:8092 --dev' C-m

# Pane 2 (top-right): Backend
tmux select-pane -t 2
tmux send-keys 'echo "=== BACKEND API ===" && sleep 10 && cd attendance-system && ./venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload' C-m

# Pane 3 (bottom-right): Frontend
tmux select-pane -t 3
tmux send-keys 'echo "=== FRONTEND ===" && sleep 15 && cd attendance-dashboard && npm run dev' C-m

# Attach to session
echo "All services starting in split-pane view"
echo "Use Ctrl+B then arrow keys to navigate panes"
echo "Use Ctrl+B then 'd' to detach"

tmux attach -t attendance
