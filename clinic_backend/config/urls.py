"""
URL configuration for clinic_backend project.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from appointments.views import ClinicSearchView

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # API URLs
    path('api/auth/', include('accounts.urls')),
    path('api/appointments/', include('appointments.urls')),
    path('api/clinics/search/', ClinicSearchView.as_view(), name='clinic_search'),
    path('api/payments/', include('payments.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
