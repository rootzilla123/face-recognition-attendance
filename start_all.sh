#!/bin/bash

# Face Recognition Attendance System - Full Stack Startup Script
# Manages Docker containers, backend server, and frontend development server

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ATTENDANCE_SYSTEM="$SCRIPT_DIR/attendance-system"
ATTENDANCE_DASHBOARD="$SCRIPT_DIR/attendance-dashboard"

# Process tracking
PIDS=()

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo -e "\n${BOLD}${BLUE}========================================================${NC}"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BOLD}${BLUE}========================================================${NC}\n"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if port is open
port_open() {
    local port=$1
    local host=${2:-127.0.0.1}
    timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && return 0 || return 1
}

# Wait for service
wait_for_service() {
    local port=$1
    local service_name=$2
    local max_wait=${3:-30}
    
    log_info "Waiting for $service_name to be ready on port $port..."
    
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if port_open $port; then
            log_success "$service_name is ready!"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    log_warning "$service_name did not start within $max_wait seconds"
    return 1
}

# Cleanup on exit
cleanup() {
    log_section "SHUTTING DOWN SERVICES"
    
    log_info "Terminating all background processes..."
    for pid in "${PIDS[@]}"; do
        if kill -0 $pid 2>/dev/null; then
            log_success "Stopping process (PID: $pid)"
            kill $pid 2>/dev/null || true
        fi
    done
    
    log_success "All services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Validation
log_section "VALIDATING ENVIRONMENT"

if ! command_exists docker; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command_exists npm; then
    log_error "npm is not installed or not in PATH"
    exit 1
fi

log_success "Docker found"
log_success "npm found"

# Start Docker containers
log_section "STARTING DOCKER CONTAINERS"

if command_exists docker-compose; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
    log_warning "Using 'docker compose' instead of 'docker-compose'"
fi

cd "$ATTENDANCE_SYSTEM"

log_info "Bringing up Docker containers..."
$COMPOSE_CMD up -d

if [ $? -ne 0 ]; then
    log_error "Docker-compose failed"
    exit 1
fi

log_success "Docker containers started successfully"

# Wait for services
log_info "Waiting for services to initialize..."
sleep 5

wait_for_service 5432 "PostgreSQL"
wait_for_service 6379 "Redis"
wait_for_service 8000 "CompreFace API"

# Start Backend
log_section "STARTING BACKEND SERVER"

if [ -d "$ATTENDANCE_SYSTEM/venv" ]; then
    PYTHON="$ATTENDANCE_SYSTEM/venv/bin/python"
    log_info "Using virtual environment"
else
    PYTHON="python3"
    log_info "Using system Python"
fi

cd "$ATTENDANCE_SYSTEM"
log_info "Starting backend server..."
$PYTHON -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001 > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
PIDS+=($BACKEND_PID)

log_success "Backend started (PID: $BACKEND_PID)"
sleep 5
wait_for_service 8001 "Backend API"
log_success "Backend server is running on http://0.0.0.0:8001"

# Start PocketBase
log_section "STARTING POCKETBASE"

cd "$SCRIPT_DIR"
log_info "Starting PocketBase..."
./pocketbase serve --http=0.0.0.0:8091 > /tmp/pocketbase.log 2>&1 &
POCKETBASE_PID=$!
PIDS+=($POCKETBASE_PID)
log_success "PocketBase started (PID: $POCKETBASE_PID)"
wait_for_service 8091 "PocketBase"

# Start Frontend
log_section "STARTING FRONTEND SERVER"

if [ ! -d "$ATTENDANCE_DASHBOARD" ]; then
    log_error "Frontend directory not found: $ATTENDANCE_DASHBOARD"
    exit 1
fi

cd "$ATTENDANCE_DASHBOARD"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    log_warning "node_modules not found, running npm install..."
    npm install
    if [ $? -ne 0 ]; then
        log_error "npm install failed"
        exit 1
    fi
    log_success "npm install completed"
fi

log_info "Starting frontend development server..."
npm run dev > /tmp/frontend.log 2>&1 &
FRONTEND_PID=$!
PIDS+=($FRONTEND_PID)

log_success "Frontend started (PID: $FRONTEND_PID)"
wait_for_service 3000 "Frontend" 60

# Print status
log_section "SERVICE STATUS"

services=(
    "PostgreSQL:5432"
    "Redis:6379"
    "CompreFace API:8000"
    "CompreFace Frontend:8080"
    "Backend API:8001"
    "PocketBase:8091"
    "Frontend Dev:3000"
)

for service in "${services[@]}"; do
    name=${service%:*}
    port=${service#*:}
    
    if port_open $port; then
        echo -e "${GREEN}✓ Running${NC} $name (port $port)"
    else
        echo -e "${RED}✗ Not running${NC} $name (port $port)"
    fi
done

# Print quick links
log_section "QUICK LINKS"

echo -e "${BLUE}Backend API${NC}          : http://localhost:8001"
echo -e "${BLUE}Backend Docs${NC}         : http://localhost:8001/docs"
echo -e "${BLUE}Frontend${NC}             : http://localhost:3000"
echo -e "${BLUE}PocketBase${NC}           : http://localhost:8091/_/"
echo -e "${BLUE}CompreFace Interface${NC} : http://localhost:8090"
echo -e "${BLUE}CompreFace API${NC}       : http://localhost:8000"

echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}\n"

echo -e "${BLUE}Logs:${NC}"
echo -e "  Backend    : tail -f /tmp/backend.log"
echo -e "  Frontend   : tail -f /tmp/frontend.log"
echo -e "  PocketBase : tail -f /tmp/pocketbase.log\n"

while true; do
    for pid in "${PIDS[@]}"; do
        if ! kill -0 $pid 2>/dev/null; then
            log_warning "Process $pid has stopped unexpectedly"
        fi
    done
    sleep 10
done
