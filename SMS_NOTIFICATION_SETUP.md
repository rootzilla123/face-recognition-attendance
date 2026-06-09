# SMS Notification Setup Guide

This guide will help you configure SMS notifications for the Face Recognition Attendance System using Twilio.

## Features

The system sends SMS notifications based on user roles:

### Parents
- **Attendance Alerts**: Receive SMS when their child checks in
- **Announcements**: Get important school announcements via SMS
- **Customizable**: Can enable/disable SMS, email, and in-app notifications

### Teachers
- **Absence Alerts**: Get notified when students are absent
- **Announcements**: Receive school-wide announcements
- **System Updates**: Important system notifications

### Admins
- **System Alerts**: Camera offline, errors, security alerts
- **Critical Events**: Immediate SMS for urgent issues
- **Announcements**: All system-wide communications

## Setup Instructions

### 1. Create a Twilio Account

1. Go to [Twilio.com](https://www.twilio.com/try-twilio)
2. Sign up for a free trial account
3. Verify your email and phone number

### 2. Get Your Twilio Credentials

1. From your Twilio Console Dashboard:
   - Copy your **Account SID**
   - Copy your **Auth Token**
   - Get a **Phone Number** (Twilio provides one for free trial)

### 3. Configure Environment Variables

Edit `/home/rootzilla/face-recognition-attendance/attendance-system/.env`:

```bash
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890  # Your Twilio phone number
```

**Important Notes:**
- Phone numbers must be in E.164 format: `+[country code][number]`
- Example: `+14155552671` for US numbers
- During trial, you can only send SMS to verified phone numbers

### 4. Verify Phone Numbers (Trial Account)

If using a trial account:
1. Go to Twilio Console → Phone Numbers → Verified Caller IDs
2. Add and verify each phone number that will receive SMS
3. Follow the verification process (you'll receive a code via SMS)

### 5. Restart the Backend

```bash
cd /home/rootzilla/face-recognition-attendance/attendance-system
source venv/bin/activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

## Testing SMS Notifications

### Test via API

```bash
# Test SMS notification (will use your profile's phone number)
curl -X POST "http://localhost:8001/api/notifications/send-test" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test with specific phone number
curl -X POST "http://localhost:8001/api/notifications/send-test?phone=+1234567890" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test via Dashboard

1. Log in to the dashboard
2. Go to Settings → Notifications
3. Click "Send Test Notification"
4. Check your phone for the test SMS

## Managing Notification Preferences

### For Parents

Parents can customize their notification preferences:

```bash
# Update preferences
curl -X PUT "http://localhost:8001/api/notifications/preferences" \
  -H "Authorization: Bearer PARENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sms": true,
    "email": true,
    "in_app": true,
    "language": "en"
  }'

# Get current preferences
curl -X GET "http://localhost:8001/api/notifications/preferences" \
  -H "Authorization: Bearer PARENT_TOKEN"
```

### Via Mobile App

1. Open the mobile app
2. Go to Settings → Notifications
3. Toggle SMS, Email, and In-App notifications
4. Save changes

## Phone Number Format

All phone numbers in the database must be in E.164 format:

- **Correct**: `+14155552671`, `+254712345678`
- **Incorrect**: `4155552671`, `0712345678`, `(415) 555-2671`

### Update Existing Phone Numbers

```sql
-- Update parent phone numbers to E.164 format
UPDATE parents 
SET phone = '+1' || phone 
WHERE phone NOT LIKE '+%' AND LENGTH(phone) = 10;

-- Update teacher phone numbers
UPDATE teachers 
SET phone = '+1' || phone 
WHERE phone NOT LIKE '+%' AND LENGTH(phone) = 10;
```

## Notification Triggers

### Automatic SMS Notifications

1. **Student Check-In** (Parents)
   - Triggered when face recognition detects student
   - Includes: Student name, location, time
   - Respects parent's SMS preference

2. **Announcements** (All Roles)
   - Sent when admin creates announcement
   - Targeted by role (parent, teacher, admin)
   - Includes announcement title and content

3. **System Alerts** (Admins)
   - Camera offline
   - System errors
   - Security alerts

## Troubleshooting

### SMS Not Sending

1. **Check Twilio credentials**:
   ```bash
   # Verify in .env file
   cat /home/rootzilla/face-recognition-attendance/attendance-system/.env | grep TWILIO
   ```

2. **Check logs**:
   ```bash
   # Backend logs will show SMS status
   tail -f /var/log/attendance-system.log
   ```

3. **Verify phone number format**:
   - Must start with `+`
   - Include country code
   - No spaces or special characters

4. **Trial account limitations**:
   - Can only send to verified numbers
   - Limited number of messages
   - Upgrade to paid account for production

### Common Error Messages

- **"Twilio not configured"**: Check .env credentials
- **"Invalid phone number"**: Use E.164 format
- **"Unverified number"**: Add number to Twilio verified list (trial accounts)
- **"Insufficient funds"**: Add credit to Twilio account

## Production Deployment

### Upgrade Twilio Account

1. Add payment method to Twilio account
2. Remove trial restrictions
3. Purchase additional phone numbers if needed
4. Set up usage alerts

### Security Best Practices

1. **Never commit credentials**:
   ```bash
   # Ensure .env is in .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use environment variables**:
   - Store credentials in secure environment
   - Use secrets management (AWS Secrets Manager, etc.)

3. **Monitor usage**:
   - Set up Twilio usage alerts
   - Monitor costs regularly
   - Implement rate limiting

### Rate Limiting

Add rate limiting to prevent SMS spam:

```python
# In notification_service.py
from datetime import datetime, timedelta
from collections import defaultdict

class NotificationService:
    def __init__(self):
        self._sms_rate_limit = defaultdict(list)
        self._max_sms_per_hour = 10
    
    def send_sms(self, phone: str, message: str) -> dict:
        # Check rate limit
        now = datetime.utcnow()
        recent = [t for t in self._sms_rate_limit[phone] 
                  if now - t < timedelta(hours=1)]
        
        if len(recent) >= self._max_sms_per_hour:
            return {"status": "rate_limited", 
                    "reason": "Too many SMS sent in the last hour"}
        
        # Send SMS...
        self._sms_rate_limit[phone].append(now)
```

## Cost Estimation

### Twilio Pricing (as of 2024)

- **SMS (US/Canada)**: $0.0079 per message
- **SMS (International)**: Varies by country ($0.01 - $0.10)
- **Phone Number**: $1.15/month

### Example Monthly Cost

For a school with:
- 500 students
- 2 attendance notifications per day per student
- 30 days per month

**Cost**: 500 × 2 × 30 × $0.0079 = **$237/month**

## Support

For issues or questions:
1. Check Twilio documentation: https://www.twilio.com/docs
2. Review system logs
3. Test with the `/send-test` endpoint
4. Contact system administrator

## Next Steps

1. ✅ Configure Twilio credentials
2. ✅ Test SMS notifications
3. ✅ Update phone numbers to E.164 format
4. ✅ Configure user notification preferences
5. ✅ Monitor SMS delivery and costs
