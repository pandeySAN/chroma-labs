# Clinic Partner - Deployment Guide

## Table of Contents
1. [AWS EC2 Setup](#aws-ec2-setup)
2. [Testing Checklist](#testing-checklist)
3. [Backend Production Setup](#backend-production-setup)
4. [Flutter Production Setup](#flutter-production-setup)
5. [Google OAuth Configuration](#google-oauth-configuration)
6. [Deployment Commands](#deployment-commands)

---

## AWS EC2 Setup

This section provides a complete step-by-step guide to deploy the Clinic Partner backend on AWS EC2.

### Step 1: Launch EC2 Instance

#### 1.1 Create EC2 Instance

1. Log in to [AWS Console](https://console.aws.amazon.com)
2. Navigate to **EC2 → Instances → Launch Instance**

3. Configure the instance:

| Setting | Recommended Value |
|---------|-------------------|
| **Name** | `clinic-partner-server` |
| **AMI** | Ubuntu Server 22.04 LTS (Free tier eligible) |
| **Instance Type** | `t2.micro` (Free tier) or `t2.small` (Production) |
| **Key Pair** | Create new or select existing `.pem` file |
| **Storage** | 20-30 GB gp3 SSD |

#### 1.2 Configure Security Group

Create a new security group with these inbound rules:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | My IP | SSH access |
| HTTP | 80 | 0.0.0.0/0 | Web traffic |
| HTTPS | 443 | 0.0.0.0/0 | Secure web traffic |
| Custom TCP | 8000 | My IP | Django dev server (optional) |

4. Click **Launch Instance**

#### 1.3 Allocate Elastic IP (Recommended)

1. Go to **EC2 → Elastic IPs → Allocate Elastic IP address**
2. Click **Allocate**
3. Select the new IP → **Actions → Associate Elastic IP address**
4. Select your instance and associate

> **Note**: Write down your Elastic IP: `100.50.136.86 `

---

### Step 2: Connect to EC2 Instance

#### 2.1 Connect via SSH

```bash
# Set correct permissions for key file
chmod 400 your-key-file.pem

# Connect to EC2
ssh -i "your-key-file.pem" ubuntu@YOUR_ELASTIC_IP

# Example:
ssh -i "clinic-partner-key.pem" ubuntu@54.123.45.67
```

#### 2.2 Update System

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y python3-pip python3-venv python3-dev \
    build-essential libpq-dev nginx curl git supervisor
```

---

### Step 3: Install PostgreSQL (Production Database)

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql

# In PostgreSQL shell:
CREATE DATABASE clinic_production;
CREATE USER clinic_user WITH PASSWORD 'your_secure_password_here';
ALTER ROLE clinic_user SET client_encoding TO 'utf8';
ALTER ROLE clinic_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE clinic_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE clinic_production TO clinic_user;
\q
```

---

### Step 4: Clone and Setup Project

#### 4.1 Create Project Directory

```bash
# Create app directory
sudo mkdir -p /var/www/clinic-partner
sudo chown ubuntu:ubuntu /var/www/clinic-partner
cd /var/www/clinic-partner
```

#### 4.2 Clone Repository

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/clinic-partner.git .

# Or upload files using SCP
# scp -i "your-key.pem" -r ./clinic_backend ubuntu@YOUR_IP:/var/www/clinic-partner/
```

#### 4.3 Setup Python Virtual Environment

```bash
# Navigate to backend
cd /var/www/clinic-partner/clinic_backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Install production dependencies
pip install gunicorn psycopg2-binary whitenoise
```

---

### Step 5: Configure Environment Variables

#### 5.1 Create Environment File

```bash
# Create .env file
nano /var/www/clinic-partner/clinic_backend/.env
```

#### 5.2 Add Environment Variables

```env
# Django Settings
DJANGO_SECRET_KEY=ffw+-+hyh*dqh==&o%*w0=o#+if__dydz^xnah9q14oy8)xqv+
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=100.50.136.86,cere-bro.in,api.cere-bro.in

# Database
DB_NAME=clinic_production
DB_USER=clinic_user
DB_PASSWORD=Chromalabs2026
DB_HOST=localhost
DB_PORT=5432

# Google OAuth
GOOGLE_OAUTH2_CLIENT_ID=230465261403-j2nd09e5ecn5256l7nuh8rlkqdm6ici7.apps.googleusercontent.com

# CORS (add your Flutter app domains)
CORS_ALLOWED_ORIGINS=https://cere-bro.in

# Static/Media
STATIC_ROOT=/var/www/clinic-partner/clinic_backend/staticfiles
MEDIA_ROOT=/var/www/clinic-partner/clinic_backend/media
```

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

#### 5.3 Generate Secret Key

```bash
# Generate a secure secret key
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Copy the output and paste it as your `DJANGO_SECRET_KEY`.

---

### Step 6: Setup Django Application

```bash
# Activate virtual environment
cd /var/www/clinic-partner/clinic_backend
source venv/bin/activate

# Set environment variable
export DJANGO_SETTINGS_MODULE=config.settings_production

# Create directories
mkdir -p staticfiles media logs

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser

# Create sample data (optional)
python manage.py create_sample_data

# Test the application
python manage.py check --deploy
```

---

### Step 7: Configure Gunicorn

#### 7.1 Create Gunicorn Config

```bash
nano /var/www/clinic-partner/clinic_backend/gunicorn.conf.py
```

```python
# Gunicorn configuration file
import multiprocessing

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Workers
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Logging
errorlog = "/var/www/clinic-partner/clinic_backend/logs/gunicorn-error.log"
accesslog = "/var/www/clinic-partner/clinic_backend/logs/gunicorn-access.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Process naming
proc_name = "clinic-partner"

# Server mechanics
daemon = False
pidfile = "/var/www/clinic-partner/clinic_backend/gunicorn.pid"
```

#### 7.2 Test Gunicorn

```bash
cd /var/www/clinic-partner/clinic_backend
source venv/bin/activate

# Test run
gunicorn config.wsgi:application --bind 127.0.0.1:8000

# Press Ctrl+C to stop
```

---

### Step 8: Create Systemd Service

#### 8.1 Create Service File

```bash
sudo nano /etc/systemd/system/clinic-partner.service
```

```ini
[Unit]
Description=Clinic Partner Django Backend
After=network.target postgresql.service

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/clinic-partner/clinic_backend
Environment="DJANGO_SETTINGS_MODULE=config.settings_production"
EnvironmentFile=/var/www/clinic-partner/clinic_backend/.env
ExecStart=/var/www/clinic-partner/clinic_backend/venv/bin/gunicorn \
    --config /var/www/clinic-partner/clinic_backend/gunicorn.conf.py \
    config.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

#### 8.2 Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable clinic-partner

# Start service
sudo systemctl start clinic-partner

# Check status
sudo systemctl status clinic-partner

# View logs if needed
sudo journalctl -u clinic-partner -f
```

---

### Step 9: Configure Nginx

#### 9.1 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/clinic-partner
```

```nginx
# Redirect HTTP to HTTPS (enable after SSL setup)
# server {
#     listen 80;
#     server_name YOUR_DOMAIN api.YOUR_DOMAIN YOUR_ELASTIC_IP;
#     return 301 https://$server_name$request_uri;
# }

# Main server block
server {
    listen 80;
    # listen 443 ssl http2;  # Enable after SSL setup
    
    server_name YOUR_ELASTIC_IP;  # Replace with your domain later
    
    # SSL Configuration (enable after certbot)
    # ssl_certificate /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem;
    # ssl_protocols TLSv1.2 TLSv1.3;
    # ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    
    # Logging
    access_log /var/log/nginx/clinic-partner-access.log;
    error_log /var/log/nginx/clinic-partner-error.log;
    
    # Max upload size
    client_max_body_size 10M;
    
    # Static files
    location /static/ {
        alias /var/www/clinic-partner/clinic_backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Media files
    location /media/ {
        alias /var/www/clinic-partner/clinic_backend/media/;
        expires 7d;
    }
    
    # Django application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /health/ {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
```

#### 9.2 Enable Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/clinic-partner /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

### Step 10: Setup SSL with Let's Encrypt (After Domain Setup)

> **Note**: Complete this step after pointing your domain to the Elastic IP.

#### 10.1 Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

#### 10.2 Obtain SSL Certificate

```bash
# Replace with your domain
sudo certbot --nginx -d your-domain.com -d api.your-domain.com

# Follow the prompts:
# - Enter email address
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (recommended: Yes)
```

#### 10.3 Auto-Renewal

```bash
# Test auto-renewal
sudo certbot renew --dry-run

# Certbot automatically creates a cron job for renewal
```

---

### Step 11: Domain Configuration

#### 11.1 Configure DNS Records

In your domain registrar (GoDaddy, Namecheap, Route53, etc.):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | YOUR_ELASTIC_IP | 300 |
| A | api | YOUR_ELASTIC_IP | 300 |
| A | www | YOUR_ELASTIC_IP | 300 |

#### 11.2 Update Nginx and Django

After DNS propagates (5-30 minutes):

1. Update Nginx `server_name`:
```bash
sudo nano /etc/nginx/sites-available/clinic-partner
# Change: server_name YOUR_ELASTIC_IP;
# To: server_name your-domain.com api.your-domain.com;
```

2. Update Django `.env`:
```bash
nano /var/www/clinic-partner/clinic_backend/.env
# Update DJANGO_ALLOWED_HOSTS
```

3. Restart services:
```bash
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl restart clinic-partner
```

---

### Step 12: Update Flutter App

Update your Flutter app to point to the production API:

Edit `lib/core/constants/api_constants.dart`:

```dart
static const bool isProduction = true;
static const String prodBaseUrl = 'https://api.your-domain.com';
// Or use Elastic IP for testing:
// static const String prodBaseUrl = 'http://YOUR_ELASTIC_IP';
```

---

### Step 13: Useful Commands Reference

#### Service Management

```bash
# Clinic Partner Backend
sudo systemctl start clinic-partner
sudo systemctl stop clinic-partner
sudo systemctl restart clinic-partner
sudo systemctl status clinic-partner

# View logs
sudo journalctl -u clinic-partner -f
sudo tail -f /var/www/clinic-partner/clinic_backend/logs/gunicorn-error.log

# Nginx
sudo systemctl restart nginx
sudo nginx -t  # Test config

# PostgreSQL
sudo systemctl status postgresql
```

#### Django Management

```bash
cd /var/www/clinic-partner/clinic_backend
source venv/bin/activate

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Django shell
python manage.py shell

# Check for issues
python manage.py check --deploy
```

#### Deployment Updates

```bash
# Pull latest code
cd /var/www/clinic-partner
git pull origin main

# Activate venv and update
cd clinic_backend
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput

# Restart service
sudo systemctl restart clinic-partner
```

---

### Step 14: Monitoring & Maintenance

#### 14.1 Setup Log Rotation

```bash
sudo nano /etc/logrotate.d/clinic-partner
```

```
/var/www/clinic-partner/clinic_backend/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ubuntu www-data
    sharedscripts
    postrotate
        systemctl reload clinic-partner > /dev/null 2>&1 || true
    endscript
}
```

#### 14.2 Setup Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 14.3 Setup Firewall (UFW)

```bash
# Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

---

### AWS EC2 Cost Estimation

| Resource | Free Tier | Production |
|----------|-----------|------------|
| EC2 t2.micro | 750 hrs/month (1 year) | ~$8.50/month |
| EC2 t2.small | - | ~$17/month |
| Elastic IP | Free (if attached) | $3.60/month (if unused) |
| Storage (30GB) | 30GB free (1 year) | ~$2.40/month |
| Data Transfer | 15GB/month | $0.09/GB after |

**Estimated Monthly Cost (Production)**: $20-30/month

---

### Troubleshooting

#### Common Issues

1. **502 Bad Gateway**
   ```bash
   # Check if Gunicorn is running
   sudo systemctl status clinic-partner
   
   # Check logs
   sudo journalctl -u clinic-partner -n 50
   ```

2. **Static files not loading**
   ```bash
   # Recollect static files
   python manage.py collectstatic --noinput
   
   # Check Nginx config
   sudo nginx -t
   ```

3. **Database connection error**
   ```bash
   # Check PostgreSQL status
   sudo systemctl status postgresql
   
   # Test connection
   psql -U clinic_user -d clinic_production -h localhost
   ```

4. **Permission denied errors**
   ```bash
   # Fix ownership
   sudo chown -R ubuntu:www-data /var/www/clinic-partner
   sudo chmod -R 755 /var/www/clinic-partner
   ```

5. **Django check --deploy warnings**
   - Ensure all security settings are configured in `settings_production.py`

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
