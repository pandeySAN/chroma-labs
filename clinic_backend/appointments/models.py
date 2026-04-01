from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class Clinic(models.Model):
    name = models.CharField(max_length=200)
    address = models.TextField()
    phone = models.CharField(max_length=20)

    class Meta:
        verbose_name = _('clinic')
        verbose_name_plural = _('clinics')
        ordering = ['name']

    def __str__(self):
        return self.name


class Patient(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_profile',
        null=True,
        blank=True,
    )
    name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, default='')
    date_of_birth = models.DateField(null=True, blank=True)

    class Meta:
        verbose_name = _('patient')
        verbose_name_plural = _('patients')
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.email})"


class Appointment(models.Model):
    class Status(models.TextChoices):
        PENDING_PAYMENT = 'pending_payment', _('Pending Payment')
        SCHEDULED = 'scheduled', _('Scheduled')
        IN_PROGRESS = 'in_progress', _('In Progress')
        COMPLETED = 'completed', _('Completed')
        CONFIRMED = 'confirmed', _('Confirmed')
        CANCELLED = 'cancelled', _('Cancelled')

    doctor = models.ForeignKey(
        'accounts.Doctor',
        on_delete=models.CASCADE,
        related_name='appointments',
    )
    patient = models.ForeignKey(
        Patient,
        on_delete=models.CASCADE,
        related_name='appointments',
    )
    clinic = models.ForeignKey(
        Clinic,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='appointments',
    )
    date = models.DateField()
    time = models.TimeField()
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SCHEDULED,
    )
    video_call_link = models.URLField(blank=True, null=True)
    consultation_fee = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
    )
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True)

    class Meta:
        verbose_name = _('appointment')
        verbose_name_plural = _('appointments')
        ordering = ['-date', '-time']
        constraints = []

    def __str__(self):
        return f"{self.patient.name} with Dr. {self.doctor.user.last_name} on {self.date} at {self.time}"
