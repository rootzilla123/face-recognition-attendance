"""
Script to drop and recreate cameras table with correct schema.
"""

import psycopg2
from app.config import settings

def fix_cameras_table():
    """Drop and recreate cameras table."""
    try:
        # Connect to database
        conn = psycopg2.connect(settings.database_url)
        cursor = conn.cursor()
        
        print("Dropping existing cameras table...")
        cursor.execute("DROP TABLE IF EXISTS cameras CASCADE")
        conn.commit()
        
        print("Creating cameras table with new schema...")
        create_table_sql = """
        CREATE TABLE cameras (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            location VARCHAR(100) NOT NULL,
            stream_url VARCHAR(500) NOT NULL,
            protocol VARCHAR(20) NOT NULL,
            username VARCHAR(100),
            password VARCHAR(100),
            status VARCHAR(20) DEFAULT 'offline',
            is_active BOOLEAN DEFAULT TRUE,
            frame_rate INTEGER DEFAULT 5,
            last_seen TIMESTAMP WITH TIME ZONE,
            error_message TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE
        );
        """
        cursor.execute(create_table_sql)
        conn.commit()
        
        print("Creating indexes...")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_cameras_status ON cameras(status)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_cameras_is_active ON cameras(is_active)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_cameras_location ON cameras(location)")
        conn.commit()
        
        print("✅ Cameras table fixed successfully!")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Failed to fix cameras table: {str(e)}")
        raise

if __name__ == "__main__":
    fix_cameras_table()
