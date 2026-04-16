from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    database_url: str

    # Redis
    redis_url: str

    # CompreFace
    comprefore_url: str
    comprefore_api_key: str
    comprefore_detection_api_key: str

    # Twilio
    twilio_account_sid: str
    twilio_auth_token: str
    twilio_phone_number: str

    # Resend (email)
    resend_api_key: str
    resend_from_email: str

    # JWT
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    # System
    recognition_threshold: float = 0.95
    duplicate_window_minutes: int = 15

    # Performance
    mjpeg_quality: int = 70
    frame_resize_width: int = 0
    frame_resize_height: int = 0
    cpu_threshold: float = 80.0
    memory_threshold: float = 90.0

    # Error monitoring (GlitchTip / Sentry-compatible DSN)
    glitchtip_dsn: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
