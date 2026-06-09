"""
Firebase Cloud Messaging (FCM) push notification service.

Sends push notifications to mobile devices when:
- Student checks in (parent notification)
- New announcement posted
- System alerts

Requires firebase-admin SDK and service account JSON.
"""
import logging
from typing import Optional, List
from firebase_admin import messaging, credentials, initialize_app
from app.config import settings
import os

logger = logging.getLogger(__name__)

class PushNotificationService:
    """Handles FCM push notifications to mobile devices."""
    
    def __init__(self):
        self._initialized = False
        self._init_firebase()
    
    def _init_firebase(self):
        """Initialize Firebase Admin SDK if credentials are available."""
        try:
            cred_path = settings.google_application_credentials
            if not cred_path or not os.path.exists(cred_path):
                logger.warning("Firebase credentials not found - push notifications disabled")
                return
            
            cred = credentials.Certificate(cred_path)
            initialize_app(cred)
            self._initialized = True
            logger.info("Firebase Admin SDK initialized successfully")
        except Exception as e:
            logger.warning(f"Firebase init failed (push notifications disabled): {e}")
    
    def send_push(
        self,
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> dict:
        """
        Send push notification to one or more device tokens.
        
        Args:
            tokens: List of FCM device tokens
            title: Notification title
            body: Notification body text
            data: Optional custom data payload
        
        Returns:
            dict with status and results
        """
        if not self._initialized:
            return {"status": "skipped", "reason": "Firebase not initialized"}
        
        if not tokens:
            return {"status": "skipped", "reason": "No device tokens provided"}
        
        # Filter out empty/invalid tokens
        valid_tokens = [t for t in tokens if t and isinstance(t, str) and len(t) > 20]
        if not valid_tokens:
            return {"status": "skipped", "reason": "No valid device tokens"}
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=valid_tokens,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        channel_id='attendance_alerts',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            response = messaging.send_multicast(message)
            
            # Log failures
            if response.failure_count > 0:
                failed_tokens = [
                    valid_tokens[idx] for idx, resp in enumerate(response.responses)
                    if not resp.success
                ]
                logger.warning(f"Push notification failed for {response.failure_count} tokens: {failed_tokens[:3]}")
            
            logger.info(f"Push notification sent: {response.success_count} succeeded, {response.failure_count} failed")
            
            return {
                "status": "sent",
                "success_count": response.success_count,
                "failure_count": response.failure_count,
            }
        
        except Exception as e:
            logger.error(f"Push notification error: {e}")
            return {"status": "failed", "error": str(e)}
    
    def send_to_user(
        self,
        user,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> dict:
        """
        Send push notification to a specific user (uses device_tokens from User model).
        
        Args:
            user: User model instance
            title: Notification title
            body: Notification body text
            data: Optional custom data payload
        
        Returns:
            dict with status and results
        """
        tokens = user.device_tokens or []
        if not tokens:
            return {"status": "skipped", "reason": "User has no device tokens"}
        
        return self.send_push(tokens, title, body, data)
