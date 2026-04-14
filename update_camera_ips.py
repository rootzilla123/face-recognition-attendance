"""
Update camera IP addresses in the database after DHCP change.
Changes all cameras from 192.168.0.104 to 192.168.0.100
"""
import asyncio
from sqlalchemy import create_engine, text
from app.config import settings

async def update_camera_ips():
    """Update camera IPs from old to new address"""
    old_ip = "192.168.0.104"
    new_ip = "192.168.0.100"
    
    # Create synchronous engine for simple update
    engine = create_engine(settings.database_url.replace('+asyncpg', ''))
    
    with engine.connect() as conn:
        # Update all cameras with old IP to new IP
        result = conn.execute(
            text("""
                UPDATE cameras 
                SET stream_url = REPLACE(stream_url, :old_ip, :new_ip),
                    error_message = NULL,
                    status = 'active'
                WHERE stream_url LIKE :pattern
            """),
            {"old_ip": old_ip, "new_ip": new_ip, "pattern": f"%{old_ip}%"}
        )
        conn.commit()
        
        print(f"✓ Updated {result.rowcount} camera(s)")
        print(f"  Changed IP: {old_ip} → {new_ip}")
        
        # Show updated cameras
        cameras = conn.execute(text("SELECT id, name, stream_url, status FROM cameras"))
        print("\nUpdated cameras:")
        for cam in cameras:
            print(f"  ID {cam.id}: {cam.name}")
            print(f"    URL: {cam.stream_url}")
            print(f"    Status: {cam.status}")

if __name__ == "__main__":
    asyncio.run(update_camera_ips())
