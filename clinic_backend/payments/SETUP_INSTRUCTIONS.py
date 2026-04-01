# ─────────────────────────────────────────────────────────────────────────────
# ADD THESE TO clinic_backend/config/settings/base.py
# ─────────────────────────────────────────────────────────────────────────────

# 1. Register the new payments app inside INSTALLED_APPS:
INSTALLED_APPS = [
    # ... your existing apps ...
    'apps.payments',          # ← ADD THIS
]

# 2. Razorpay credentials — read from .env
# Make sure python-decouple or django-environ is already set up.
# If you use os.environ directly, replace config() with os.environ.get()
import os
RAZORPAY_KEY_ID     = os.environ.get('RAZORPAY_KEY_ID', '')
RAZORPAY_KEY_SECRET = os.environ.get('RAZORPAY_KEY_SECRET', '')

# 3. Add payments URLs in clinic_backend/config/urls.py:
# urlpatterns = [
#     ...existing patterns...
#     path('api/payments/', include('apps.payments.urls')),   ← ADD THIS
# ]
