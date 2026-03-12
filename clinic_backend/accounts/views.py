from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.conf import settings
from django.db import transaction

from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from .models import Doctor
from appointments.models import Clinic
from .models import PasswordResetOTP
from .serializers import (
    UserSerializer, 
    DoctorSerializer,
    SignupSerializer,
    LoginSerializer,
    ForgotPasswordSerializer,
    VerifyOTPSerializer,
    ResetPasswordSerializer,
)

User = get_user_model()


class SignupView(APIView):
    """
    POST /api/auth/signup/
    
    Create a new user account with email/mobile and password.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        
        if serializer.is_valid():
            user = serializer.save()
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            # Check if user is a doctor
            is_doctor = Doctor.objects.filter(user=user).exists()
            doctor_data = None
            if is_doctor:
                doctor = Doctor.objects.select_related('clinic').get(user=user)
                doctor_data = DoctorSerializer(doctor).data
            
            return Response({
                'user': UserSerializer(user).data,
                'is_doctor': is_doctor,
                'doctor': doctor_data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
                'message': 'Account created successfully',
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    POST /api/auth/login/
    
    Authenticate user with email/mobile and password.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            # Check if user is a doctor
            is_doctor = Doctor.objects.filter(user=user).exists()
            
            # Get doctor data if applicable
            doctor_data = None
            if is_doctor:
                doctor = Doctor.objects.select_related('clinic').get(user=user)
                doctor_data = DoctorSerializer(doctor).data
            
            return Response({
                'user': UserSerializer(user).data,
                'is_doctor': is_doctor,
                'doctor': doctor_data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GoogleOAuthView(APIView):
    """
    POST /api/auth/google/
    
    Accepts a Google ID token or access token, verifies it,
    creates or gets the user, and returns JWT tokens.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        token = request.data.get('token')
        token_type = request.data.get('token_type', 'id_token')
        
        if not token:
            return Response(
                {'error': 'Token is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        try:
            if token_type == 'access_token':
                userinfo = self._verify_access_token(token)
            else:
                userinfo = self._verify_id_token(token)
            
            email = userinfo.get('email')
            if not email:
                return Response(
                    {'error': 'Email not provided by Google'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            
            first_name = userinfo.get('given_name', '')
            last_name = userinfo.get('family_name', '')
            profile_picture = userinfo.get('picture', '')
            
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email.split('@')[0],
                    'first_name': first_name,
                    'last_name': last_name,
                    'profile_picture': profile_picture,
                    'auth_provider': 'google',
                }
            )
            
            if not created:
                updated = False
                if first_name and user.first_name != first_name:
                    user.first_name = first_name
                    updated = True
                if last_name and user.last_name != last_name:
                    user.last_name = last_name
                    updated = True
                if profile_picture and user.profile_picture != profile_picture:
                    user.profile_picture = profile_picture
                    updated = True
                if updated:
                    user.save()
            
            refresh = RefreshToken.for_user(user)
            
            is_doctor = Doctor.objects.filter(user=user).exists()
            doctor_data = None
            if is_doctor:
                doctor = Doctor.objects.select_related('clinic').get(user=user)
                doctor_data = DoctorSerializer(doctor).data
            
            return Response({
                'user': UserSerializer(user).data,
                'is_doctor': is_doctor,
                'doctor': doctor_data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
                'created': created,
            }, status=status.HTTP_200_OK)
            
        except ValueError as e:
            return Response(
                {'error': 'Invalid Google token', 'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except Exception as e:
            return Response(
                {'error': 'Authentication failed', 'detail': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
    
    @staticmethod
    def _verify_id_token(token):
        """Verify a Google ID token (JWT) and return user info."""
        return id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            settings.GOOGLE_OAUTH2_CLIENT_ID,
        )
    
    @staticmethod
    def _verify_access_token(token):
        """Verify a Google access token by calling Google's userinfo API."""
        import requests
        resp = requests.get(
            'https://www.googleapis.com/oauth2/v3/userinfo',
            headers={'Authorization': f'Bearer {token}'},
            timeout=10,
        )
        if resp.status_code != 200:
            raise ValueError('Invalid access token')
        return resp.json()


class CurrentUserView(APIView):
    """
    GET /api/auth/me/
    
    Returns the currently authenticated user's information.
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Check if user is a doctor and include doctor info
        doctor_data = None
        try:
            doctor = Doctor.objects.select_related('clinic').get(user=user)
            doctor_data = DoctorSerializer(doctor).data
        except Doctor.DoesNotExist:
            pass
        
        return Response({
            'user': UserSerializer(user).data,
            'is_doctor': doctor_data is not None,
            'doctor': doctor_data,
        }, status=status.HTTP_200_OK)


class RegisterDoctorView(APIView):
    """
    POST /api/auth/register-doctor/
    
    Register the current user as a doctor.
    Creates a doctor profile for the authenticated user.
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = request.user
        
        # Check if already a doctor
        if Doctor.objects.filter(user=user).exists():
            doctor = Doctor.objects.select_related('clinic').get(user=user)
            return Response({
                'message': 'Already registered as a doctor',
                'doctor': DoctorSerializer(doctor).data,
            }, status=status.HTTP_200_OK)
        
        # Get data from request
        specialization = request.data.get('specialization', 'General Practitioner')
        clinic_id = request.data.get('clinic_id')
        
        try:
            with transaction.atomic():
                # Get or create a default clinic if not provided
                clinic = None
                if clinic_id:
                    try:
                        clinic = Clinic.objects.get(id=clinic_id)
                    except Clinic.DoesNotExist:
                        pass
                
                if clinic is None:
                    # Create a default clinic for the doctor
                    clinic, _ = Clinic.objects.get_or_create(
                        name="My Clinic",
                        defaults={
                            'address': 'Address not set',
                            'phone': '',
                        }
                    )
                
                # Create doctor profile
                doctor = Doctor.objects.create(
                    user=user,
                    specialization=specialization,
                    clinic=clinic,
                )
                
                return Response({
                    'message': 'Successfully registered as a doctor',
                    'doctor': DoctorSerializer(doctor).data,
                    'is_doctor': True,
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response(
                {'error': f'Failed to register as doctor: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class ListClinicsView(APIView):
    """
    GET /api/auth/clinics/
    
    Returns list of available clinics for doctor registration.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        from appointments.serializers import ClinicSerializer
        clinics = Clinic.objects.all().order_by('name')
        serializer = ClinicSerializer(clinics, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ForgotPasswordView(APIView):
    """
    POST /api/auth/forgot-password/
    
    Sends a 6-digit OTP to the user's email for password reset.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            user = serializer.context['user']
            
            otp_obj = PasswordResetOTP.create_for_user(user)
            
            try:
                from django.core.mail import send_mail
                send_mail(
                    subject='CEREBRO - Password Reset OTP',
                    message=(
                        f'Hello {user.full_name},\n\n'
                        f'Your OTP for password reset is: {otp_obj.otp}\n\n'
                        f'This code is valid for 10 minutes.\n'
                        f'If you did not request this, please ignore this email.\n\n'
                        f'- CEREBRO Clinic Partner'
                    ),
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
            except Exception:
                pass
            
            masked_email = self._mask_email(user.email)
            
            return Response({
                'message': f'OTP sent to {masked_email}',
                'email': masked_email,
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @staticmethod
    def _mask_email(email):
        parts = email.split('@')
        if len(parts) != 2:
            return email
        local = parts[0]
        if len(local) <= 2:
            masked = local[0] + '*' * (len(local) - 1)
        else:
            masked = local[0] + '*' * (len(local) - 2) + local[-1]
        return f'{masked}@{parts[1]}'


class VerifyOTPView(APIView):
    """
    POST /api/auth/verify-otp/
    
    Verifies the OTP code. Returns a success response if valid.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        
        if serializer.is_valid():
            return Response({
                'message': 'OTP verified successfully',
                'verified': True,
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ResetPasswordView(APIView):
    """
    POST /api/auth/reset-password/
    
    Resets the user's password after OTP verification.
    Expects identifier, otp, and new_password.
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            user = serializer.validated_data['user']
            new_password = serializer.validated_data['new_password']
            
            user.set_password(new_password)
            user.save()
            
            PasswordResetOTP.objects.filter(
                user=user, is_used=False
            ).update(is_used=True)
            
            return Response({
                'message': 'Password reset successfully',
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
