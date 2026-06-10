# Local Testing Guide - Development Mode

## Quick Start for Local Testing

### What's Ready
- ✅ Backend API running on `http://localhost:8001`
- ✅ Frontend ready to start
- ✅ **Quick Access Buttons** on login page for each role
- ✅ Twilio validation disabled for local development

---

## Running the System Locally

### Step 1: Backend is Running
Backend is already started on port 8001. Check status:

```bash
# Check if backend is responding
curl http://localhost:8001/version
```

### Step 2: Start the Frontend

```bash
cd attendance-dashboard
npm install  # if needed
npm run dev
```

Frontend will run on: **http://localhost:3000**

---

## Login with Quick Access Buttons

On the login page (`http://localhost:3000/login`), scroll down to **"Quick Access (Dev)"** section.

### Available Test Accounts

| Role | Button | Dashboard |
|------|--------|-----------|
| **Admin** | → Admin | System control, users, cameras |
| **Teacher** | → Teacher | Attendance, classes, marks |
| **Student** | → Student | My attendance, notifications |
| **Parent** | → Parent | Children tracking, alerts |

Just **click any button** to instantly log in to that role's dashboard!

---

## Testing User Journeys

### 1. Admin Journey
**Click → Admin**

Access:
- Dashboard with system stats
- User management
- Camera configuration
- Real-time attendance counter
- System health monitoring

Test:
- [ ] View dashboard stats
- [ ] Navigate to cameras section
- [ ] Check user management
- [ ] Review system logs

### 2. Teacher Journey
**Click → Teacher**

Access:
- Teacher dashboard
- Class-based attendance
- Student marks management
- Announcements posting
- Attendance reports

Test:
- [ ] View my class attendance
- [ ] Check student list
- [ ] Review attendance history
- [ ] Post an announcement

### 3. Student Journey
**Click → Student**

Access:
- Student dashboard
- My attendance history
- Notifications
- My marks/grades
- Profile management

Test:
- [ ] View my attendance
- [ ] Check my marks
- [ ] See notifications
- [ ] Update profile

### 4. Parent Journey
**Click → Parent**

Access:
- Parent dashboard
- Multiple children tracking
- Children's attendance
- Attendance alerts
- Notifications

Test:
- [ ] View children list
- [ ] Check each child's attendance
- [ ] Review notifications
- [ ] See attendance trends

---

## API Testing

### Check Backend Health
```bash
curl http://localhost:8001/version
```

Expected response:
```json
{
  "version": "1.0.0",
  "status": "running",
  "features": { ... }
}
```

### List API Endpoints
```bash
curl http://localhost:8001/docs
# Opens Swagger UI at http://localhost:8001/docs
```

### Test a Real Endpoint
```bash
# Get current user info (requires auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8001/api/v1/users/me
```

---

## Features You Can Test Locally

### ✅ Authentication
- Login with quick access buttons
- Logout
- Role-based access

### ✅ Dashboards
- Admin dashboard with real-time stats
- Teacher attendance view
- Student attendance history
- Parent multi-child tracking

### ✅ Navigation
- Sidebar navigation
- Role-specific menu items
- Page routing

### ⏳ Partially Working Locally
- Notifications (backend ready, UI needs completion)
- Chatbot (backend running with Ollama)
- Announcements (backend ready, UI testing needed)

### ❌ Not Available Locally (No Internet)
- Google OAuth (requires network)
- Twilio SMS (requires network)
- Email notifications (requires network)
- Firebase push notifications (requires network)

---

## Troubleshooting Local Setup

### Backend Not Responding?
```bash
# Check if backend is still running
docker ps | grep backend

# Or check the background process
ps aux | grep uvicorn
```

### Frontend Won't Connect to Backend?
```bash
# Check if backend is listening
netstat -an | grep 8001

# Check backend logs
# See the terminal where you started it
```

### Stuck on Login Page?
1. Make sure backend is running on port 8001
2. Check browser console for errors (F12)
3. Try refreshing the page
4. Click one of the quick access buttons

### Can't See Quick Access Buttons?
1. Clear browser cache: Ctrl+Shift+Delete
2. Refresh page: Ctrl+R
3. Hard refresh: Ctrl+Shift+R

---

## What to Test First

1. **Start Backend** → Check `/version` endpoint responds
2. **Start Frontend** → Navigate to login page
3. **Click Admin Button** → Should redirect to admin dashboard
4. **Navigate Sidebar** → Test different sections
5. **Click Student Button** → Should see student dashboard
6. **Review Each Dashboard** → Check layout and components

---

## Expected Behavior

### ✅ Should Work
- [ ] Login with any quick access button
- [ ] See role-specific dashboard
- [ ] Navigate between pages using sidebar
- [ ] View real-time stats (if backend data available)
- [ ] Logout and re-login

### 🟡 Might Have Issues
- API endpoints might return empty data (no seeds)
- Some UI might be incomplete
- WebSocket real-time updates might be pending

### ❌ Won't Work
- Google sign-in (no network)
- SMS/Email notifications (no network)
- Push notifications (no network/Firebase)

---

## Development Tips

### Modify a Dashboard
Edit files in: `attendance-dashboard/app/[role]/page.tsx`
```bash
# Example: Edit admin dashboard
vim attendance-dashboard/app/admin/page.tsx
# Changes auto-reload with next dev
```

### Test API Responses
Use Swagger UI at: `http://localhost:8001/docs`
- All endpoints documented
- Try endpoints directly from UI
- See request/response formats

### Debug Authentication
```bash
# Check localStorage
localStorage.getItem('auth_token')

# Check if user is logged in
localStorage.getItem('current_user')
```

### Monitor Backend Logs
Backend logs to console where it's running. Watch for:
- Request logs
- Error messages
- Connection attempts
- API calls

---

## Next Steps After Testing

1. **Identify UI Gaps**: Which pages need completion?
2. **Test User Flows**: Can you complete attendance marking?
3. **Check Data**: Are endpoints returning real data?
4. **Performance**: Is the UI responsive?
5. **Bugs**: Document any issues found

---

## Bonus: Quick Reset

To start fresh locally:

```bash
# Clear browser cache
rm -rf ~/.cache/google-chrome  # Chrome
# or
rm -rf ~/Library/Caches/Google/Chrome  # macOS

# Restart backend
# Kill the process and restart it

# Clear localStorage in browser
# Open DevTools (F12) → Application → LocalStorage → Clear All
```

---

You're ready to test! Start with **Step 1** above and work through the user journeys. Let me know what you discover! 🚀

