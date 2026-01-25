from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Doctor

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
