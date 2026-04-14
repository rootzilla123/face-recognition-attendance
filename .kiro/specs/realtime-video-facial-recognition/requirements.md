# Requirements Document

## Introduction

This document specifies requirements for implementing real-time video streaming and facial recognition capabilities in the school attendance system. The system will capture video from 4 camera sources, process frames to detect and recognize student faces using CompreFace API, and automatically mark attendance records. The solution must handle 500+ students efficiently while preventing duplicate attendance entries within a configurable time window.

## Glossary

- **Video_Stream_Manager**: Backend service responsible for capturing and managing video streams from camera sources
- **Frame_Processor**: Component that extracts individual frames from video streams for face detection
- **Face_Detector**: Service that identifies face regions within video frames using CompreFace detection API
- **Face_Recognizer**: Service that matches detected faces against enrolled student database using CompreFace recognition API
- **Attendance_Marker**: Service that creates attendance records when students are successfully recognized
- **Stream_Broadcaster**: Component that transmits video frames and recognition data to connected dashboard clients
- **WebSocket_Server**: Real-time bidirectional communication server for pushing attendance events to clients
- **Camera_Feed_Display**: Frontend component that renders live video streams with recognition overlays
- **Recognition_Overlay**: Visual indicator displayed on video feed showing detected face bounding boxes and student identification
- **Duplicate_Filter**: Component that prevents marking attendance for the same student within the configured time window
- **Camera_Source**: Physical or network camera device providing video input (4 total: main_gate, classroom_building, cafeteria, exit_gate)
- **Frame_Rate**: Number of frames processed per second for face detection (measured in FPS)
- **Recognition_Confidence**: Similarity score from CompreFace indicating match certainty (0.0 to 1.0)
- **Time_Window**: Duration in minutes during which duplicate attendance entries are prevented (DUPLICATE_WINDOW_MINUTES)

## Requirements

### Requirement 1: Video Stream Capture

**User Story:** As a system administrator, I want the system to capture video from 4 camera sources simultaneously, so that all school entry/exit points are monitored for attendance.

#### Acceptance Criteria

1. THE Video_Stream_Manager SHALL support concurrent video capture from 4 Camera_Sources
2. WHEN a Camera_Source connection is established, THE Video_Stream_Manager SHALL begin capturing video frames
3. THE Video_Stream_Manager SHALL maintain camera configuration including camera_id, location_name, and stream_url for each Camera_Source
4. IF a Camera_Source connection fails, THEN THE Video_Stream_Manager SHALL log the error and mark the camera status as offline
5. THE Video_Stream_Manager SHALL support RTSP, HTTP, and local device camera protocols
6. WHEN a Camera_Source is offline, THE Video_Stream_Manager SHALL attempt reconnection every 30 seconds

### Requirement 2: Frame Extraction and Processing

**User Story:** As a system operator, I want video frames to be extracted and processed efficiently, so that face detection can occur in real-time without overwhelming system resources.

#### Acceptance Criteria

1. THE Frame_Processor SHALL extract frames from each video stream at a configurable Frame_Rate between 1 and 10 FPS
2. THE Frame_Processor SHALL convert extracted frames to JPEG format for CompreFace API compatibility
3. WHEN system CPU usage exceeds 80%, THE Frame_Processor SHALL reduce Frame_Rate by 50%
4. THE Frame_Processor SHALL maintain a processing queue with maximum size of 100 frames per camera
5. IF the processing queue reaches capacity, THEN THE Frame_Processor SHALL drop oldest frames to prevent memory overflow
6. THE Frame_Processor SHALL process frames from all 4 cameras in parallel using separate threads or async tasks

### Requirement 3: Face Detection

**User Story:** As a system operator, I want faces to be detected in video frames, so that only frames containing faces are sent for recognition processing.

#### Acceptance Criteria

1. WHEN a frame is extracted, THE Face_Detector SHALL send the frame to CompreFace detection API
2. THE Face_Detector SHALL identify bounding box coordinates for each detected face in the frame
3. IF no faces are detected in a frame, THEN THE Face_Detector SHALL discard the frame and process the next frame
4. WHEN multiple faces are detected in a single frame, THE Face_Detector SHALL process each face independently
5. THE Face_Detector SHALL include face bounding box coordinates (x, y, width, height) in detection results
6. IF CompreFace detection API returns an error, THEN THE Face_Detector SHALL log the error and retry up to 2 times with 1 second delay

### Requirement 4: Face Recognition

**User Story:** As a system operator, I want detected faces to be matched against enrolled students, so that students can be automatically identified for attendance marking.

#### Acceptance Criteria

1. WHEN a face is detected, THE Face_Recognizer SHALL send the face image to CompreFace recognition API
2. THE Face_Recognizer SHALL retrieve the student_id and Recognition_Confidence score from CompreFace response
3. IF Recognition_Confidence is below 0.85, THEN THE Face_Recognizer SHALL discard the recognition result as unconfident
4. WHEN Recognition_Confidence is 0.85 or above, THE Face_Recognizer SHALL pass the student_id and confidence to Attendance_Marker
5. IF no matching student is found, THEN THE Face_Recognizer SHALL log an unknown face event with timestamp and camera location
6. THE Face_Recognizer SHALL include camera_location and timestamp metadata with each recognition result

### Requirement 5: Automatic Attendance Marking

**User Story:** As a school administrator, I want attendance to be marked automatically when students are recognized, so that manual attendance tracking is eliminated.

#### Acceptance Criteria

1. WHEN a student is recognized with sufficient confidence, THE Attendance_Marker SHALL create an attendance record
2. THE Attendance_Marker SHALL include student_id, camera_location, timestamp, and Recognition_Confidence in the attendance record
3. THE Attendance_Marker SHALL invoke Duplicate_Filter before creating the attendance record
4. WHEN Duplicate_Filter indicates a duplicate, THE Attendance_Marker SHALL skip record creation and log the duplicate event
5. THE Attendance_Marker SHALL persist attendance records to PostgreSQL database
6. WHEN an attendance record is successfully created, THE Attendance_Marker SHALL publish an attendance event to Stream_Broadcaster

### Requirement 6: Duplicate Prevention

**User Story:** As a school administrator, I want to prevent duplicate attendance entries when a student passes the same camera multiple times, so that attendance records remain accurate.

#### Acceptance Criteria

1. THE Duplicate_Filter SHALL check Redis cache for existing attendance within the Time_Window for the student and camera combination
2. WHEN a student has existing attendance for the same camera within Time_Window, THE Duplicate_Filter SHALL return duplicate status
3. WHEN no duplicate is found, THE Duplicate_Filter SHALL cache the attendance event in Redis with TTL equal to Time_Window in seconds
4. THE Duplicate_Filter SHALL use cache key format "attendance:recent:{student_id}:{camera_location}"
5. THE Duplicate_Filter SHALL read Time_Window value from DUPLICATE_WINDOW_MINUTES configuration setting
6. IF Redis connection fails, THEN THE Duplicate_Filter SHALL log the error and allow attendance marking to proceed

### Requirement 7: Real-Time Video Streaming to Dashboard

**User Story:** As a school administrator, I want to view live camera feeds on the dashboard, so that I can monitor attendance activity in real-time.

#### Acceptance Criteria

1. THE Stream_Broadcaster SHALL transmit video frames to connected dashboard clients via WebSocket_Server
2. THE Stream_Broadcaster SHALL encode frames in JPEG format with 70% quality to optimize bandwidth
3. THE Stream_Broadcaster SHALL send frames at maximum 5 FPS to each connected client
4. WHEN a client connects, THE Stream_Broadcaster SHALL send the current frame from all 4 cameras immediately
5. THE Stream_Broadcaster SHALL include camera_id and timestamp metadata with each transmitted frame
6. IF no clients are connected, THEN THE Stream_Broadcaster SHALL pause frame transmission to conserve resources

### Requirement 8: Real-Time Recognition Overlays

**User Story:** As a school administrator, I want to see visual indicators on camera feeds when students are recognized, so that I can verify the system is working correctly.

#### Acceptance Criteria

1. WHEN a face is detected, THE Stream_Broadcaster SHALL include face bounding box coordinates in the frame data
2. WHEN a student is recognized, THE Stream_Broadcaster SHALL include student name and Recognition_Confidence in the frame data
3. THE Camera_Feed_Display SHALL render Recognition_Overlay with green bounding box for recognized students
4. THE Camera_Feed_Display SHALL render Recognition_Overlay with yellow bounding box for detected but unrecognized faces
5. THE Recognition_Overlay SHALL display student name and confidence percentage above the bounding box
6. THE Recognition_Overlay SHALL remain visible for 3 seconds after recognition

### Requirement 9: WebSocket Communication

**User Story:** As a dashboard user, I want to receive real-time attendance notifications, so that I am immediately informed when students arrive.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL accept client connections on endpoint /ws/attendance
2. WHEN an attendance record is created, THE WebSocket_Server SHALL broadcast an attendance event to all connected clients
3. THE WebSocket_Server SHALL include student_id, student_name, camera_location, timestamp, and confidence_score in attendance events
4. THE WebSocket_Server SHALL send camera status updates (online/offline) to connected clients
5. WHEN a client disconnects, THE WebSocket_Server SHALL clean up the connection and remove it from broadcast list
6. THE WebSocket_Server SHALL implement ping/pong heartbeat every 30 seconds to detect disconnected clients

### Requirement 10: Performance Optimization

**User Story:** As a system operator, I want the system to handle 4 concurrent video streams efficiently, so that system resources are not exhausted and recognition remains responsive.

#### Acceptance Criteria

1. THE Video_Stream_Manager SHALL process all 4 camera streams using asynchronous I/O operations
2. THE Frame_Processor SHALL limit concurrent CompreFace API requests to 8 maximum across all cameras
3. THE System SHALL maintain average frame processing latency below 500ms from capture to recognition result
4. THE System SHALL limit memory usage to 2GB maximum for video processing components
5. WHEN memory usage exceeds 1.8GB, THE Frame_Processor SHALL reduce Frame_Rate by 25%
6. THE System SHALL process at least 500 unique student recognitions per hour across all cameras

### Requirement 11: Camera Management API

**User Story:** As a system administrator, I want to configure camera settings via API, so that I can add, update, or remove cameras without code changes.

#### Acceptance Criteria

1. THE System SHALL provide REST API endpoint POST /api/v1/cameras to register new Camera_Sources
2. THE System SHALL provide REST API endpoint PUT /api/v1/cameras/{camera_id} to update camera configuration
3. THE System SHALL provide REST API endpoint DELETE /api/v1/cameras/{camera_id} to remove cameras
4. THE System SHALL provide REST API endpoint GET /api/v1/cameras to list all configured cameras with status
5. WHEN camera configuration is updated, THE Video_Stream_Manager SHALL reload the camera connection within 5 seconds
6. THE System SHALL persist camera configuration to PostgreSQL database

### Requirement 12: Error Handling and Logging

**User Story:** As a system operator, I want comprehensive error logging, so that I can troubleshoot issues with video streaming and recognition.

#### Acceptance Criteria

1. WHEN any component encounters an error, THE System SHALL log the error with timestamp, component name, and error details
2. THE System SHALL log camera connection failures with camera_id and failure reason
3. THE System SHALL log CompreFace API errors with request details and response status
4. THE System SHALL log recognition events including student_id, confidence, and camera_location
5. THE System SHALL log duplicate attendance attempts with student_id and time since last attendance
6. THE System SHALL provide log level configuration (DEBUG, INFO, WARNING, ERROR) via environment variable
