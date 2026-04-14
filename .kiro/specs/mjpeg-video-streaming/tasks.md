# Implementation Plan: MJPEG Video Streaming

## Overview

This implementation plan converts the MJPEG video streaming design into actionable coding tasks. The implementation will replace WebSocket-based video streaming with HTTP MJPEG streams, separating video delivery from event messaging. The plan follows an incremental approach: backend service → backend endpoint → frontend component → integration → testing.

## Tasks

- [ ] 1. Create MJPEG streaming service
  - [x] 1.1 Implement MJPEGStreamService class with core attributes
    - Create `attendance-system/app/services/mjpeg_streaming.py`
    - Define class with video_stream_manager, frame_processor, db, active_streams, stream_locks, jpeg_quality attributes
    - Initialize active_streams as Dict[str, Set[str]] for tracking camera_id → client_ids
    - Initialize stream_locks as Dict[str, asyncio.Lock] for per-camera concurrency control
    - _Requirements: 1.6, 4.3, 10.1, 10.2_

  - [ ]* 1.2 Write property test for MJPEGStreamService initialization
    - **Property 13: Service Integration Compliance**
    - **Validates: Requirements 2.4, 10.1, 10.2**

  - [x] 1.3 Implement camera validation method
    - Write `validate_camera(camera_id)` method
    - Query database for camera by ID
    - Raise CameraNotFoundError if not found
    - Raise CameraInactiveError if not active
    - Return Camera model on success
    - _Requirements: 1.3, 1.4, 1.5_

  - [ ]* 1.4 Write property test for camera validation
    - **Property 2: HTTP Error Response Correctness**
    - **Validates: Requirements 1.3, 1.4, 1.5, 5.1**

  - [x] 1.5 Implement client connection management methods
    - Write `register_client(camera_id, client_id)` method to add client to active_streams
    - Write `unregister_client(camera_id, client_id)` method to remove client and log event
    - Write `get_client_count(camera_id)` method to return number of connected clients
    - _Requirements: 1.7, 4.3, 4.5_

  - [ ]* 1.6 Write property test for client connection isolation
    - **Property 8: Client Connection Isolation**
    - **Validates: Requirements 1.6, 4.4**

  - [ ]* 1.7 Write property test for client connection cleanup
    - **Property 9: Client Connection Cleanup**
    - **Validates: Requirements 1.7, 4.3, 4.5**

  - [x] 1.8 Implement frame rate calculation method
    - Write `get_frame_interval(camera_id)` method
    - Read Frame_Rate from Camera database record
    - Calculate interval as `1.0 / Frame_Rate`
    - Return float representing seconds between frames
    - _Requirements: 3.1, 3.2, 3.5_

  - [ ]* 1.9 Write property test for frame rate calculation
    - **Property 4: Frame Rate Calculation**
    - **Validates: Requirements 3.2, 3.5**

  - [ ]* 1.10 Write property test for database configuration reading
    - **Property 14: Database Configuration Reading**
    - **Validates: Requirements 3.1, 10.3**

- [ ] 2. Implement MJPEG stream generation
  - [x] 2.1 Implement generate_mjpeg_stream async generator
    - Write `generate_mjpeg_stream(camera_id, client_id)` async generator method
    - Validate camera using validate_camera method
    - Register client using register_client method
    - Get frame interval using get_frame_interval method
    - Enter infinite loop to stream frames
    - _Requirements: 2.1, 2.2, 2.3, 4.1_

  - [x] 2.2 Implement frame reading and encoding in stream generator
    - Call `video_stream_manager.read_frame(camera_id)` to get frame
    - If frame read fails, log warning, sleep for frame_interval, and continue
    - Call `frame_processor.encode_frame_jpeg(frame, quality=70)` to encode
    - If encoding fails, log error, sleep for frame_interval, and continue
    - _Requirements: 2.4, 2.6, 3.3, 5.2, 10.1, 10.2_

  - [ ]* 2.3 Write property test for JPEG quality consistency
    - **Property 6: JPEG Quality Consistency**
    - **Validates: Requirements 3.3**

  - [ ]* 2.4 Write property test for frame read error recovery
    - **Property 7: Frame Read Error Recovery**
    - **Validates: Requirements 2.6, 5.2**

  - [x] 2.5 Implement multipart HTTP response formatting
    - Format each frame as: `--frame\r\nContent-Type: image/jpeg\r\nContent-Length: {size}\r\n\r\n{jpeg_bytes}\r\n`
    - Yield formatted bytes to client
    - Sleep for frame_interval between frames
    - _Requirements: 2.1, 2.2, 2.3, 2.5, 3.6_

  - [ ]* 2.6 Write property test for MJPEG protocol compliance
    - **Property 1: MJPEG Protocol Compliance**
    - **Validates: Requirements 2.1, 2.2, 2.3**

  - [ ]* 2.7 Write property test for frame rate timing accuracy
    - **Property 5: Frame Rate Timing Accuracy**
    - **Validates: Requirements 2.5, 2.7, 3.6**

  - [x] 2.8 Implement error handling and cleanup in stream generator
    - Wrap yield in try-except to catch ConnectionResetError, BrokenPipeError, asyncio.CancelledError
    - Log client disconnection with camera_id and client_id
    - Add finally block to call unregister_client
    - Check if camera goes offline during streaming and break loop
    - _Requirements: 4.2, 4.3, 5.3, 5.4, 5.6_

  - [ ]* 2.9 Write property test for camera error isolation
    - **Property 10: Camera Error Isolation**
    - **Validates: Requirements 5.3, 5.4, 5.5, 5.6**

- [x] 3. Checkpoint - Verify MJPEG service implementation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Create MJPEG stream endpoint
  - [x] 4.1 Create FastAPI router for MJPEG streaming
    - Create `attendance-system/app/routes/mjpeg_stream.py`
    - Import FastAPI dependencies: APIRouter, Request, Depends, HTTPException
    - Import StreamingResponse from fastapi.responses
    - Create router with `router = APIRouter()`
    - _Requirements: 1.1, 10.6_

  - [x] 4.2 Implement stream_camera endpoint
    - Define `@router.get("/cameras/{camera_id}/stream")` endpoint
    - Accept camera_id as path parameter (int)
    - Accept request (Request), db (Session), mjpeg_service (MJPEGStreamService) as dependencies
    - Generate unique client_id using uuid.uuid4()
    - Call mjpeg_service.generate_mjpeg_stream(camera_id, client_id)
    - Return StreamingResponse with content_type="multipart/x-mixed-replace; boundary=frame"
    - _Requirements: 1.1, 1.2, 4.1_

  - [ ]* 4.3 Write property test for content type header consistency
    - **Property 3: Content Type Header Consistency**
    - **Validates: Requirements 1.2**

  - [x] 4.3 Implement error handling in stream_camera endpoint
    - Catch CameraNotFoundError and return HTTPException(404, "Camera not found")
    - Catch CameraInactiveError and return HTTPException(400, "Camera is not active")
    - Check if camera is offline and return HTTPException(503, "Camera is offline")
    - _Requirements: 1.3, 1.4, 1.5, 5.1_

  - [x] 4.4 Create dependency injection function for MJPEG service
    - Define `get_mjpeg_service()` function that returns global mjpeg_service instance
    - _Requirements: 10.5_

  - [x] 4.5 Create custom exception classes
    - Define CameraNotFoundError exception class
    - Define CameraInactiveError exception class
    - Define CameraOfflineError exception class
    - _Requirements: 1.3, 1.4, 1.5_

- [ ] 5. Integrate MJPEG endpoint with FastAPI application
  - [x] 5.1 Register MJPEG router in main application
    - Open `attendance-system/app/main.py`
    - Import mjpeg_stream router
    - Call `app.include_router(mjpeg_stream.router, prefix="/api/v1", tags=["streaming"])`
    - _Requirements: 10.6_

  - [x] 5.2 Initialize MJPEG service in application startup
    - Add global mjpeg_service variable
    - In startup_event, create MJPEGStreamService instance
    - Pass video_stream_manager, frame_processor, and db session to constructor
    - _Requirements: 10.5_

  - [ ]* 5.3 Write property test for immediate stream start
    - **Property 11: Immediate Stream Start**
    - **Validates: Requirements 4.1**

- [x] 6. Checkpoint - Verify backend MJPEG implementation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Create frontend MJPEG camera feed component
  - [x] 7.1 Create MJPEGCameraFeed component file
    - Create `attendance-dashboard/app/components/MJPEGCameraFeed.tsx`
    - Import React hooks: useState
    - Define MJPEGCameraFeedProps interface with cameraId, locationName, status, apiBaseUrl
    - Export default function MJPEGCameraFeed component
    - _Requirements: 6.1, 6.2_

  - [x] 7.2 Implement stream URL construction
    - Set default apiBaseUrl to 'http://192.168.0.111:8001'
    - Construct streamUrl as `${apiBaseUrl}/api/v1/cameras/${cameraId}/stream`
    - _Requirements: 6.1_

  - [ ]* 7.3 Write property test for frontend stream URL construction
    - **Property 20: Frontend Stream URL Construction**
    - **Validates: Requirements 6.1**

  - [x] 7.4 Implement loading and error state management
    - Add isLoading state (default true)
    - Add hasError state (default false)
    - Add onLoad handler to set isLoading to false
    - Add onError handler to set hasError to true and isLoading to false
    - _Requirements: 6.3, 6.4_

  - [ ]* 7.5 Write property test for frontend error handling
    - **Property 22: Frontend Error Handling**
    - **Validates: Requirements 6.4**

  - [x] 7.6 Implement img element rendering
    - Render img element with src={streamUrl}
    - Add alt={locationName}
    - Add className="w-full h-full object-cover"
    - Add onLoad and onError handlers
    - Hide img while isLoading is true
    - _Requirements: 6.1, 6.5_

  - [ ]* 7.7 Write property test for frontend CSS application
    - **Property 23: Frontend CSS Application**
    - **Validates: Requirements 6.5**

  - [x] 7.8 Implement status and error message display
    - Show loading indicator when isLoading is true
    - Show error message when hasError is true
    - Show offline message when status is 'offline'
    - Show error message when status is 'error'
    - Display camera location name and ID
    - _Requirements: 6.2, 6.4, 6.6_

  - [ ]* 7.9 Write property test for frontend camera information display
    - **Property 21: Frontend Camera Information Display**
    - **Validates: Requirements 6.2**

  - [ ]* 7.10 Write property test for frontend status display independence
    - **Property 24: Frontend Status Display Independence**
    - **Validates: Requirements 6.6**

  - [x] 7.11 Implement dynamic camera switching
    - Use useEffect hook to watch cameraId prop changes
    - Update img src when cameraId changes
    - Reset loading and error states on camera change
    - _Requirements: 6.7_

  - [ ]* 7.12 Write property test for frontend dynamic camera switching
    - **Property 25: Frontend Dynamic Camera Switching**
    - **Validates: Requirements 6.7**

- [ ] 8. Update cameras page to use MJPEG component
  - [x] 8.1 Replace CameraFeed with MJPEGCameraFeed in cameras page
    - Open `attendance-dashboard/app/cameras/page.tsx`
    - Import MJPEGCameraFeed component
    - Replace CameraFeed component with MJPEGCameraFeed in camera grid
    - Pass cameraId, locationName, and status props
    - Remove frameData prop (no longer needed)
    - _Requirements: 6.1, 6.2, 6.6_

  - [x] 8.2 Remove frame_update message handling from WebSocket
    - Remove frame_update case from onMessage handler
    - Remove frameData state updates
    - Keep attendance_event and camera_status message handling
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ]* 8.3 Write property test for WebSocket message type exclusion
    - **Property 15: WebSocket Message Type Exclusion**
    - **Validates: Requirements 7.1, 7.5**

  - [ ]* 8.4 Write property test for WebSocket event message structure
    - **Property 16: WebSocket Event Message Structure**
    - **Validates: Requirements 7.2, 7.6**

  - [ ]* 8.5 Write property test for WebSocket status message structure
    - **Property 17: WebSocket Status Message Structure**
    - **Validates: Requirements 7.3, 7.7**

- [ ] 9. Remove frame broadcasting from WebSocket manager
  - [x] 9.1 Remove broadcast_frame method from WebSocketManager
    - Open `attendance-system/app/services/websocket.py`
    - Remove broadcast_frame method if it exists
    - Keep broadcast_attendance_event and broadcast_camera_status methods
    - _Requirements: 7.4_

  - [x] 9.2 Remove frame broadcasting from video streaming service
    - Open `attendance-system/app/services/video_streaming.py`
    - Find _process_camera_pipeline or similar frame processing method
    - Remove calls to broadcast_frame or similar frame broadcasting
    - Keep face recognition pipeline intact
    - Keep attendance event broadcasting intact
    - Keep camera status broadcasting intact
    - _Requirements: 7.4, 7.5, 8.5, 8.6, 8.7_

  - [ ]* 9.3 Write property test for face recognition independence
    - **Property 12: Face Recognition Independence**
    - **Validates: Requirements 4.6, 9.6**

  - [ ]* 9.4 Write property test for face recognition pipeline preservation
    - **Property 19: Face Recognition Pipeline Preservation**
    - **Validates: Requirements 8.5, 8.6, 8.7**

- [x] 10. Checkpoint - Verify integration and WebSocket separation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Verify backward compatibility
  - [ ]* 11.1 Write property test for camera API backward compatibility
    - **Property 18: Camera API Backward Compatibility**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**

  - [x] 11.2 Manually test camera CRUD operations
    - Test camera creation via API
    - Test camera listing via API
    - Test camera update via API
    - Test camera deletion via API
    - Verify all operations work as before
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 12. Final integration and testing
  - [x] 12.1 Test MJPEG streaming with single camera
    - Start backend server
    - Open cameras page in browser
    - Verify MJPEG stream displays correctly
    - Verify no browser console errors
    - Verify no backend errors in logs
    - _Requirements: 1.1, 2.1, 6.1_

  - [x] 12.2 Test MJPEG streaming with multiple cameras
    - Add 4 cameras to system
    - Verify all 4 streams display simultaneously
    - Verify no performance degradation
    - Verify CPU usage < 60%
    - Verify memory usage < 1.5 GB
    - _Requirements: 9.1, 9.3, 9.4_

  - [x] 12.3 Test WebSocket event separation
    - Connect to MJPEG stream
    - Connect to WebSocket
    - Verify WebSocket receives attendance events
    - Verify WebSocket receives camera status updates
    - Verify WebSocket does NOT receive frame data
    - _Requirements: 7.1, 7.2, 7.3, 7.5, 7.6, 7.7_

  - [x] 12.4 Test client connection handling
    - Open multiple browser tabs with same camera
    - Verify all tabs receive streams
    - Close one tab and verify others continue streaming
    - Verify backend logs connection/disconnection events
    - _Requirements: 1.6, 1.7, 4.2, 4.3, 4.4, 4.5_

  - [x] 12.5 Test error handling scenarios
    - Disconnect camera and verify offline status
    - Request stream for non-existent camera and verify 404 error
    - Request stream for inactive camera and verify 400 error
    - Verify errors don't crash the service
    - _Requirements: 1.3, 1.4, 1.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 13. Final checkpoint - Complete implementation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional property-based tests and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties from the design document
- The implementation follows an incremental approach: backend → frontend → integration
- All 25 correctness properties from the design are covered by property test tasks
- Face recognition pipeline remains unchanged and continues to operate independently
- WebSocket connections are preserved for events only, not for frame streaming
