import requests
from app.config import settings

class CompreFaceService:
    def __init__(self):
        self.api_url = settings.comprefore_url
        self.api_key = settings.comprefore_api_key
    
    def detect_faces(self, image_path: str):
        """Detect faces in image"""
        with open(image_path, 'rb') as f:
            response = requests.post(
                f"{self.api_url}/api/v1/detection/detect",
                files={'file': f},
                headers={'x-api-key': self.api_key}
            )
        return response.json()
    
    def recognize_face(self, image_path: str):
        """Recognize which student this face belongs to"""
        with open(image_path, 'rb') as f:
            response = requests.post(
                f"{self.api_url}/api/v1/recognition/recognize",
                files={'file': f},
                headers={'x-api-key': self.api_key}
            )
        return response.json()
    
    def enroll_face(self, student_id: str, image_path: str):
        """Enroll a student's face"""
        with open(image_path, 'rb') as f:
            response = requests.post(
                f"{self.api_url}/api/v1/recognition/faces",
                files={'file': f},
                data={'subject': student_id},
                headers={'x-api-key': self.api_key}
            )
        return response.json()
