#!/bin/bash
# Quick rebuild and run script

echo "🔨 Rebuilding Linux app..."
flutter build linux --release

echo ""
echo "🚀 Starting AttendanceAI..."
./build/linux/x64/release/bundle/attendanceai
