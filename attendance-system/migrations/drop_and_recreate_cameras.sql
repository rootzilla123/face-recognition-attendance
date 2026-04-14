-- Drop existing cameras table and recreate with new schema
DROP TABLE IF EXISTS cameras CASCADE;

-- Create cameras table with new schema
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cameras_status ON cameras(status);
CREATE INDEX IF NOT EXISTS idx_cameras_is_active ON cameras(is_active);
CREATE INDEX IF NOT EXISTS idx_cameras_location ON cameras(location);
