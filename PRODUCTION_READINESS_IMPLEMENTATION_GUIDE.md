# Production Readiness Implementation Guide

This guide explains how to deploy and configure the newly added production features.

## 1. Push Notifications Setup

### Backend Setup

1. **Get Firebase Service Account**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (or create one)
   - Go to Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `firebase-service-account.json`

2. **Configure Environment**:
   ```bash
   # In your .env file
   GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-service-account.json
   FIREBASE_PROJECT_ID=your-project-id
   ```

3. **Mount Service Account in Docker**:
   ```yaml
   # Already configured in docker-compose.prod.yml
   volumes:
     - ./firebase-service-account.json:/app/firebase-service-account.json:ro
   ```

4. **Run Migration**:
   ```bash
   cd attendance-system
   alembic upgrade head
   ```
   This adds the `device_tokens` column to the `users` table.

### Mobile App Integration

1. **Add FCM/APNs to Your App**:
   - Android: Add Firebase Cloud Messaging SDK
   - iOS: Configure APNs and add Firebase SDK

2. **Register Device Token After Login**:
   ```javascript
   // After successful login
   const fcmToken = await messaging().getToken();
   
   await fetch('https://your-api.com/api/v1/auth/device-token', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${accessToken}`,
       'Content-Type': 'application/json',
     },
     body: JSON.stringify({
       token: fcmToken,
       platform: Platform.OS, // 'android' or 'ios'
     }),
   });
   ```

3. **Handle Push Notifications**:
   ```javascript
   // Listen for foreground messages
   messaging().onMessage(async remoteMessage => {
     console.log('Notification received:', remoteMessage);
     // Show in-app notification
   });
   
   // Handle background/quit state
   messaging().setBackgroundMessageHandler(async remoteMessage => {
     console.log('Background notification:', remoteMessage);
   });
   ```

4. **Unregister on Logout**:
   ```javascript
   await fetch('https://your-api.com/api/v1/auth/device-token', {
     method: 'DELETE',
     headers: {
       'Authorization': `Bearer ${accessToken}`,
       'Content-Type': 'application/json',
     },
     body: JSON.stringify({
       token: fcmToken,
     }),
   });
   ```

## 2. App Version Enforcement

### Backend Configuration

The version enforcement is already active. Update minimum versions in:
```python
# attendance-system/app/routes/version.py

MIN_ANDROID_VERSION = "1.0.0"  # Update this when breaking changes occur
MIN_IOS_VERSION = "1.0.0"

LATEST_ANDROID_VERSION = "1.2.0"  # Update with each release
LATEST_IOS_VERSION = "1.2.0"
```

### Mobile App Integration

1. **Add Version Headers to All Requests**:
   ```javascript
   // Create an axios/fetch interceptor
   const API_VERSION = '1.2.0'; // From app.json or package.json
   const PLATFORM = Platform.OS; // 'android' or 'ios'
   
   axios.interceptors.request.use(config => {
     config.headers['X-App-Version'] = API_VERSION;
     config.headers['X-App-Platform'] = PLATFORM;
     return config;
   });
   ```

2. **Handle 426 Upgrade Required Response**:
   ```javascript
   axios.interceptors.response.use(
     response => response,
     error => {
       if (error.response?.status === 426) {
         const { min_version, update_url } = error.response.data;
         
         Alert.alert(
           'Update Required',
           `Your app version is no longer supported. Please update to version ${min_version} or later.`,
           [
             {
               text: 'Update Now',
               onPress: () => Linking.openURL(update_url),
             },
           ],
           { cancelable: false }
         );
       }
       return Promise.reject(error);
     }
   );
   ```

3. **Check Version on App Start**:
   ```javascript
   useEffect(() => {
     const checkVersion = async () => {
       try {
         const response = await fetch('https://your-api.com/api/v1/version/check', {
           headers: {
             'X-App-Version': API_VERSION,
             'X-App-Platform': PLATFORM,
           },
         });
         
         const data = await response.json();
         
         if (data.update_required) {
           // Force update
           Alert.alert(
             'Update Required',
             data.message,
             [{ text: 'Update', onPress: () => Linking.openURL(data.update_url) }],
             { cancelable: false }
           );
         } else if (!data.is_supported) {
           // Optional update available
           Alert.alert(
             'Update Available',
             data.message,
             [
               { text: 'Later', style: 'cancel' },
               { text: 'Update', onPress: () => Linking.openURL(data.update_url) },
             ]
           );
         }
       } catch (error) {
         console.error('Version check failed:', error);
       }
     };
     
     checkVersion();
   }, []);
   ```

## 3. SECRET_KEY Security

### Generate Secure Key

```bash
# Generate a secure 64-character hex key
python -c "import secrets; print(secrets.token_hex(32))"
```

### Set in Production

```bash
# In your .env file (NEVER commit this)
SECRET_KEY=your-generated-64-char-hex-key-here
```

### CI/CD Setup

```yaml
# GitHub Actions example
- name: Set SECRET_KEY
  run: |
    echo "SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')" >> .env
```

## 4. Chatbot History (Redis)

Already configured! The chatbot now stores conversation history in Redis with:
- Key format: `chatbot:history:{user_id}`
- TTL: 24 hours
- Automatic cleanup

No additional configuration needed.

## 5. Testing

### Test Push Notifications

```bash
# Send a test notification
curl -X POST https://your-api.com/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "This is a test push notification"
  }'
```

### Test Version Enforcement

```bash
# Test with old version (should get 426)
curl -X GET https://your-api.com/api/v1/students \
  -H "X-App-Version: 0.9.0" \
  -H "X-App-Platform: android"

# Test with current version (should work)
curl -X GET https://your-api.com/api/v1/students \
  -H "X-App-Version: 1.2.0" \
  -H "X-App-Platform: android"
```

### Test SECRET_KEY Validation

```bash
# Try starting with insecure key (should fail)
SECRET_KEY=your-secret-key-change-this python -m uvicorn app.main:app

# Should see error:
# ValueError: INSECURE SECRET_KEY detected! Generate a secure key with:
#   python -c "import secrets; print(secrets.token_hex(32))"
```

## 6. Monitoring

### Check Push Notification Logs

```bash
docker logs backend | grep "Push notification"
```

### Check Version Enforcement

```bash
docker logs backend | grep "App version"
```

### Check Redis Chat History

```bash
docker exec -it redis redis-cli
> KEYS chatbot:history:*
> GET chatbot:history:USER_ID_HERE
```

## 7. Rollout Strategy

1. **Phase 1: Backend Deployment**
   - Deploy backend with new features
   - Push notifications will be skipped if no tokens registered (graceful)
   - Version enforcement only affects mobile apps with headers

2. **Phase 2: Mobile App Update**
   - Release mobile app v1.1.0 with:
     - Push notification registration
     - Version headers
     - Update handling
   - Soft launch to beta testers

3. **Phase 3: Enforce Minimum Version**
   - After 2 weeks, update `MIN_ANDROID_VERSION` and `MIN_IOS_VERSION`
   - Old apps will be blocked with upgrade prompt

4. **Phase 4: Monitor & Iterate**
   - Monitor push notification delivery rates
   - Track version adoption
   - Adjust TTLs and limits as needed

## Troubleshooting

### Push Notifications Not Working

1. Check Firebase credentials:
   ```bash
   docker exec backend ls -la /app/firebase-service-account.json
   ```

2. Check logs:
   ```bash
   docker logs backend | grep -i firebase
   ```

3. Verify device token is registered:
   ```sql
   SELECT email, device_tokens FROM users WHERE email = 'user@example.com';
   ```

### Version Enforcement Not Working

1. Verify headers are being sent:
   ```bash
   docker logs backend | grep "X-App-Version"
   ```

2. Check middleware is loaded:
   ```bash
   docker exec backend python -c "from app.main import app; print(app.middleware)"
   ```

### Chatbot History Not Persisting

1. Check Redis connection:
   ```bash
   docker exec backend python -c "from app.main import redis_client; print(redis_client.ping())"
   ```

2. Check Redis keys:
   ```bash
   docker exec redis redis-cli KEYS "chatbot:*"
   ```
