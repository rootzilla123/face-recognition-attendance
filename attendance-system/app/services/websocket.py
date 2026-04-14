"""
WebSocket management for real-time video streaming and attendance notifications.
"""

import asyncio
import json
import logging
from typing import Dict, Set
from fastapi import WebSocket
import uuid

logger = logging.getLogger(__name__)


class WebSocketManager:
    """
    Manages WebSocket connections for real-time communication with dashboard clients.
    Handles client registration, message broadcasting, and heartbeat monitoring.
    """
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.heartbeat_tasks: Dict[str, asyncio.Task] = {}
        self.heartbeat_interval = 30  # seconds
        
    async def connect(self, websocket: WebSocket) -> str:
        """
        Register a new WebSocket client connection.
        
        Args:
            websocket: WebSocket connection instance
            
        Returns:
            str: Unique client ID
        """
        await websocket.accept()
        
        # Generate unique client ID
        client_id = str(uuid.uuid4())
        
        # Store connection
        self.active_connections[client_id] = websocket
        
        # Start heartbeat for this client
        heartbeat_task = asyncio.create_task(self._heartbeat(client_id, websocket))
        self.heartbeat_tasks[client_id] = heartbeat_task
        
        logger.info(f"WebSocket client connected: {client_id} (total: {len(self.active_connections)})")
        
        return client_id
    
    async def disconnect(self, client_id: str):
        """
        Unregister and clean up a WebSocket client connection.
        
        Args:
            client_id: Unique client identifier
        """
        # Cancel heartbeat task
        if client_id in self.heartbeat_tasks:
            self.heartbeat_tasks[client_id].cancel()
            try:
                await self.heartbeat_tasks[client_id]
            except asyncio.CancelledError:
                pass
            del self.heartbeat_tasks[client_id]
        
        # Remove connection
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            logger.info(f"WebSocket client disconnected: {client_id} (remaining: {len(self.active_connections)})")
    
    async def send_message(self, client_id: str, message: dict) -> bool:
        """
        Send a message to a specific client.
        
        Args:
            client_id: Unique client identifier
            message: Message dictionary to send (will be JSON encoded)
            
        Returns:
            bool: True if sent successfully, False otherwise
        """
        if client_id not in self.active_connections:
            logger.warning(f"Cannot send message to unknown client: {client_id}")
            return False
        
        try:
            websocket = self.active_connections[client_id]
            await websocket.send_json(message)
            return True
        except Exception as e:
            logger.error(f"Error sending message to client {client_id}: {str(e)}")
            await self.disconnect(client_id)
            return False
    
    async def broadcast(self, message: dict, exclude_client: str = None):
        """
        Broadcast a message to all connected clients.
        
        Args:
            message: Message dictionary to broadcast (will be JSON encoded)
            exclude_client: Optional client ID to exclude from broadcast
        """
        if len(self.active_connections) == 0:
            return
        
        disconnected_clients = []
        
        for client_id, websocket in self.active_connections.items():
            if exclude_client and client_id == exclude_client:
                continue
            
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to client {client_id}: {str(e)}")
                disconnected_clients.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            await self.disconnect(client_id)
    
    async def _heartbeat(self, client_id: str, websocket: WebSocket):
        """
        Send periodic ping messages to detect disconnected clients.
        
        Args:
            client_id: Unique client identifier
            websocket: WebSocket connection instance
        """
        try:
            while True:
                await asyncio.sleep(self.heartbeat_interval)
                
                # Send ping
                try:
                    await websocket.send_json({"type": "ping", "timestamp": asyncio.get_event_loop().time()})
                except Exception as e:
                    logger.warning(f"Heartbeat failed for client {client_id}: {str(e)}")
                    await self.disconnect(client_id)
                    break
                    
        except asyncio.CancelledError:
            # Task was cancelled (normal during disconnect)
            pass
        except Exception as e:
            logger.error(f"Error in heartbeat for client {client_id}: {str(e)}")
    
    def get_connection_count(self) -> int:
        """
        Get the number of active WebSocket connections.
        
        Returns:
            int: Number of active connections
        """
        return len(self.active_connections)
    
    def is_client_connected(self, client_id: str) -> bool:
        """
        Check if a client is currently connected.
        
        Args:
            client_id: Unique client identifier
            
        Returns:
            bool: True if connected, False otherwise
        """
        return client_id in self.active_connections
