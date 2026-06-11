# Twilio SMS Setup Guide

This guide walks you through setting up Twilio for SMS notifications in the AttendanceAI system.

## Prerequisites

- A valid phone number to receive test messages
- Credit card for Twilio account (free trial gives $15 credit)

## Step 1: Create a Twilio Account

1. Go to https://www.twilio.com/try-twilio
2. Sign up with your email
3. Verify your phone number (you'll receive a code via SMS)
4. Create your account

## Step 2: Get Your Credentials

1. Go to https://www.twilio.com/console
2. You'll see your **Account SID** and **Auth Token** on the dashboard
3. Copy these values - you'll need them

**Example:**
```
Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Auth Token: your_token_here
```

## Step 3: Get a Twilio Phone Number

1. Still in the console, go to **Phone Numbers** → **Manage** → **Get a Number**
2. Choose your country and click Search
3. Select a number (e.g., +1-555-123-4567)
4. Click "Buy this number"
5. Copy the phone number - you'll need it in E.164 format (e.g., +15551234567)

## Step 4: Update Your .env File

Open `.env` and fill in:

```
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567
```

## Step 5: Test SMS Sending

Once the backend is running, test SMS via the API:

**POST** `http://localhost:8001/api/notifications/test`

```json
{
  "phone": "+1234567890",
  "notification_type": "sms"
}
```

You should receive a test SMS within seconds.

## Step 6: Verify Parent Phone Numbers

Make sure all parent phone numbers in the system are stored in E.164 format:
- ✅ +1234567890
- ✅ +447911123456 (UK)
- ❌ 1234567890 (missing +)
- ❌ (123) 456-7890 (wrong format)

## SMS Features Enabled

Once configured, SMS notifications will automatically send for:

- **Student Check-In**: When a student is marked present via camera face recognition
- **Mark Posting**: When grades or marks are posted
- **Announcements**: Critical announcements to parents/teachers
- **Alerts**: System alerts and warnings

## Rate Limiting

- Maximum 20 SMS per phone number per hour
- Automatic retry with exponential backoff if sending fails
- Permanent failures are logged for manual review

## Troubleshooting

**"SMS skipped (Twilio not configured)"**
- Check that all three env vars are set (SID, Auth Token, Phone Number)
- Restart the backend after updating .env

**"Phone must be in E.164 format"**
- Phone numbers must start with + and include country code
- Example: +1 for USA, +44 for UK, +91 for India

**"SMS rate-limited"**
- Too many SMS sent to the same number in 1 hour
- The system automatically queues and retries later

**"Transient failure" / "Permanent failure"**
- Transient: Temporary network issue - will retry automatically
- Permanent: Invalid number or account issue - needs manual review

## Cost

- Twilio free trial: $15 credit
- Typical SMS cost: $0.0075 - $0.01 per SMS
- Example: 100 SMS/day = $0.75-$1.00/day

## Support

- Twilio Docs: https://www.twilio.com/docs/sms
- Twilio Support: https://www.twilio.com/console/support
