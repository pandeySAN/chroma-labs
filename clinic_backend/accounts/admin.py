from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, Doctor


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin configuration for custom User model."""
    
    list_display = ['email', 'first_name', 'last_name', 'auth_provider', 'is_active', 'date_joined']
    list_filter = ['auth_provider', 'is_active', 'is_staff', 'date_joined']
    search_fields = ['email', 'first_name', 'last_name']
    ordering = ['-date_joined']
    
    fieldsets = (
        (None, {'fields': ('email', 'username', 'password')}),
        (_('Personal info'), {
            'fields': ('first_name', 'last_name', 'profile_picture')
        }),
        (_('Authentication'), {
            'fields': ('auth_provider',)
        }),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'first_name', 'last_name', 'password1', 'password2', 'auth_provider'),
        }),
    )


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    """Admin configuration for Doctor model."""
    
    list_display = ['user', 'specialization', 'clinic']
    list_filter = ['specialization', 'clinic']
    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'specialization']
    raw_id_fields = ['user']
    autocomplete_fields = ['clinic']
