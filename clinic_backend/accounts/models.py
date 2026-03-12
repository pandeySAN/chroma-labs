import random
import string
from datetime import timedelta

from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    """
    Custom User model for the Clinic Partner system.
    Extends Django's AbstractUser to support multiple auth providers.
    """
    
    class AuthProvider(models.TextChoices):
        EMAIL = 'email', _('Email')
        GOOGLE = 'google', _('Google')
        MICROSOFT = 'microsoft', _('Microsoft')
    
    email = models.EmailField(_('email address'), unique=True)
    auth_provider = models.CharField(
        max_length=20,
        choices=AuthProvider.choices,
        default=AuthProvider.EMAIL,
    )
    first_name = models.CharField(_('first name'), max_length=150)
    last_name = models.CharField(_('last name'), max_length=150)
    profile_picture = models.URLField(
        _('profile picture'),
        blank=True,
        null=True,
    )
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name']
    
    class Meta:
        verbose_name = _('user')
        verbose_name_plural = _('users')
        ordering = ['-date_joined']
    
    def __str__(self):
        return self.email
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()


class Doctor(models.Model):
    """
    Doctor model linked to a User account.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='doctor_profile',
    )
    specialization = models.CharField(max_length=100)
    clinic = models.ForeignKey(
        'appointments.Clinic',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='doctors',
    )
    
    class Meta:
        verbose_name = _('doctor')
        verbose_name_plural = _('doctors')
        ordering = ['user__last_name', 'user__first_name']
    
    def __str__(self):
        return f"Dr. {self.user.full_name} - {self.specialization}"


class PasswordResetOTP(models.Model):
    """
    Stores a 6-digit OTP for password reset.
    Expires after 10 minutes. Max 5 attempts per OTP.
    """

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='password_reset_otps',
    )
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.IntegerField(default=0)

    class Meta:
        verbose_name = _('password reset OTP')
        verbose_name_plural = _('password reset OTPs')
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.user.email} - {'Used' if self.is_used else 'Active'}"

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

    @property
    def is_valid(self):
        return not self.is_used and not self.is_expired and self.attempts < 5

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=10)
        super().save(*args, **kwargs)

    @classmethod
    def generate_otp(cls):
        return ''.join(random.choices(string.digits, k=6))

    @classmethod
    def create_for_user(cls, user):
        cls.objects.filter(user=user, is_used=False).update(is_used=True)
        otp_code = cls.generate_otp()
        return cls.objects.create(
            user=user,
            otp=otp_code,
            expires_at=timezone.now() + timedelta(minutes=10),
        )
