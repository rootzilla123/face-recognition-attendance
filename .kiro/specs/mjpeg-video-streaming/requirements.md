# Requirements Document

## Introduction

This document specifies the requirements for implementing MJPEG (Motion JPEG) video streaming to replace the current WebSocket-based video streaming in the face recognition attendance system. The current WebSocket implementation causes browser freezing, constant disconnections, and blinking online/offline status due to large base64-encoded JPEG frames overwhelming the browser. The MJPEG solution will use HTTP multipart responses for efficient video streaming while maintaining WebSocket connections only for attendance events and camera status updates.

## Glossary

- **MJPEG_Stream_Service**: Backend service that generates MJPEG streams from camera sources
- **HTTP_Multipart_Response**: HTTP response using multipart/x-mixed-replace content type for streaming
- **Camera_Stream_Endpoint**: HTTP endpoint that serves MJPEG stream for a specific camera
- **Frame_Generator**: Component that captures and encodes frames from video sources
- **Stream_Client**: Frontend component that displays MJPEG streams using HTML img tags
- **WebSocket_Manager**: Existing service for real-time event communication
- **Video_Stream_Manager**: Existing service that manages camera connections and frame capture
- **Frame_Processor**: Existing service that encodes frames to JPEG format
- **Camera**: Physical or virtual camera device with RTSP/HTTP/local stream source
- **Frame_Rate**: Number of frames per second delivered to clients (1-10 FPS)
- **JPEG_Quality**: Compression quality for JPEG encoding (1-100)
- **Boundary_Marker**: Unique string delimiter for multipart HTTP responses

## Requirements

### Requirement 1: MJPEG Stream Endpoint

**User Story:** As a system administrator, I want each camera to have its own MJPEG stream endpoint, so that clients can access video feeds independently without WebSocket overhead.

#### Acceptance Criteria

1. THE Camera_Stream_Endpoint SHALL be accessible at `/api/v1/cameras/{camera_id}/stream`
2. WHEN a client requests the Camera_Stream_Endpoint, THE MJPEG_Stream_Service SHALL return an HTTP response with content type `multipart/x-mixed-replace; boundary=frame`
3. THE Camera_Stream_Endpoint SHALL validate that the camera_id exists in the database
4. IF the camera_id does not exist, THEN THE Camera_Stream_Endpoint SHALL return HTTP 404 with error message "Camera not found"
5. IF the camera is not active, THEN THE Camera_Stream_Endpoint SHALL return HTTP 400 with error message "Camera is not active"
6. THE Camera_Stream_Endpoint SHALL support concurrent connections from multiple clients
7. WHEN a client disconnects, THE MJPEG_Stream_Service SHALL clean up the connection resources

### Requirement 2: MJPEG Frame Streaming

**User Story:** As a frontend developer, I want the MJPEG stream to deliver frames in the correct multipart format, so that browsers can display the video feed natively.

#### Acceptance Criteria

1. THE MJPEG_Stream_Service SHALL generate frames using the multipart/x-mixed-replace protocol
2. FOR EACH frame, THE MJPEG_Stream_Service SHALL send headers: `Content-Type: image/jpeg`, `Content-Length: {size}`, followed by JPEG data and boundary marker
3. THE MJPEG_Stream_Service SHALL use the Boundary_Marker `--frame` to separate consecutive frames
4. THE MJPEG_Stream_Service SHALL encode frames as JPEG using the Frame_Processor
5. THE MJPEG_Stream_Service SHALL respect the camera's configured Frame_Rate setting
6. WHEN the Video_Stream_Manager fails to read a frame, THE MJPEG_Stream_Service SHALL skip that frame and continue streaming
7. THE MJPEG_Stream_Service SHALL maintain frame delivery at the configured Frame_Rate with tolerance of ±10%

### Requirement 3: Frame Rate and Quality Control

**User Story:** As a system administrator, I want to control frame rate and JPEG quality per camera, so that I can balance bandwidth usage and video quality.

#### Acceptance Criteria

1. THE MJPEG_Stream_Service SHALL read the Frame_Rate setting from the Camera database record
2. THE MJPEG_Stream_Service SHALL support Frame_Rate values between 1 and 10 FPS
3. THE MJPEG_Stream_Service SHALL use JPEG_Quality of 70 for MJPEG streams
4. WHERE the camera's Frame_Rate is updated in the database, THE MJPEG_Stream_Service SHALL apply the new rate within 5 seconds
5. THE MJPEG_Stream_Service SHALL calculate frame interval as `1.0 / Frame_Rate` seconds
6. WHILE streaming, THE MJPEG_Stream_Service SHALL wait for the frame interval between consecutive frames

### Requirement 4: Connection Management

**User Story:** As a system operator, I want the MJPEG stream to handle client connections gracefully, so that disconnections don't affect other clients or the camera processing pipeline.

#### Acceptance Criteria

1. WHEN a client connects to the Camera_Stream_Endpoint, THE MJPEG_Stream_Service SHALL start streaming frames immediately
2. WHEN a client disconnects, THE MJPEG_Stream_Service SHALL detect the disconnection within 2 seconds
3. IF a client disconnection is detected, THEN THE MJPEG_Stream_Service SHALL stop streaming to that client
4. THE MJPEG_Stream_Service SHALL continue streaming to other connected clients when one client disconnects
5. THE MJPEG_Stream_Service SHALL log client connection and disconnection events with camera_id and timestamp
6. WHEN no clients are connected to a camera stream, THE MJPEG_Stream_Service SHALL continue capturing frames for face recognition processing

### Requirement 5: Error Handling

**User Story:** As a system operator, I want the MJPEG stream to handle errors gracefully, so that temporary issues don't crash the streaming service.

#### Acceptance Criteria

1. IF the Video_Stream_Manager reports a camera as offline, THEN THE Camera_Stream_Endpoint SHALL return HTTP 503 with error message "Camera is offline"
2. IF frame encoding fails, THEN THE MJPEG_Stream_Service SHALL log the error and skip that frame
3. IF the camera connection is lost during streaming, THEN THE MJPEG_Stream_Service SHALL close all client connections with appropriate error
4. WHEN an exception occurs during frame streaming, THE MJPEG_Stream_Service SHALL log the exception with camera_id and error details
5. THE MJPEG_Stream_Service SHALL not terminate the entire service when one camera stream encounters an error
6. IF a client connection write fails, THEN THE MJPEG_Stream_Service SHALL close that specific client connection

### Requirement 6: Frontend Stream Display Component

**User Story:** As a frontend developer, I want a React component that displays MJPEG streams using img tags, so that I can replace the WebSocket-based video display.

#### Acceptance Criteria

1. THE Stream_Client SHALL render an HTML img element with src attribute pointing to the Camera_Stream_Endpoint
2. THE Stream_Client SHALL display the camera location name and camera ID
3. THE Stream_Client SHALL show a loading indicator while the stream is connecting
4. IF the img element fails to load, THEN THE Stream_Client SHALL display an error message
5. THE Stream_Client SHALL apply CSS class `object-cover` to maintain aspect ratio
6. THE Stream_Client SHALL display camera status indicator (online/offline/error) independent of the MJPEG stream
7. WHEN the camera_id prop changes, THE Stream_Client SHALL update the img src to the new camera's stream endpoint

### Requirement 7: WebSocket Separation

**User Story:** As a system architect, I want WebSocket connections to handle only events and status updates, so that we eliminate the bandwidth issues caused by streaming video frames over WebSocket.

#### Acceptance Criteria

1. THE WebSocket_Manager SHALL not send frame_update messages
2. THE WebSocket_Manager SHALL continue sending attendance_event messages
3. THE WebSocket_Manager SHALL continue sending camera_status messages
4. THE Stream_Broadcaster SHALL not call broadcast_frame method
5. THE VideoStreamingService SHALL not include frame data in WebSocket messages
6. WHEN an attendance event occurs, THE WebSocket_Manager SHALL broadcast the event with student_id, student_name, camera_location, timestamp, and confidence_score
7. WHEN a camera status changes, THE WebSocket_Manager SHALL broadcast the status with camera_id, status, and error_message

### Requirement 8: Backward Compatibility

**User Story:** As a system administrator, I want the existing camera management features to continue working, so that the MJPEG implementation doesn't break existing functionality.

#### Acceptance Criteria

1. THE Camera registration API SHALL continue to accept the same request format
2. THE Camera update API SHALL continue to support updating name, location, stream_url, protocol, is_active, and frame_rate
3. THE Camera list API SHALL continue to return all camera records
4. THE Camera delete API SHALL continue to remove cameras from the system
5. THE Video_Stream_Manager SHALL continue to capture frames for face recognition processing
6. THE Face recognition pipeline SHALL continue to process frames independently of MJPEG streaming
7. THE Attendance marking logic SHALL remain unchanged

### Requirement 9: Performance Requirements

**User Story:** As a system operator, I want the MJPEG streaming to be efficient, so that the system can handle 4 simultaneous camera streams without performance degradation.

#### Acceptance Criteria

1. THE MJPEG_Stream_Service SHALL support at least 4 concurrent camera streams
2. THE MJPEG_Stream_Service SHALL support at least 10 concurrent client connections per camera
3. WHEN streaming 4 cameras at 5 FPS, THE system SHALL maintain CPU usage below 60%
4. WHEN streaming 4 cameras at 5 FPS, THE system SHALL maintain memory usage below 1.5 GB
5. THE MJPEG_Stream_Service SHALL deliver frames with latency less than 500ms from capture to client display
6. THE MJPEG_Stream_Service SHALL not block the face recognition processing pipeline

### Requirement 10: Integration with Existing Services

**User Story:** As a developer, I want the MJPEG streaming to integrate with existing services, so that I can reuse the Video_Stream_Manager and Frame_Processor components.

#### Acceptance Criteria

1. THE MJPEG_Stream_Service SHALL use the Video_Stream_Manager to read frames from cameras
2. THE MJPEG_Stream_Service SHALL use the Frame_Processor.encode_frame_jpeg method to encode frames
3. THE MJPEG_Stream_Service SHALL access camera configuration from the Camera database model
4. THE MJPEG_Stream_Service SHALL use the same logging configuration as other services
5. THE MJPEG_Stream_Service SHALL be initialized in the FastAPI application startup
6. THE Camera_Stream_Endpoint SHALL be registered in the FastAPI router with prefix `/api/v1`
