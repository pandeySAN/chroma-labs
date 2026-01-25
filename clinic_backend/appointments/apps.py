from django.apps import AppConfig


class AppointmentsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'appointments'
    verbose_name = 'Appointments Management'

    def ready(self):
        # Import signals when app is ready
        try:
            import appointments.signals  # noqa: F401
        except ImportError:
            pass
