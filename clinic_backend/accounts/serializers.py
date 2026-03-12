from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Doctor, PasswordResetOTP

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""
    
    full_name = serializers.ReadOnlyField()
    
    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'first_name',
            'last_name',
            'full_name',
            'auth_provider',
            'profile_picture',
            'date_joined',
        ]
        read_only_fields = ['id', 'date_joined', 'auth_provider']


class DoctorSerializer(serializers.ModelSerializer):
    """Serializer for Doctor model with nested user data."""
    
    user = UserSerializer(read_only=True)
    clinic_name = serializers.CharField(source='clinic.name', read_only=True)
    
    class Meta:
        model = Doctor
        fields = [
            'id',
            'user',
            'specialization',
            'clinic',
            'clinic_name',
        ]
        read_only_fields = ['id']


class SignupSerializer(serializers.Serializer):
    """Serializer for user signup with email/mobile + password."""
    
    name = serializers.CharField(max_length=150, required=True)
    identifier = serializers.CharField(max_length=150, required=True)
    password = serializers.CharField(
        write_only=True,
        required=True,
        min_length=6,
        style={'input_type': 'password'},
    )
    
    def validate_identifier(self, value):
        """Check if identifier (email or mobile) already exists."""
        # Check if it's an email
        if '@' in value:
            if User.objects.filter(email=value).exists():
                raise serializers.ValidationError("A user with this email already exists.")
        else:
            # It's a mobile number - store in username field
            if User.objects.filter(username=value).exists():
                raise serializers.ValidationError("A user with this mobile number already exists.")
        return value
    
    def create(self, validated_data):
        name = validated_data['name']
        identifier = validated_data['identifier']
        password = validated_data['password']
        
        # Split name into first and last name
        name_parts = name.strip().split(' ', 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ''
        
        # Determine if identifier is email or mobile
        if '@' in identifier:
            email = identifier
            username = identifier.split('@')[0]
        else:
            email = f"{identifier}@mobile.local"  # Placeholder email for mobile users
            username = identifier
        
        # Create user
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            auth_provider='email',
        )
        
        return user


class LoginSerializer(serializers.Serializer):
    """Serializer for user login with email/mobile + password."""
    
    identifier = serializers.CharField(max_length=150, required=True)
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
    )
    
    def validate(self, attrs):
        identifier = attrs.get('identifier')
        password = attrs.get('password')
        
        # Find user by email or username (mobile)
        user = None
        if '@' in identifier:
            try:
                user = User.objects.get(email=identifier)
            except User.DoesNotExist:
                pass
        else:
            try:
                user = User.objects.get(username=identifier)
            except User.DoesNotExist:
                pass
        
        if user is None:
            raise serializers.ValidationError({
                'identifier': 'No account found with this email/mobile.'
            })
        
        if not user.check_password(password):
            raise serializers.ValidationError({
                'password': 'Incorrect password.'
            })
        
        if not user.is_active:
            raise serializers.ValidationError({
                'identifier': 'This account has been deactivated.'
            })
        
        attrs['user'] = user
        return attrs


class ForgotPasswordSerializer(serializers.Serializer):
    """Accepts an email/mobile identifier and locates the user."""

    identifier = serializers.CharField(max_length=150, required=True)

    def validate_identifier(self, value):
        user = None
        if '@' in value:
            try:
                user = User.objects.get(email=value)
            except User.DoesNotExist:
                pass
        else:
            try:
                user = User.objects.get(username=value)
            except User.DoesNotExist:
                pass

        if user is None:
            raise serializers.ValidationError(
                'No account found with this email/mobile.'
            )

        if user.auth_provider != 'email':
            raise serializers.ValidationError(
                f'This account uses {user.auth_provider} sign-in. '
                'Please use that method to access your account.'
            )

        self.context['user'] = user
        return value


class VerifyOTPSerializer(serializers.Serializer):
    """Validates the OTP code for a given identifier."""

    identifier = serializers.CharField(max_length=150, required=True)
    otp = serializers.CharField(max_length=6, min_length=6, required=True)

    def validate(self, attrs):
        identifier = attrs['identifier']
        otp = attrs['otp']

        user = None
        if '@' in identifier:
            try:
                user = User.objects.get(email=identifier)
            except User.DoesNotExist:
                pass
        else:
            try:
                user = User.objects.get(username=identifier)
            except User.DoesNotExist:
                pass

        if user is None:
            raise serializers.ValidationError(
                {'identifier': 'No account found.'}
            )

        otp_obj = PasswordResetOTP.objects.filter(
            user=user,
            is_used=False,
        ).order_by('-created_at').first()

        if otp_obj is None:
            raise serializers.ValidationError(
                {'otp': 'No active OTP found. Please request a new one.'}
            )

        otp_obj.attempts += 1
        otp_obj.save(update_fields=['attempts'])

        if otp_obj.is_expired:
            otp_obj.is_used = True
            otp_obj.save(update_fields=['is_used'])
            raise serializers.ValidationError(
                {'otp': 'OTP has expired. Please request a new one.'}
            )

        if otp_obj.attempts >= 5:
            otp_obj.is_used = True
            otp_obj.save(update_fields=['is_used'])
            raise serializers.ValidationError(
                {'otp': 'Too many attempts. Please request a new OTP.'}
            )

        if otp_obj.otp != otp:
            raise serializers.ValidationError(
                {'otp': 'Invalid OTP code.'}
            )

        otp_obj.is_used = True
        otp_obj.save(update_fields=['is_used'])

        attrs['user'] = user
        return attrs


class ResetPasswordSerializer(serializers.Serializer):
    """Sets a new password for the user after OTP verification."""

    identifier = serializers.CharField(max_length=150, required=True)
    otp = serializers.CharField(max_length=6, min_length=6, required=True)
    new_password = serializers.CharField(
        write_only=True,
        required=True,
        min_length=6,
        style={'input_type': 'password'},
    )

    def validate(self, attrs):
        identifier = attrs['identifier']

        user = None
        if '@' in identifier:
            try:
                user = User.objects.get(email=identifier)
            except User.DoesNotExist:
                pass
        else:
            try:
                user = User.objects.get(username=identifier)
            except User.DoesNotExist:
                pass

        if user is None:
            raise serializers.ValidationError(
                {'identifier': 'No account found.'}
            )

        try:
            validate_password(attrs['new_password'], user)
        except Exception as e:
            raise serializers.ValidationError(
                {'new_password': list(e.messages)}
            )

        attrs['user'] = user
        return attrs
