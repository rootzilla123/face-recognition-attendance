from pydantic_settings import BaseSettings
from urllib.parse import urlparse


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
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""

    # Resend (email)
    resend_api_key: str = ""
    resend_from_email: str = ""

    # JWT
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440
    
    def validate_secret_key(self):
        """Validate that SECRET_KEY is not a placeholder value."""
        insecure_keys = [
            "your-secret-key-change-this",
            "CHANGE_ME",
            "changeme",
            "secret",
            "password",
            "12345",
        ]
        if self.secret_key.lower() in [k.lower() for k in insecure_keys] or len(self.secret_key) < 32:
            raise ValueError(
                "INSECURE SECRET_KEY detected! Generate a secure key with:\n"
                "  python -c \"import secrets; print(secrets.token_hex(32))\"\n"
                "Then set it in your .env file."
            )

    @staticmethod
    def _looks_placeholder(value: str) -> bool:
        if not value:
            return True
        lowered = value.strip().lower()
        markers = ["change_me", "your-", "changeme", "example", "placeholder"]
        return any(marker in lowered for marker in markers)

    @staticmethod
    def _validate_url(name: str, value: str, allowed_schemes: set[str]):
        parsed = urlparse(value)
        if parsed.scheme not in allowed_schemes or not parsed.netloc:
            raise ValueError(f"{name} must be a valid URL with schemes: {', '.join(sorted(allowed_schemes))}")

    def validate_required_settings(self):
        required = {
            "DATABASE_URL": self.database_url,
            "REDIS_URL": self.redis_url,
            "COMPREFORE_URL": self.comprefore_url,
            "COMPREFORE_API_KEY": self.comprefore_api_key,
            "COMPREFORE_DETECTION_API_KEY": self.comprefore_detection_api_key,
            "SECRET_KEY": self.secret_key,
        }
        missing = [name for name, value in required.items() if not value]
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")

        placeholder_values = [
            name for name, value in required.items()
            if self._looks_placeholder(value)
        ]
        if placeholder_values:
            raise ValueError(f"Placeholder values detected for: {', '.join(placeholder_values)}")

        self._validate_url("DATABASE_URL", self.database_url, {"postgresql", "postgresql+psycopg2"})
        self._validate_url("REDIS_URL", self.redis_url, {"redis", "rediss"})
        self._validate_url("COMPREFORE_URL", self.comprefore_url, {"http", "https"})
        self._validate_url("PB_URL", self.pb_url, {"http", "https"})

        if self.twilio_phone_number and not self.twilio_phone_number.startswith("+"):
            raise ValueError("TWILIO_PHONE_NUMBER must be in E.164 format (e.g. +1234567890)")
        if (self.twilio_account_sid or self.twilio_auth_token or self.twilio_phone_number):
            if not (self.twilio_account_sid and self.twilio_auth_token and self.twilio_phone_number):
                raise ValueError("TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER must be set together")
            if self._looks_placeholder(self.twilio_account_sid) or self._looks_placeholder(self.twilio_auth_token):
                raise ValueError("Twilio credentials contain placeholder values")

        if self.resend_api_key and self._looks_placeholder(self.resend_api_key):
            raise ValueError("RESEND_API_KEY contains a placeholder value")
        if self.resend_api_key and not self.resend_from_email:
            raise ValueError("RESEND_FROM_EMAIL is required when RESEND_API_KEY is set")

        self.validate_secret_key()

    # System
    recognition_threshold: float = 0.95
    duplicate_window_minutes: int = 15

    # Video clips
    clips_dir: str = "/var/attendance_clips"
    clips_retention_days: int = 7

    # Performance
    mjpeg_quality: int = 70
    frame_resize_width: int = 0
    frame_resize_height: int = 0
    cpu_threshold: float = 80.0
    memory_threshold: float = 90.0

    # Firebase (for Google Sign-In token verification)
    firebase_project_id: str = "face-recogniton-attendance"
    google_application_credentials: str = ""

    # PocketBase admin credentials (used for user management)
    pb_url: str = "http://localhost:8092"
    pb_admin_email: str = ""
    pb_admin_password: str = ""

    # Error monitoring (GlitchTip / Sentry-compatible DSN)
    glitchtip_dsn: str = ""

    # AI Chatbot (Ollama)
    ollama_url: str = "http://localhost:11434"
    ollama_model: str = "llama3.2:latest"

    class Config:
        env_file = ".env"


settings = Settings()
settings.validate_required_settings()
