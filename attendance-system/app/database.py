from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
from app.config import settings
import logging

logger = logging.getLogger(__name__)

engine = create_engine(
    settings.database_url,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=30,
    pool_timeout=30,
    pool_pre_ping=True,
    pool_recycle=3600,  # Recycle connections after 1 hour
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_connection_stats():
    """Get current database connection statistics"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    count(*) as total_connections,
                    count(*) FILTER (WHERE state = 'active') as active_connections,
                    count(*) FILTER (WHERE state = 'idle') as idle_connections,
                    max_conn.setting::int as max_connections
                FROM pg_stat_activity
                CROSS JOIN (SELECT setting FROM pg_settings WHERE name = 'max_connections') max_conn
                WHERE datname = current_database()
            """))
            row = result.fetchone()
            stats = {
                "total": row[0],
                "active": row[1],
                "idle": row[2],
                "max": row[3],
                "usage_percent": round((row[0] / row[3]) * 100, 2),
                "pool_size": engine.pool.size(),
                "pool_checked_out": engine.pool.checkedout(),
            }
            
            # Log warning if usage is high
            if stats["usage_percent"] > 80:
                logger.warning(f"High database connection usage: {stats['usage_percent']}% ({stats['total']}/{stats['max']})")
            
            return stats
    except Exception as e:
        logger.error(f"Failed to get connection stats: {e}")
        return {
            "error": str(e),
            "pool_size": engine.pool.size(),
            "pool_checked_out": engine.pool.checkedout(),
        }
