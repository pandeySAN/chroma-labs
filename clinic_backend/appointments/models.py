from django.db import models
from django.utils.translation import gettext_lazy as _


class Clinic(models.Model):
    """
    Clinic model representing a medical facility.
    """
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
    """
    Patient model for storing patient information.
    """
    name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20)
    date_of_birth = models.DateField()
    
    class Meta:
        verbose_name = _('patient')
        verbose_name_plural = _('patients')
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.email})"


class Appointment(models.Model):
    """
    Appointment model for scheduling doctor-patient meetings.
    """
    
    class Status(models.TextChoices):
        SCHEDULED = 'scheduled', _('Scheduled')
        IN_PROGRESS = 'in_progress', _('In Progress')
        COMPLETED = 'completed', _('Completed')
    
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
    date = models.DateField()
    time = models.TimeField()
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SCHEDULED,
    )
    video_call_link = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = _('appointment')
        verbose_name_plural = _('appointments')
        ordering = ['-date', '-time']
    
    def __str__(self):
        return f"{self.patient.name} with Dr. {self.doctor.user.last_name} on {self.date} at {self.time}"
