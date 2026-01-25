# Clinic Partner - Deployment Guide

## Table of Contents
1. [Testing Checklist](#testing-checklist)
2. [Backend Production Setup](#backend-production-setup)
3. [Flutter Production Setup](#flutter-production-setup)
4. [Google OAuth Configuration](#google-oauth-configuration)
5. [Deployment Commands](#deployment-commands)

---

## Testing Checklist

### Backend API Testing

```bash
cd clinic_backend

# 1. Start the server
python manage.py runserver

# 2. Create sample data
python manage.py create_sample_data

# 3. Test endpoints with curl or Postman
```

#### API Endpoint Tests

| Test | Endpoint | Expected |
|------|----------|----------|
| Health Check | `GET /admin/` | Admin login page |
| Token Auth | `POST /api/token/` | JWT tokens |
| Google Auth | `POST /api/auth/google/` | JWT tokens + user |
| Current User | `GET /api/auth/me/` | User data |
| Appointments | `GET /api/appointments/` | List of appointments |

#### Test Commands

```bash
# Get JWT token (email/password)
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"email": "doctor@test.com", "password": "doctor123"}'

# Get current user (replace <token>)
curl http://localhost:8000/api/auth/me/ \
  -H "Authorization: Bearer <access_token>"

# Get appointments
curl http://localhost:8000/api/appointments/ \
  -H "Authorization: Bearer <access_token>"

# Update appointment status
curl -X PATCH http://localhost:8000/api/appointments/1/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'
```

### Flutter App Testing

| Test | Steps | Expected Result |
|------|-------|-----------------|
| Login Flow | Tap Google Sign-In | Redirect to Home |
| Auth Error | Use invalid token | Show error message |
| Load Appointments | Open Home screen | List of cards |
| Empty State | No appointments | "No appointments yet" |
| Pull to Refresh | Pull down on list | Loading indicator, refresh |
| Video Call | Tap video button | Opens browser/app |
| Logout | Tap logout → Confirm | Return to Login |
| Network Error | Disable internet | Show error + retry |

### Error Scenario Testing

```dart
// Test network failure
// 1. Disable network on device/emulator
// 2. Try to fetch appointments
// 3. Verify error message displays
// 4. Enable network
// 5. Tap retry/refresh
// 6. Verify data loads

// Test token expiration
// 1. Wait for access token to expire (or manually clear)
// 2. Try API call
// 3. Verify auto-refresh works
// 4. If refresh fails, verify redirect to login
```

---

## Backend Production Setup

### 1. Environment Variables

Create `.env` file in `clinic_backend/`:

```env
# Django
DJANGO_SECRET_KEY=your-super-secret-production-key-min-50-chars
DJANGO_ALLOWED_HOSTS=api.yourdomain.com,yourdomain.com
DJANGO_SETTINGS_MODULE=config.settings_production

# Database (PostgreSQL)
DB_NAME=clinic_production
DB_USER=clinic_user
DB_PASSWORD=secure-database-password
DB_HOST=localhost
DB_PORT=5432

# Google OAuth
GOOGLE_OAUTH2_CLIENT_ID=your-google-client-id.apps.googleusercontent.com

# CORS
CORS_ALLOWED_ORIGINS=https://app.yourdomain.com,https://yourdomain.com

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### 2. Production Checklist

```bash
# Install production dependencies
pip install gunicorn psycopg2-binary whitenoise

# Update requirements.txt
pip freeze > requirements.txt

# Create logs directory
mkdir -p logs

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Security check
python manage.py check --deploy
```

### 3. Gunicorn Configuration

Create `gunicorn.conf.py`:

```python
bind = "0.0.0.0:8000"
workers = 3
worker_class = "sync"
timeout = 120
keepalive = 5
errorlog = "logs/gunicorn-error.log"
accesslog = "logs/gunicorn-access.log"
loglevel = "info"
```

### 4. Nginx Configuration

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    location /static/ {
        alias /path/to/clinic_backend/staticfiles/;
    }

    location /media/ {
        alias /path/to/clinic_backend/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5. Systemd Service

Create `/etc/systemd/system/clinic-backend.service`:

```ini
[Unit]
Description=Clinic Partner Backend
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/clinic_backend
Environment="DJANGO_SETTINGS_MODULE=config.settings_production"
EnvironmentFile=/path/to/clinic_backend/.env
ExecStart=/path/to/venv/bin/gunicorn config.wsgi:application -c gunicorn.conf.py

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable clinic-backend
sudo systemctl start clinic-backend
sudo systemctl status clinic-backend
```

---

## Flutter Production Setup

### 1. Update API Base URL

Edit `lib/core/constants/api_constants.dart`:

```dart
static const bool isProduction = true;  // Change to true
static const String _prodBaseUrl = 'https://api.yourdomain.com';
```

### 2. Android Release Build

#### Generate Keystore

```bash
# Create keystore (only once)
keytool -genkey -v -keystore clinic-partner-release.keystore \
  -alias clinic-partner \
  -keyalg RSA -keysize 2048 -validity 10000
```

#### Configure Signing

Create `android/key.properties`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=clinic-partner
storeFile=../clinic-partner-release.keystore
```

Edit `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### Build APK

```bash
# Clean and build
flutter clean
flutter pub get
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3. iOS Release Build

```bash
# Build iOS
flutter build ios --release

# Open Xcode for archive
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

---

## Google OAuth Configuration

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project or select existing
3. Enable **Google Sign-In API**
4. Go to **APIs & Services → Credentials**

### 2. Create OAuth 2.0 Credentials

#### Web Client (for Backend)
- Application type: **Web application**
- Name: `Clinic Partner Backend`
- Authorized redirect URIs: `https://api.yourdomain.com/api/auth/google/callback/`
- Copy **Client ID** → Use in Django settings

#### Android Client
- Application type: **Android**
- Name: `Clinic Partner Android`
- Package name: `com.clinicpartner.app`
- SHA-1 fingerprint:

```bash
# Debug SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android

# Release SHA-1
keytool -list -v -keystore clinic-partner-release.keystore -alias clinic-partner
```

#### iOS Client
- Application type: **iOS**
- Name: `Clinic Partner iOS`
- Bundle ID: `com.clinicpartner.app`
- Download `GoogleService-Info.plist`

### 3. Android Configuration

Create/edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Clinic Partner</string>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
</resources>
```

### 4. iOS Configuration

1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## Deployment Commands

### Quick Reference

```bash
# === BACKEND ===

# Development
cd clinic_backend
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\Activate.ps1 on Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py create_sample_data
python manage.py runserver

# Production
export DJANGO_SETTINGS_MODULE=config.settings_production
python manage.py collectstatic --noinput
python manage.py migrate
gunicorn config.wsgi:application -c gunicorn.conf.py

# === FLUTTER ===

# Development
cd clinic_partner_app
flutter pub get
flutter run

# Production (Android)
flutter clean
flutter pub get
flutter build apk --release

# Production (iOS)
flutter build ios --release
```

### Health Check URLs

| Service | URL | Expected |
|---------|-----|----------|
| Backend API | `https://api.yourdomain.com/admin/` | Django Admin |
| API Health | `https://api.yourdomain.com/api/auth/me/` | 401 Unauthorized |

---

## Security Checklist

- [ ] SECRET_KEY is unique and secret (50+ chars)
- [ ] DEBUG = False in production
- [ ] ALLOWED_HOSTS configured
- [ ] HTTPS enabled with valid SSL certificate
- [ ] Database password is strong
- [ ] Google OAuth credentials are secured
- [ ] CORS origins are restricted
- [ ] Rate limiting enabled
- [ ] Logging configured
- [ ] Backups scheduled
- [ ] Error monitoring (Sentry) configured
