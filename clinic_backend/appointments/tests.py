from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status
from datetime import date, time

from accounts.models import Doctor
from .models import Clinic, Patient, Appointment

User = get_user_model()


class ClinicModelTests(TestCase):
    """Tests for the Clinic model."""
    
    def test_create_clinic(self):
        """Test creating a clinic."""
        clinic = Clinic.objects.create(
            name='Test Clinic',
            address='123 Main St',
            phone='555-1234',
        )
        
        self.assertEqual(str(clinic), 'Test Clinic')


class PatientModelTests(TestCase):
    """Tests for the Patient model."""
    
    def test_create_patient(self):
        """Test creating a patient."""
        patient = Patient.objects.create(
            name='John Doe',
            email='john@example.com',
            phone='555-5678',
            date_of_birth=date(1990, 1, 1),
        )
        
        self.assertEqual(str(patient), 'John Doe (john@example.com)')


class AppointmentModelTests(TestCase):
    """Tests for the Appointment model."""
    
    def setUp(self):
        """Set up test data."""
        self.clinic = Clinic.objects.create(
            name='Test Clinic',
            address='123 Main St',
            phone='555-1234',
        )
        
        self.doctor_user = User.objects.create_user(
            username='doctor',
            email='doctor@example.com',
            password='testpass123',
            first_name='Jane',
            last_name='Smith',
        )
        
        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            specialization='General Medicine',
            clinic=self.clinic,
        )
        
        self.patient = Patient.objects.create(
            name='John Doe',
            email='john@example.com',
            phone='555-5678',
            date_of_birth=date(1990, 1, 1),
        )
    
    def test_create_appointment(self):
        """Test creating an appointment."""
        appointment = Appointment.objects.create(
            doctor=self.doctor,
            patient=self.patient,
            date=date(2026, 2, 15),
            time=time(10, 0),
        )
        
        self.assertEqual(appointment.status, 'scheduled')
        self.assertIn('John Doe', str(appointment))
        self.assertIn('Smith', str(appointment))


class AppointmentAPITests(APITestCase):
    """Tests for appointment API endpoints."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
        )
        
        self.clinic = Clinic.objects.create(
            name='Test Clinic',
            address='123 Main St',
            phone='555-1234',
        )
        
        self.doctor_user = User.objects.create_user(
            username='doctor',
            email='doctor@example.com',
            password='testpass123',
            first_name='Jane',
            last_name='Smith',
        )
        
        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            specialization='General Medicine',
            clinic=self.clinic,
        )
        
        self.patient = Patient.objects.create(
            name='John Doe',
            email='john@example.com',
            phone='555-5678',
            date_of_birth=date(1990, 1, 1),
        )
    
    def test_list_appointments_authenticated(self):
        """Test listing appointments for authenticated user."""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.get('/api/appointments/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_list_appointments_unauthenticated(self):
        """Test listing appointments requires authentication."""
        response = self.client.get('/api/appointments/')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_create_appointment(self):
        """Test creating an appointment."""
        self.client.force_authenticate(user=self.user)
        
        payload = {
            'doctor': self.doctor.id,
            'patient': self.patient.id,
            'date': '2026-02-15',
            'time': '10:00:00',
        }
        
        response = self.client.post('/api/appointments/', payload)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
