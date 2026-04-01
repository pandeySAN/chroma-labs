from django.urls import path
from .views import (
    AppointmentListView,
    AppointmentDetailView,
    AppointmentCreateView,
    PatientListCreateView,
    PatientDetailView,
    ClinicListView,
    ClinicDetailView,
    ClinicSearchView,
    AvailableSlotsView,
    PatientBookAppointmentView,
    PatientAppointmentListView,
    CancelAppointmentView,
)

app_name = 'appointments'

urlpatterns = [
    # Doctor-facing
    path('', AppointmentListView.as_view(), name='appointment_list'),
    path('create/', AppointmentCreateView.as_view(), name='appointment_create'),
    path('<int:pk>/', AppointmentDetailView.as_view(), name='appointment_detail'),

    # Patient-facing booking
    path('slots/', AvailableSlotsView.as_view(), name='available_slots'),
    path('book/', PatientBookAppointmentView.as_view(), name='patient_book'),
    path('my/', PatientAppointmentListView.as_view(), name='patient_appointments'),
    path('<int:pk>/cancel/', CancelAppointmentView.as_view(), name='cancel_appointment'),

    # Patients (CRUD for doctor dashboard)
    path('patients/', PatientListCreateView.as_view(), name='patient_list_create'),
    path('patients/<int:pk>/', PatientDetailView.as_view(), name='patient_detail'),

    # Clinics
    path('clinics/', ClinicListView.as_view(), name='clinic_list'),
    path('clinics/<int:pk>/', ClinicDetailView.as_view(), name='clinic_detail'),
]
