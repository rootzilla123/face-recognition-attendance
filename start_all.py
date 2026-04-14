#!/usr/bin/env python3
"""
Full-stack startup script for Face Recognition Attendance System.
Manages Docker containers, backend server, and frontend development server.
"""

import subprocess
import time
import os
import sys
import signal
import psutil
from pathlib import Path
from typing import List, Optional

# Color codes for terminal output
GREEN = '\033[92m'
YELLOW = '\033[93m'
RED = '\033[91m'
BLUE = '\033[94m'
RESET = '\033[0m'
BOLD = '\033[1m'

# Paths
SCRIPT_DIR = Path(__file__).parent
ATTENDANCE_SYSTEM = SCRIPT_DIR / "attendance-system"
ATTENDANCE_DASHBOARD = SCRIPT_DIR / "attendance-dashboard"

# Process management
processes: List[subprocess.Popen] = []


def log_info(message: str):
    """Log info message with color."""
    print(f"{BLUE}[INFO]{RESET} {message}")


def log_success(message: str):
    """Log success message with color."""
    print(f"{GREEN}[✓]{RESET} {message}")


def log_warning(message: str):
    """Log warning message with color."""
    print(f"{YELLOW}[⚠]{RESET} {message}")


def log_error(message: str):
    """Log error message with color."""
    print(f"{RED}[✗]{RESET} {message}")


def log_section(title: str):
    """Log section header."""
    print(f"\n{BOLD}{BLUE}{'='*60}{RESET}")
    print(f"{BOLD}{BLUE}{title}{RESET}")
    print(f"{BOLD}{BLUE}{'='*60}{RESET}\n")


def check_command_exists(cmd: str) -> bool:
    """Check if a command exists in PATH."""
    result = subprocess.run(
        ["which", cmd],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    return result.returncode == 0


def is_port_open(port: int, host: str = "127.0.0.1", timeout: float = 2) -> bool:
    """Check if a port is open (service is running)."""
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        result = sock.connect_ex((host, port))
        return result == 0
    finally:
        sock.close()


def wait_for_service(port: int, service_name: str, max_wait: int = 30) -> bool:
    """Wait for a service to be ready on a given port."""
    log_info(f"Waiting for {service_name} to be ready on port {port}...")
    
    start_time = time.time()
    while time.time() - start_time < max_wait:
        if is_port_open(port):
            log_success(f"{service_name} is ready!")
            return True
        time.sleep(1)
    
    log_warning(f"{service_name} did not start within {max_wait} seconds")
    return False


def run_command(
    cmd: List[str],
    cwd: Optional[Path] = None,
    env_vars: Optional[dict] = None,
    name: Optional[str] = None
) -> Optional[subprocess.Popen]:
    """
    Run a command as a subprocess.
    
    Returns:
        subprocess.Popen object or None if failed
    """
    try:
        env = os.environ.copy()
        if env_vars:
            env.update(env_vars)
        
        process = subprocess.Popen(
            cmd,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        if name:
            log_success(f"Started {name} (PID: {process.pid})")
        
        return process
    except Exception as e:
        log_error(f"Failed to start process: {str(e)}")
        return None


def start_docker():
    """Start Docker containers using docker-compose."""
    log_section("STARTING DOCKER CONTAINERS")
    
    if check_command_exists("docker-compose"):
        compose_cmd = ["docker-compose"]
    elif check_command_exists("docker"):
        log_warning("docker-compose not found, using 'docker compose' instead")
        compose_cmd = ["docker", "compose"]
    else:
        log_error("Docker is not installed!")
        return False
    
    try:
        log_info("Bringing up Docker containers...")
        result = subprocess.run(
            compose_cmd + ["up", "-d"],
            cwd=ATTENDANCE_SYSTEM,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            log_error(f"Docker-compose failed: {result.stderr}")
            return False
        
        log_success("Docker containers started successfully")
        
        # Wait for key services
        log_info("Waiting for services to initialize...")
        time.sleep(5)  # Initial buffer
        
        wait_for_service(5432, "PostgreSQL")
        wait_for_service(6379, "Redis")
        if is_port_open(1025):
            log_success("Mailpit SMTP is ready!")
        wait_for_service(8000, "CompreFace API")
        
        return True
        
    except subprocess.TimeoutExpired:
        log_error("Docker-compose timeout")
        return False
    except Exception as e:
        log_error(f"Error starting Docker: {str(e)}")
        return False



def start_pocketbase():
    """Start PocketBase server."""
    log_section("STARTING POCKETBASE")

    # Already running?
    if is_port_open(8091):
        log_success("PocketBase already running on port 8091")
        return True

    pb_binary = SCRIPT_DIR / "pocketbase"
    pb_data = SCRIPT_DIR / "pb_data"

    if not pb_binary.exists():
        log_warning("PocketBase binary not found at " + str(pb_binary))
        return None

    # Ensure binary is executable
    import stat
    pb_binary.chmod(pb_binary.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)

    process = run_command(
        [str(pb_binary), "serve", "--http=0.0.0.0:8091", f"--dir={pb_data}"],
        cwd=SCRIPT_DIR,
        name="PocketBase"
    )

    if process:
        processes.append(process)
        ready = wait_for_service(8091, "PocketBase", max_wait=15)
        if not ready:
            log_warning("PocketBase may not have started correctly")

    return process

def start_backend():
    """Start the FastAPI backend server."""
    log_section("STARTING BACKEND SERVER")
    
    if not ATTENDANCE_SYSTEM.exists():
        log_error(f"Backend directory not found: {ATTENDANCE_SYSTEM}")
        return None
    
    try:
        # Check for venv
        venv_python = ATTENDANCE_SYSTEM / "venv" / "bin" / "python"
        if venv_python.exists():
            python_cmd = str(venv_python)
            log_info(f"Using virtual environment: {python_cmd}")
        else:
            python_cmd = "python3"
            log_info("Using system Python")
        
        # Start uvicorn
        process = run_command(
            [python_cmd, "-m", "uvicorn", "app.main:app", "--reload", "--host", "0.0.0.0", "--port", "8001"],
            cwd=ATTENDANCE_SYSTEM,
            name="Backend (Uvicorn)"
        )
        
        if process:
            processes.append(process)
            # Wait for backend to be ready
            time.sleep(5)
            wait_for_service(8001, "Backend API")
            log_success("Backend server is running on http://0.0.0.0:8001")
        
        return process
        
    except Exception as e:
        log_error(f"Error starting backend: {str(e)}")
        return None


def start_frontend():
    """Start the frontend development server."""
    log_section("STARTING FRONTEND SERVER")
    
    if not ATTENDANCE_DASHBOARD.exists():
        log_error(f"Frontend directory not found: {ATTENDANCE_DASHBOARD}")
        log_info(f"Looked at: {ATTENDANCE_DASHBOARD}")
        return None
    
    # Check if node_modules exists, if not run npm install
    node_modules = ATTENDANCE_DASHBOARD / "node_modules"
    if not node_modules.exists():
        log_warning("node_modules not found, running npm install...")
        try:
            result = subprocess.run(
                ["npm", "install"],
                cwd=ATTENDANCE_DASHBOARD,
                capture_output=True,
                text=True,
                timeout=120
            )
            if result.returncode != 0:
                log_error(f"npm install failed: {result.stderr}")
                return None
            log_success("npm install completed")
        except Exception as e:
            log_error(f"Error running npm install: {str(e)}")
            return None
    
    try:
        process = run_command(
            ["npm", "run", "dev"],
            cwd=ATTENDANCE_DASHBOARD,
            name="Frontend (Vite Dev Server)"
        )
        
        if process:
            processes.append(process)
            wait_for_service(3000, "Frontend (Next.js)", max_wait=60)
            log_success("Frontend development server started")
        
        return process
        
    except Exception as e:
        log_error(f"Error starting frontend: {str(e)}")
        return None


def print_status():
    """Print status of all running services."""
    log_section("SERVICE STATUS")
    
    services = [
        ("PostgreSQL", 5432),
        ("Redis", 6379),
        ("Mailpit SMTP", 1025),
        ("Mailpit UI", 8025),
        ("PocketBase", 8091),
        ("CompreFace API", 8000),
        ("CompreFace Frontend", 8080),
        ("Backend API", 8001),
        ("Frontend Dev", 3000),
    ]
    
    for service_name, port in services:
        status = "✓ Running" if is_port_open(port) else "✗ Not running"
        color = GREEN if is_port_open(port) else RED
        print(f"{color}{status}{RESET} {service_name:30} (port {port})")


def cleanup(signum=None, frame=None):
    """Clean up processes and exit gracefully."""
    log_section("SHUTTING DOWN SERVICES")
    
    log_info("Terminating all processes...")
    for process in processes:
        try:
            process.terminate()
            process.wait(timeout=5)
            log_success(f"Stopped process (PID: {process.pid})")
        except subprocess.TimeoutExpired:
            process.kill()
            log_warning(f"Killed process (PID: {process.pid})")
        except Exception as e:
            log_error(f"Error stopping process: {str(e)}")
    
    log_success("All services stopped")
    sys.exit(0)


def stream_output(process: subprocess.Popen, process_name: str):
    """Stream process output to terminal."""
    try:
        for line in process.stdout:
            if line:
                print(f"{BOLD}{YELLOW}[{process_name}]{RESET} {line}", end='')
    except Exception:
        pass


def main():
    """Main entry point."""
    print(f"\n{BOLD}{BLUE}Face Recognition Attendance System - Full Stack Startup{RESET}\n")
    
    # Set up signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    
    # Validation
    log_section("VALIDATING ENVIRONMENT")
    
    if not check_command_exists("docker"):
        log_error("Docker is not installed or not in PATH")
        sys.exit(1)
    
    if not check_command_exists("npm"):
        log_error("npm is not installed or not in PATH")
        sys.exit(1)
    
    log_success("Docker found")
    log_success("npm found")
    
    # Start services
    if not start_docker():
        log_error("Failed to start Docker containers")
        sys.exit(1)
    
    pb_process = start_pocketbase()
    if not pb_process:
        log_warning("PocketBase startup had issues, continuing anyway...")

    backend_process = start_backend()
    if not backend_process:
        log_warning("Backend startup had issues, continuing anyway...")
    
    frontend_process = start_frontend()
    if not frontend_process:
        log_warning("Frontend startup had issues, continuing anyway...")
    
    # Print summary
    time.sleep(2)
    print_status()
    
    # Print helpful info
    log_section("QUICK LINKS")
    print(f"{BLUE}Backend API{RESET}         : http://localhost:8001")
    print(f"{BLUE}Backend Docs{RESET}        : http://localhost:8001/docs")
    print(f"{BLUE}Frontend{RESET}            : http://localhost:3000")
    print(f"{BLUE}PocketBase Admin{RESET}    : http://localhost:8091/_/")
    print(f"{BLUE}Mailpit (emails){RESET}    : http://localhost:8025")
    print(f"{BLUE}CompreFace Interface{RESET}: http://localhost:8090")
    print(f"{BLUE}CompreFace API{RESET}      : http://localhost:8000")
    
    print(f"\n{YELLOW}Press Ctrl+C to stop all services{RESET}\n")
    
    # Keep running and stream output
    try:
        import threading
        
        if pb_process:
            thread = threading.Thread(target=stream_output, args=(pb_process, "PocketBase"), daemon=True)
            thread.start()

        if backend_process:
            thread = threading.Thread(target=stream_output, args=(backend_process, "Backend"), daemon=True)
            thread.start()
        
        if frontend_process:
            thread = threading.Thread(target=stream_output, args=(frontend_process, "Frontend"), daemon=True)
            thread.start()
        
        # Keep main thread alive
        while True:
            time.sleep(1)
            
            # Remove dead processes silently
            processes[:] = [p for p in processes if p.poll() is None]
                    
    except KeyboardInterrupt:
        cleanup()


if __name__ == "__main__":
    main()
