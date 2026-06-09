#!/usr/bin/env python3
"""
Configure PocketBase SMTP settings to use Mailpit for email delivery.
Also configures verification and password-reset email templates with correct URLs.

Usage:
  python configure_pb_smtp.py --email admin@example.com --password yourpassword

Mailpit catches ALL emails locally — view them at http://localhost:8025
"""

import requests
import argparse
import json
import sys

PB_URL = "http://localhost:8091"
# Mailpit SMTP (accepts anything, no real auth needed)
SMTP_HOST = "localhost"
SMTP_PORT = 1025

# The URL where the web dashboard is hosted
DASHBOARD_URL = "http://localhost:3000"


def get_admin_token(email: str, password: str) -> str:
    """Authenticate as PocketBase superuser."""
    r = requests.post(
        f"{PB_URL}/api/collections/_superusers/auth-with-password",
        json={"identity": email, "password": password},
    )
    if r.status_code != 200:
        print(f"❌ Admin auth failed: {r.status_code} - {r.text}")
        sys.exit(1)
    return r.json()["token"]


def configure_smtp(token: str):
    """Set PocketBase SMTP to use the local Mailpit server."""
    headers = {"Authorization": token}

    # Get current settings first
    r = requests.get(f"{PB_URL}/api/settings", headers=headers)
    if r.status_code != 200:
        print(f"❌ Failed to read settings: {r.status_code} - {r.text}")
        return False

    settings = r.json()

    # Update SMTP settings
    settings["smtp"] = {
        "enabled": True,
        "host": SMTP_HOST,
        "port": SMTP_PORT,
        "tls": False,
        "authMethod": "",
        "username": "",
        "password": "",
        "localName": "",
    }

    # Update sender info
    settings["meta"] = settings.get("meta", {})
    settings["meta"]["senderName"] = "AttendanceAI"
    settings["meta"]["senderAddress"] = "noreply@attendanceai.local"
    settings["meta"]["appName"] = "AttendanceAI"
    settings["meta"]["appUrl"] = DASHBOARD_URL
    settings["meta"]["verificationTemplate"] = {
        "subject": "Verify your AttendanceAI email",
        "body": """<p>Hello,</p>
<p>Thank you for joining AttendanceAI! Click the link below to verify your email address:</p>
<p><a href="{APP_URL}/verify-email?token={TOKEN}">Verify Email Address</a></p>
<p>If you did not create an account, you can safely ignore this email.</p>
<p>Thanks,<br/>AttendanceAI Team</p>""",
        "actionUrl": "{APP_URL}/verify-email?token={TOKEN}",
    }
    settings["meta"]["resetPasswordTemplate"] = {
        "subject": "Reset your AttendanceAI password",
        "body": """<p>Hello,</p>
<p>We received a request to reset your password. Click the link below to set a new password:</p>
<p><a href="{APP_URL}/_/#/auth/confirm-password-reset/{TOKEN}">Reset Password</a></p>
<p>If you did not request a password reset, you can safely ignore this email.</p>
<p>This link expires in 30 minutes.</p>
<p>Thanks,<br/>AttendanceAI Team</p>""",
        "actionUrl": "{APP_URL}/_/#/auth/confirm-password-reset/{TOKEN}",
    }

    # Save settings
    r = requests.patch(f"{PB_URL}/api/settings", json=settings, headers=headers)
    if r.status_code == 200:
        print("✅ SMTP configured successfully!")
        print(f"   Host: {SMTP_HOST}:{SMTP_PORT} (Mailpit)")
        print(f"   Sender: noreply@attendanceai.local")
        print(f"   App URL: {DASHBOARD_URL}")
        return True
    else:
        print(f"❌ Failed to save settings: {r.status_code} - {r.text}")
        return False


def test_smtp(token: str, test_email: str):
    """Send a test email to verify SMTP works."""
    headers = {"Authorization": token}
    r = requests.post(
        f"{PB_URL}/api/settings/test/email",
        json={"email": test_email, "template": "verification"},
        headers=headers,
    )
    if r.status_code == 204 or r.status_code == 200:
        print(f"✅ Test email sent to {test_email}!")
        print(f"   View it at: http://localhost:8025")
    else:
        print(f"⚠️  Test email may have failed: {r.status_code} - {r.text}")
        print(f"   Make sure Mailpit is running (docker container)")


def main():
    parser = argparse.ArgumentParser(description="Configure PocketBase SMTP for email delivery")
    parser.add_argument("--email", required=True, help="PocketBase admin email")
    parser.add_argument("--password", required=True, help="PocketBase admin password")
    parser.add_argument("--test", help="Send a test email to this address after configuring")
    parser.add_argument("--dashboard-url", default="http://localhost:3000", help="Dashboard URL for email links")
    args = parser.parse_args()

    global DASHBOARD_URL
    DASHBOARD_URL = args.dashboard_url

    print("🔧 Configuring PocketBase SMTP...")
    print(f"   PocketBase: {PB_URL}")
    print()

    token = get_admin_token(args.email, args.password)
    print("✅ Authenticated as admin")

    if configure_smtp(token):
        if args.test:
            print()
            test_smtp(token, args.test)

    print()
    print("📧 Email verification and password reset are now active!")
    print("   All emails are caught by Mailpit → http://localhost:8025")
    print()
    print("   Web app verification:    /verify-email?token=...")
    print("   Web app forgot password: /forgot-password")
    print("   Mobile app:              Works through PocketBase API")


if __name__ == "__main__":
    main()
