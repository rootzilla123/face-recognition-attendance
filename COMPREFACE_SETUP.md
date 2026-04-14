# CompreFace Setup Guide

## Current Issue
❌ **Error:** "Recognition service with API Key not found"

The API key in your `.env` file doesn't exist in CompreFace, OR you created a Detection Service instead of a Recognition Service.

## Solution

### Step 1: Access CompreFace Admin
Open in your browser: **http://localhost:8080**

### Step 2: Login/Register
- If first time, create an account
- Login with your credentials

### Step 3: Create Recognition Service (NOT Detection!)
1. Click "Create Application" (if you don't have one)
2. Give it a name like "Attendance System"
3. Click on the application
4. Click "Add Service"
5. Select **"Recognition Service"** ⚠️ NOT "Detection Service"!
6. Give it a name like "Face Recognition"

**Important:** 
- ✅ **Recognition Service** = Identifies WHO the person is (what we need)
- ❌ **Detection Service** = Only finds faces, doesn't identify them

### Step 4: Copy API Key
1. You'll see the API key displayed
2. Copy the entire API key (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### Step 5: Update .env File
Open `attendance-system/.env` and update:

```env
COMPREFORE_API_KEY=YOUR_NEW_API_KEY_HERE
```

Replace `YOUR_NEW_API_KEY_HERE` with the key you copied from the **Recognition Service**.

### Step 6: Restart Backend
The backend will auto-reload, or restart it manually.

### Step 7: Test
Try adding a student with a photo again!

## Current API Key (Invalid)
```
f29d91ab-2db7-4b49-a40d-53c316516b0b
```

This key doesn't exist in your CompreFace instance, or it's for a Detection Service instead of Recognition Service.

## Verification
After setup, you should be able to:
✅ Add students with photos
✅ Photos registered in CompreFace
✅ Face recognition working on camera feeds
