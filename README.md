# CEREBRO - Clinic Partner

<p align="center">
  <img src="clinic_partner_app/images/cerebro.jpg" alt="Cerebro Logo" width="180" height="180" style="border-radius: 35px;">
</p>

<p align="center">
  <strong>Mind Re-Wired</strong><br>
  <em>A Complete Healthcare Appointment Management System</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Django-4.2-green?style=flat-square&logo=django" alt="Django">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Python-3.10+-yellow?style=flat-square&logo=python" alt="Python">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart" alt="Dart">
</p>

---

## Overview

**CEREBRO Clinic Partner** is a full-stack healthcare appointment management system designed for doctors and healthcare professionals. The system consists of a Django REST API backend and a cross-platform Flutter mobile application.

### System Components

| Component | Technology | Description |
|-----------|------------|-------------|
| **Backend API** | Django + DRF | RESTful API with JWT authentication |
| **Mobile App** | Flutter | Cross-platform iOS/Android application |
| **Database** | SQLite/PostgreSQL | Data persistence layer |
| **Authentication** | JWT + Google OAuth | Secure multi-provider auth |

---

## Features

### For Doctors
- View daily, weekly, and upcoming appointments
- Update appointment status (Scheduled → In Progress → Completed)
- Access video consultation links
- View patient notes and history
- Google Sign-In integration

### For Administrators
- Manage doctors, patients, and clinics
- Create and schedule appointments
- Monitor appointment statuses
- Django Admin dashboard

### Technical Features
- JWT token authentication with auto-refresh
- Google OAuth 2.0 integration
- Real-time status updates
- Pull-to-refresh functionality
- Demo mode for presentations
- Beautiful animated UI with micro-interactions

---

## Project Structure

```
clinic-partner/
├── clinic_backend/              # Django Backend API
│   ├── accounts/                # User & Doctor models
│   │   ├── models.py            # User, Doctor models
│   │   ├── views.py             # Auth views (login, signup, Google)
│   │   ├── serializers.py       # DRF serializers
│   │   └── urls.py              # Auth routes
│   ├── appointments/            # Appointment management
│   │   ├── models.py            # Clinic, Patient, Appointment models
│   │   ├── views.py             # Appointment CRUD views
│   │   ├── serializers.py       # DRF serializers
│   │   └── urls.py              # Appointment routes
│   ├── config/                  # Django configuration
│   │   ├── settings.py          # Development settings
│   │   ├── settings_production.py
│   │   ├── urls.py              # Root URL configuration
│   │   └── wsgi.py              # WSGI application
│   ├── manage.py
│   └── requirements.txt
│
├── clinic_partner_app/          # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── core/                # Constants & utilities
│   │   ├── data/                # Models & services
│   │   └── presentation/        # UI (screens, widgets, providers)
│   ├── images/
│   │   └── cerebro.jpg          # App logo
│   ├── android/                 # Android platform
│   ├── ios/                     # iOS platform
│   └── pubspec.yaml
│
├── DEPLOYMENT.md                # Production deployment guide
└── README.md                    # This file
```

---

## Quick Start

### Prerequisites

- Python 3.10+
- Flutter SDK 3.0+
- Git

### 1. Clone the Repository

```bash
git clone <repository-url>
cd clinic-partner
```

### 2. Backend Setup

```bash
# Navigate to backend
cd clinic_backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
.\venv\Scripts\Activate.ps1
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create sample data (optional)
python manage.py create_sample_data

# Create admin user
python manage.py createsuperuser

# Start development server
python manage.py runserver
```

The API will be available at `http://localhost:8000`

### 3. Flutter App Setup

```bash
# Navigate to Flutter app
cd clinic_partner_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## API Documentation

### Base URL

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Production | `https://api.yourdomain.com` |

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup/` | Register new user |
| POST | `/api/auth/login/` | Login with email/password |
| POST | `/api/auth/google/` | Google OAuth login |
| GET | `/api/auth/me/` | Get current user info |
| POST | `/api/auth/token/refresh/` | Refresh JWT token |
| POST | `/api/auth/register-doctor/` | Register as doctor |
| GET | `/api/auth/clinics/` | List available clinics |

### Appointment Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/appointments/` | List doctor's appointments |
| GET | `/api/appointments/{id}/` | Get appointment details |
| PATCH | `/api/appointments/{id}/` | Update appointment |

### Example API Calls

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"identifier": "doctor@test.com", "password": "doctor123"}'

# Get appointments (with token)
curl http://localhost:8000/api/appointments/ \
  -H "Authorization: Bearer <access_token>"

# Update appointment status
curl -X PATCH http://localhost:8000/api/appointments/1/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'
```

---

## Data Models

### User
```python
- email (unique)
- username
- first_name
- last_name
- auth_provider (email/google/microsoft)
- profile_picture
```

### Doctor
```python
- user (OneToOne → User)
- specialization
- clinic (ForeignKey → Clinic)
```

### Clinic
```python
- name
- address
- phone
```

### Patient
```python
- name
- email (unique)
- phone
- date_of_birth
```

### Appointment
```python
- doctor (ForeignKey → Doctor)
- patient (ForeignKey → Patient)
- date
- time
- status (scheduled/in_progress/completed)
- video_call_link
- notes
```

---

## Configuration

### Backend Configuration

Edit `clinic_backend/config/settings.py`:

```python
# Database (default: SQLite)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Google OAuth
GOOGLE_OAUTH2_CLIENT_ID = 'your-client-id.apps.googleusercontent.com'

# CORS (for Flutter web)
CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:5000',
]
```

### Flutter Configuration

Edit `clinic_partner_app/lib/core/constants/api_constants.dart`:

```dart
static const bool isProduction = false;
static const String webDevBaseUrl = 'http://localhost:8000';
static const String prodBaseUrl = 'https://api.yourdomain.com';
```

Edit `clinic_partner_app/lib/core/constants/app_config.dart`:

```dart
static const String googleWebClientId = 
    'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
```

---

## Demo Mode

The Flutter app includes a demo mode for presentations without backend connectivity:

1. Open the app and navigate to the Doctor Home Screen
2. Tap the **flask icon** (🧪) in the app bar
3. Sample appointments will load instantly
4. A "DEMO" badge appears next to the title
5. Tap the flask icon again to exit demo mode

---

## Theming

The app uses a custom color scheme inspired by the Cerebro neural network logo:

| Color | Hex Code | Usage |
|-------|----------|-------|
| Dark Navy | `#0F2A3D` | Primary background |
| Teal | `#00B8A9` | Primary accent |
| Green | `#6FCF4E` | Secondary accent |
| Light Navy | `#153A4D` | Gradient top |

---

## Testing

### Backend Tests

```bash
cd clinic_backend

# Run all tests
python manage.py test

# Run specific app tests
python manage.py test accounts
python manage.py test appointments
```

### Flutter Tests

```bash
cd clinic_partner_app

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Manual Testing

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed testing checklists.

---

## Production Deployment

### Backend Deployment

1. Configure environment variables
2. Set `DEBUG = False`
3. Configure PostgreSQL database
4. Set up Gunicorn + Nginx
5. Enable HTTPS with SSL certificate

### Flutter Deployment

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment instructions.

---

## Tech Stack Details

### Backend
| Package | Version | Purpose |
|---------|---------|---------|
| Django | 4.2.x | Web framework |
| djangorestframework | 3.14+ | REST API |
| djangorestframework-simplejwt | 5.3+ | JWT authentication |
| django-cors-headers | 4.3+ | CORS handling |
| google-auth | 2.25+ | Google OAuth |
| python-dotenv | 1.0+ | Environment variables |

### Flutter
| Package | Version | Purpose |
|---------|---------|---------|
| provider | 6.0+ | State management |
| http | 1.1+ | HTTP client |
| flutter_secure_storage | 9.0+ | Secure token storage |
| google_sign_in | 6.1+ | Google authentication |
| url_launcher | 6.2+ | External links |
| intl | 0.18+ | Date/time formatting |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- **Python**: Follow PEP 8 guidelines
- **Dart**: Follow official Dart style guide
- **Commits**: Use conventional commit messages

---

## Security

- JWT tokens with short expiration (access: 1 hour, refresh: 7 days)
- Secure token storage using Flutter Secure Storage
- HTTPS required in production
- CORS restricted to allowed origins
- Password hashing with Django's built-in hasher
- Google OAuth for secure third-party authentication

---

## License

This project is proprietary software. All rights reserved.

---

## Support

For support or inquiries, contact the development team.

---

<p align="center">
  <strong>CEREBRO - Mind Re-Wired</strong><br>
  Built with Django 🐍 and Flutter 💙
</p>
