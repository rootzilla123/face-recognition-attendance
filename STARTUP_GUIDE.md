# Full-Stack Startup Scripts

Automated scripts to start Docker containers, backend server, and frontend development server in one command.

## Available Scripts

### Python Version (Recommended)
```bash
./start_all.py
```

**Features:**
- Colored output for easy reading
- Service status monitoring
- Graceful shutdown on Ctrl+C
- Real-time process output streaming
- Port availability checking

**Requirements:**
- Python 3.7+
- `psutil` module: `pip install psutil`

### Bash Version (Lightweight)
```bash
./start_all.sh
```

**Features:**
- No Python dependencies
- Lightweight and fast
- Service health checks
- Log file output to `/tmp/`

**Requirements:**
- Bash 4.0+
- Docker and Docker Compose
- npm

## What Each Script Does

Both scripts automate the following sequence:

1. **Validates environment** - Checks for Docker and npm
2. **Starts Docker containers** - PostgreSQL, Redis, CompreFace stack
3. **Starts backend server** - FastAPI on port 8001
4. **Installs npm dependencies** - If needed
5. **Starts frontend dev server** - Vite dev server on port 5173
6. **Shows service status** - Live port checking
7. **Stays running** - Streaming logs from services

## Quick Start

### Option 1: Python (with advanced features)
```bash
cd ~/face-recognition-attendance
python3 start_all.py
```

### Option 2: Bash (simple and fast)
```bash
cd ~/face-recognition-attendance
bash start_all.sh
```

## After Startup

Once running, access your services:

| Service | URL |
|---------|-----|
| **Frontend** | http://localhost:5173 |
| **Backend API** | http://localhost:8001 |
| **API Docs** | http://localhost:8001/docs |
| **CompreFace UI** | http://localhost:8090 |
| **CompreFace API** | http://localhost:8000 |

## Stopping Services

Press **Ctrl+C** in the terminal to gracefully stop all services:
- Terminates backend process
- Terminates frontend process
- Keeps Docker containers running (use `docker-compose down` if needed)

## Troubleshooting

### Backend not starting?
Check logs with:
```bash
tail -f /tmp/backend.log  # Bash version
python3 start_all.py  # Python version shows output live
```

### Frontend not starting?
```bash
tail -f /tmp/frontend.log  # Bash version
npm run dev  # Manual start
```

### Port conflicts?
If a port is already in use, the scripts will timeout waiting. Kill the conflicting process:
```bash
# Example: Kill process on port 8001
lsof -ti:8001 | xargs kill -9
```

### Docker not running?
Try:
```bash
docker-compose up -d  # Manual start
# or
systemctl start docker  # On Linux with systemd
```

## Install psutil (Python version only)

If you see an import error for `psutil`:
```bash
pip install psutil
# or
pip3 install psutil
```

## Manual Alternative

If you prefer manual control, run these separately in different terminals:

**Terminal 1 - Docker:**
```bash
cd ~/face-recognition-attendance/attendance-system
docker-compose up -d
```

**Terminal 2 - Backend:**
```bash
cd ~/face-recognition-attendance/attendance-system
python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

**Terminal 3 - Frontend:**
```bash
cd ~/face-recognition-attendance/attendance-dashboard
npm run dev
```

## Notes

- The Python version is recommended for better UX and real-time monitoring
- Both scripts assume the folder structure: `attendance-system/` and `attendance-dashboard/`
- Logs are piped to `/tmp/` in Bash version for debugging
- Services need 10-30 seconds to fully initialize depending on your system
