from django.urls import path
from .views import (
    AppointmentListView,
    AppointmentDetailView,
    AppointmentCreateView,
    PatientListCreateView,
    PatientDetailView,
    ClinicListView,
    ClinicDetailView,
)

app_name = 'appointments'

urlpatterns = [
    # GET /api/appointments/
    path('', AppointmentListView.as_view(), name='appointment_list'),
    
    # Additional appointment endpoints
    path('create/', AppointmentCreateView.as_view(), name='appointment_create'),
    path('<int:pk>/', AppointmentDetailView.as_view(), name='appointment_detail'),
    
    # Patient endpoints
    path('patients/', PatientListCreateView.as_view(), name='patient_list_create'),
    path('patients/<int:pk>/', PatientDetailView.as_view(), name='patient_detail'),
    
    # Clinic endpoints
    path('clinics/', ClinicListView.as_view(), name='clinic_list'),
    path('clinics/<int:pk>/', ClinicDetailView.as_view(), name='clinic_detail'),
]
