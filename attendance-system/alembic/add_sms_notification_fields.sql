-- Migration: Add notification_preferences to teachers and administrators, add phone to administrators
-- Date: 2026-04-22

-- Add phone column to administrators
ALTER TABLE administrators ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Add notification_preferences to administrators
ALTER TABLE administrators ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"sms": true, "email": true, "in_app": true, "language": "en"}';

-- Add notification_preferences to teachers
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"sms": true, "email": true, "in_app": true, "language": "en"}';

-- Set defaults for existing rows that have NULL
UPDATE administrators SET notification_preferences = '{"sms": true, "email": true, "in_app": true, "language": "en"}' WHERE notification_preferences IS NULL;
UPDATE teachers SET notification_preferences = '{"sms": true, "email": true, "in_app": true, "language": "en"}' WHERE notification_preferences IS NULL;
