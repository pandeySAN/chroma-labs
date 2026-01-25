from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    SignupView,
    LoginView,
    GoogleOAuthView,
    CurrentUserView,
    RegisterDoctorView,
    ListClinicsView,
)

app_name = 'accounts'

urlpatterns = [
    # Email/Mobile + Password Authentication
    path('signup/', SignupView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
    
    # Google OAuth
    path('google/', GoogleOAuthView.as_view(), name='google_oauth'),
    
    # Token refresh
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Current user
    path('me/', CurrentUserView.as_view(), name='current_user'),
    
    # Doctor registration
    path('register-doctor/', RegisterDoctorView.as_view(), name='register_doctor'),
    path('clinics/', ListClinicsView.as_view(), name='list_clinics'),
]
