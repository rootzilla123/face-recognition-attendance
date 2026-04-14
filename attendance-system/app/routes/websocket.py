"""
WebSocket routes for real-time video streaming and attendance notifications.
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# WebSocket manager will be injected at startup
websocket_manager = None


def set_websocket_manager(manager):
    """Set the WebSocket manager instance."""
    global websocket_manager
    websocket_manager = manager


@router.websocket("/ws")
@router.websocket("/ws/attendance")
async def websocket_attendance_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time attendance updates and video streaming.
    
    Clients connect to this endpoint to receive:
    - Live video frames from cameras
    - Real-time attendance notifications
    - Camera status updates
    """
    if websocket_manager is None:
        logger.error("WebSocket manager not initialized")
        await websocket.close(code=1011, reason="Server not ready")
        return
    
    client_id = None
    
    try:
        # Accept and register connection
        client_id = await websocket_manager.connect(websocket)
        
        # Send welcome message
        await websocket_manager.send_message(client_id, {
            "type": "connected",
            "client_id": client_id,
            "message": "Connected to attendance system"
        })
        
        # Keep connection alive and handle incoming messages
        while True:
            try:
                # Receive messages from client (e.g., pong responses)
                data = await websocket.receive_json()
                
                # Handle pong responses
                if data.get("type") == "pong":
                    logger.debug(f"Received pong from client {client_id}")
                
            except WebSocketDisconnect:
                logger.info(f"Client {client_id} disconnected normally")
                break
            except Exception as e:
                logger.error(f"Error receiving message from client {client_id}: {str(e)}")
                break
                
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
    finally:
        # Clean up connection
        if client_id:
            await websocket_manager.disconnect(client_id)
