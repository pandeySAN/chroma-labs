from django.contrib import admin
from .models import Clinic, Patient, Appointment


@admin.register(Clinic)
class ClinicAdmin(admin.ModelAdmin):
    """Admin configuration for Clinic model."""
    
    list_display = ['name', 'phone', 'address']
    search_fields = ['name', 'address', 'phone']
    ordering = ['name']


@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    """Admin configuration for Patient model."""
    
    list_display = ['name', 'email', 'phone', 'date_of_birth']
    search_fields = ['name', 'email', 'phone']
    list_filter = ['date_of_birth']
    ordering = ['name']


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    """Admin configuration for Appointment model."""
    
    list_display = ['patient', 'doctor', 'date', 'time', 'status']
    list_filter = ['status', 'date', 'doctor']
    search_fields = [
        'patient__name', 'patient__email',
        'doctor__user__first_name', 'doctor__user__last_name',
    ]
    raw_id_fields = ['patient', 'doctor']
    date_hierarchy = 'date'
    ordering = ['-date', '-time']
    
    fieldsets = (
        ('Appointment Info', {
            'fields': ('doctor', 'patient', 'date', 'time', 'status')
        }),
        ('Video Call', {
            'fields': ('video_call_link',),
            'classes': ('collapse',),
        }),
        ('Notes', {
            'fields': ('notes',),
            'classes': ('collapse',),
        }),
    )
