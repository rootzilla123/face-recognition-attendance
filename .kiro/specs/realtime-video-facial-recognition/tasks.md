# Implementation Plan: Real-Time Video Facial Recognition

## Overview

This implementation plan breaks down the real-time video streaming and facial recognition system into discrete coding tasks. The system will capture video from 4 concurrent camera sources, process frames for face detection and recognition using CompreFace API, automatically mark attendance, and stream live video feeds with recognition overlays to the Next.js dashboard via WebSocket.

The implementation follows a bottom-up approach: core infrastructure first, then video processing pipeline, followed by real-time streaming, and finally frontend integration.

## Tasks

- [x] 1. Set up database schema and models for camera management
  - Create database migration script for cameras table with indexes
  - Add Camera SQLAlchemy model to app/models.py
  - Update database initialization in app/main.py to create new tables
  - _Requirements: 1.3, 11.6_

- [x] 2. Implement core video streaming infrastructure
  - [x] 2.1 Create VideoStreamManager class in app/services/video_streaming.py
    - Implement camera connection management with OpenCV VideoCapture
    - Add support for RTSP, HTTP, and local device protocols
    - Implement async camera start/stop methods
    - Add camera status tracking (online/offline/error)
    - Implement reconnection logic with 30-second intervals
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [ ]* 2.2 Write unit tests for VideoStreamManager
    - Test camera connection establishment
    - Test reconnection logic on failure
    - Test status tracking
    - _Requirements: 1.1, 1.2, 1.6_

- [x] 3. Implement frame extraction and processing pipeline
  - [x] 3.1 Create FrameProcessor class in app/services/video_streaming.py
    - Implement frame extraction at configurable FPS (1-10)
    - Add JPEG encoding with quality settings (85% for CompreFace, 70% for streaming)
    - Implement bounded frame queues (max 100 per camera) with oldest-frame-drop policy
    - Add parallel processing for all 4 cameras using asyncio
    - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6_

  - [x] 3.2 Implement dynamic frame rate adjustment
    - Add system resource monitoring using psutil
    - Implement CPU threshold check (reduce FPS by 50% when >80%)
    - Implement memory threshold check (reduce FPS by 25% when >90%)
    - _Requirements: 2.3, 10.5_

  - [ ]* 3.3 Write unit tests for FrameProcessor
    - Test frame extraction and JPEG encoding
    - Test queue management and frame dropping
    - Test dynamic frame rate adjustment
    - _Requirements: 2.1, 2.3, 2.4, 2.5_

- [x] 4. Checkpoint - Ensure video capture and frame processing work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement face detection service
  - [x] 5.1 Create FaceDetector class in app/services/video_streaming.py
    - Implement detect_faces method that calls CompreFace detection API
    - Parse bounding box coordinates from API response
    - Add retry logic (2 retries with 1-second delay) for API failures
    - Filter out frames with no detected faces
    - Handle multiple faces per frame independently
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 5.2 Write unit tests for FaceDetector
    - Test API integration with mock responses
    - Test retry logic on failures
    - Test multiple face handling
    - _Requirements: 3.1, 3.4, 3.6_

- [x] 6. Implement face recognition service
  - [x] 6.1 Create FaceRecognizer class in app/services/video_streaming.py
    - Implement recognize_face method that calls CompreFace recognition API
    - Apply confidence threshold (0.85 minimum)
    - Extract student_id and confidence score from API response
    - Include camera_location and timestamp metadata
    - Log unknown face events for unrecognized detections
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [ ]* 6.2 Write unit tests for FaceRecognizer
    - Test API integration with mock responses
    - Test confidence threshold filtering
    - Test unknown face logging
    - _Requirements: 4.2, 4.3, 4.5_

- [x] 7. Implement duplicate prevention with Redis caching
  - [x] 7.1 Create DuplicateFilter class in app/services/video_streaming.py
    - Implement is_duplicate method that checks Redis cache
    - Use cache key format "attendance:recent:{student_id}:{camera_location}"
    - Set TTL equal to DUPLICATE_WINDOW_MINUTES configuration
    - Implement cache_attendance method to store attendance events
    - Add fallback logic to allow attendance if Redis connection fails
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ]* 7.2 Write unit tests for DuplicateFilter
    - Test duplicate detection within time window
    - Test cache expiration after TTL
    - Test fallback behavior on Redis failure
    - _Requirements: 6.1, 6.2, 6.6_

- [x] 8. Implement automatic attendance marking
  - [x] 8.1 Create AttendanceMarker class in app/services/video_streaming.py
    - Implement mark_attendance method that creates attendance records
    - Integrate with DuplicateFilter before creating records
    - Persist attendance records to PostgreSQL with student_id, camera_location, timestamp, confidence
    - Log duplicate attempts when DuplicateFilter returns duplicate status
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 8.2 Add attendance event publishing to AttendanceMarker
    - Implement publish_attendance_event method
    - Pass attendance events to StreamBroadcaster for WebSocket transmission
    - _Requirements: 5.6_

  - [ ]* 8.3 Write unit tests for AttendanceMarker
    - Test attendance record creation
    - Test duplicate filtering integration
    - Test event publishing
    - _Requirements: 5.1, 5.3, 5.4, 5.6_

- [x] 9. Checkpoint - Ensure face detection, recognition, and attendance marking work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Implement WebSocket server and connection management
  - [x] 10.1 Create WebSocketManager class in app/services/websocket.py
    - Implement connect method to register new clients
    - Implement disconnect method to clean up client connections
    - Implement send_message method for individual client messages
    - Implement broadcast method for all-client messages
    - Add client connection tracking with unique client IDs
    - _Requirements: 9.1, 9.5_

  - [x] 10.2 Add WebSocket heartbeat mechanism
    - Implement ping/pong heartbeat every 30 seconds
    - Detect and remove disconnected clients automatically
    - _Requirements: 9.6_

  - [x] 10.3 Create WebSocket endpoint in app/routes/websocket.py
    - Add /ws/attendance WebSocket endpoint
    - Handle client connections and disconnections
    - Integrate with WebSocketManager
    - _Requirements: 9.1_

  - [ ]* 10.4 Write unit tests for WebSocketManager
    - Test client registration and cleanup
    - Test message broadcasting
    - Test heartbeat mechanism
    - _Requirements: 9.1, 9.5, 9.6_

- [x] 11. Implement real-time stream broadcasting
  - [x] 11.1 Create StreamBroadcaster class in app/services/video_streaming.py
    - Implement broadcast_frame method to send frames to WebSocket clients
    - Encode frames as Base64 JPEG with 70% quality
    - Limit broadcast rate to 5 FPS per client
    - Include camera_id, timestamp, and detection metadata in frame messages
    - Pause transmission when no clients connected
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 11.2 Add attendance event broadcasting
    - Implement broadcast_attendance_event method
    - Include student_id, student_name, camera_location, timestamp, confidence_score
    - Broadcast to all connected WebSocket clients
    - _Requirements: 9.2, 9.3_

  - [x] 11.3 Add camera status broadcasting
    - Implement broadcast_camera_status method
    - Send camera online/offline status updates to clients
    - _Requirements: 9.4_

  - [ ]* 11.4 Write unit tests for StreamBroadcaster
    - Test frame encoding and broadcasting
    - Test rate limiting
    - Test pause behavior when no clients connected
    - _Requirements: 7.2, 7.3, 7.6_

- [x] 12. Implement camera management REST API
  - [x] 12.1 Create camera routes in app/routes/cameras.py
    - Implement POST /api/v1/cameras endpoint to register cameras
    - Implement GET /api/v1/cameras endpoint to list all cameras
    - Implement PUT /api/v1/cameras/{camera_id} endpoint to update camera config
    - Implement DELETE /api/v1/cameras/{camera_id} endpoint to remove cameras
    - Implement GET /api/v1/cameras/{camera_id}/status endpoint for camera status
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

  - [x] 12.2 Add camera configuration persistence
    - Persist camera configuration to PostgreSQL
    - Reload camera connections when configuration updated
    - _Requirements: 11.5, 11.6_

  - [ ]* 12.3 Write integration tests for camera API endpoints
    - Test camera registration and retrieval
    - Test camera updates and deletion
    - Test status endpoint
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [x] 13. Implement performance optimization and resource management
  - [x] 13.1 Add async I/O for concurrent stream processing
    - Use asyncio.gather for parallel camera processing
    - Implement non-blocking I/O operations
    - _Requirements: 10.1_

  - [x] 13.2 Add API request throttling with semaphore
    - Limit concurrent CompreFace API requests to 8 maximum
    - Use asyncio.Semaphore for request limiting
    - _Requirements: 10.2_

  - [x] 13.3 Add memory and latency monitoring
    - Track frame processing latency (target <500ms)
    - Monitor memory usage (limit 2GB)
    - Log performance metrics
    - _Requirements: 10.3, 10.4_

  - [ ]* 13.4 Write performance tests
    - Test concurrent stream processing
    - Test API throttling
    - Test latency under load
    - _Requirements: 10.1, 10.2, 10.3_

- [x] 14. Checkpoint - Ensure backend services are fully integrated
  - Ensure all tests pass, ask the user if questions arise.

- [x] 15. Wire backend components together
  - [x] 15.1 Create VideoStreamingService orchestrator in app/services/video_streaming.py
    - Initialize all components (VideoStreamManager, FrameProcessor, FaceDetector, etc.)
    - Wire frame processing pipeline: capture → process → detect → recognize → mark attendance
    - Wire streaming pipeline: frames → broadcaster → WebSocket
    - Add startup and shutdown lifecycle methods
    - _Requirements: 1.1, 2.6, 10.1_

  - [x] 15.2 Integrate VideoStreamingService into FastAPI app
    - Update app/main.py to initialize VideoStreamingService
    - Add startup event handler to start video streaming
    - Add shutdown event handler to stop video streaming gracefully
    - Include camera and WebSocket routers
    - _Requirements: 1.1, 9.1_

  - [x] 15.3 Add environment configuration
    - Update .env file with video streaming settings (FRAME_RATE, JPEG_QUALITY, etc.)
    - Add configuration validation in app/config.py
    - _Requirements: 2.1, 7.2, 10.4_

- [x] 16. Implement frontend WebSocket client hook
  - [x] 16.1 Create useWebSocket hook in attendance-dashboard/lib/useWebSocket.ts
    - Implement WebSocket connection management
    - Handle connection, disconnection, and reconnection
    - Parse incoming messages by type (frame_update, attendance_event, camera_status)
    - Implement automatic reconnection on connection loss
    - _Requirements: 9.1, 9.5_

  - [ ]* 16.2 Write unit tests for useWebSocket hook
    - Test connection lifecycle
    - Test message parsing
    - Test reconnection logic
    - _Requirements: 9.1, 9.5_

- [x] 17. Implement camera feed display component
  - [x] 17.1 Create CameraFeed component in attendance-dashboard/app/components/CameraFeed.tsx
    - Accept cameraId and locationName as props
    - Connect to WebSocket using useWebSocket hook
    - Display live video frames from Base64 JPEG data
    - Update frame display on frame_update messages
    - Show camera status (online/offline)
    - _Requirements: 7.1, 7.4, 7.5_

  - [ ]* 17.2 Write component tests for CameraFeed
    - Test frame rendering
    - Test WebSocket integration
    - Test status display
    - _Requirements: 7.1, 7.4_

- [x] 18. Implement recognition overlay component
  - [x] 18.1 Create RecognitionOverlay component in attendance-dashboard/app/components/RecognitionOverlay.tsx
    - Accept detection data (bounding box, student info, confidence)
    - Render green bounding box for recognized students
    - Render yellow bounding box for unrecognized faces
    - Display student name and confidence percentage above bounding box
    - Auto-hide overlay after 3 seconds
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 18.2 Write component tests for RecognitionOverlay
    - Test bounding box rendering
    - Test color coding (green/yellow)
    - Test auto-hide behavior
    - _Requirements: 8.3, 8.4, 8.6_

- [x] 19. Update cameras page with live feeds
  - [x] 19.1 Update attendance-dashboard/app/cameras/page.tsx
    - Replace static camera placeholders with CameraFeed components
    - Display all 4 camera feeds in grid layout
    - Add RecognitionOverlay to each camera feed
    - Show real-time attendance notifications from WebSocket
    - _Requirements: 7.1, 8.1, 9.2_

  - [ ]* 19.2 Write integration tests for cameras page
    - Test camera feed grid rendering
    - Test WebSocket message handling
    - Test attendance notifications
    - _Requirements: 7.1, 9.2_

- [x] 20. Add error handling and logging
  - [x] 20.1 Implement comprehensive error logging in backend
    - Log camera connection failures with camera_id and reason
    - Log CompreFace API errors with request details
    - Log recognition events with student_id, confidence, camera_location
    - Log duplicate attendance attempts
    - Add log level configuration via environment variable
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

  - [x] 20.2 Add error handling in frontend components
    - Display error messages when WebSocket connection fails
    - Show camera offline status in UI
    - Add retry mechanism for failed connections
    - _Requirements: 9.5_

- [x] 21. Update dependencies and documentation
  - [x] 21.1 Update backend dependencies
    - Add opencv-python, Pillow, psutil, websockets to requirements.txt
    - Update docker-compose.yml if needed for new dependencies
    - _Requirements: 1.1, 2.1, 2.3_

  - [x] 21.2 Update frontend dependencies
    - Add reconnecting-websocket to package.json
    - Update Next.js configuration for WebSocket support
    - _Requirements: 9.1_

  - [x] 21.3 Create database migration script
    - Create migrations/add_cameras_table.sql with cameras table and indexes
    - Add default camera configurations for 4 locations
    - _Requirements: 1.3, 11.6_

- [x] 22. Final checkpoint - End-to-end integration testing
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The implementation uses Python for backend (FastAPI) and TypeScript for frontend (Next.js)
- Checkpoints ensure incremental validation at key milestones
- The system processes 4 concurrent camera streams with real-time face recognition and attendance marking
- WebSocket provides bidirectional communication for live video streaming and attendance notifications
