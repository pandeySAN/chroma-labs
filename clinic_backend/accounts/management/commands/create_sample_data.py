"""
Management command to create sample data for testing.

Usage:
    python manage.py create_sample_data
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from datetime import date, time, timedelta

from accounts.models import Doctor
from appointments.models import Clinic, Patient, Appointment

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates sample data for testing: 1 doctor, 1 clinic, 3 patients, 3 appointments'

    def handle(self, *args, **options):
        self.stdout.write('Creating sample data...\n')

        # Create Clinic
        clinic, created = Clinic.objects.get_or_create(
            name='HealthCare Clinic',
            defaults={
                'address': '123 Medical Center Drive, Suite 100, New York, NY 10001',
                'phone': '+1-555-123-4567',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created clinic: {clinic.name}'))
        else:
            self.stdout.write(f'  Clinic already exists: {clinic.name}')

        # Create Doctor User
        doctor_user, created = User.objects.get_or_create(
            email='doctor@test.com',
            defaults={
                'username': 'doctor',
                'first_name': 'John',
                'last_name': 'Smith',
                'auth_provider': 'email',
            }
        )
        if created:
            doctor_user.set_password('doctor123')
            doctor_user.save()
            self.stdout.write(self.style.SUCCESS(f'✓ Created doctor user: {doctor_user.email}'))
            self.stdout.write(self.style.WARNING(f'  Password: doctor123'))
        else:
            self.stdout.write(f'  Doctor user already exists: {doctor_user.email}')

        # Create Doctor Profile
        doctor, created = Doctor.objects.get_or_create(
            user=doctor_user,
            defaults={
                'specialization': 'General Medicine',
                'clinic': clinic,
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created doctor profile: Dr. {doctor_user.full_name}'))
        else:
            self.stdout.write(f'  Doctor profile already exists: Dr. {doctor_user.full_name}')

        # Create Patients
        patients_data = [
            {
                'name': 'Alice Johnson',
                'email': 'alice.johnson@email.com',
                'phone': '+1-555-111-2222',
                'date_of_birth': date(1985, 3, 15),
            },
            {
                'name': 'Bob Williams',
                'email': 'bob.williams@email.com',
                'phone': '+1-555-333-4444',
                'date_of_birth': date(1990, 7, 22),
            },
            {
                'name': 'Carol Davis',
                'email': 'carol.davis@email.com',
                'phone': '+1-555-555-6666',
                'date_of_birth': date(1978, 11, 8),
            },
        ]

        patients = []
        for patient_data in patients_data:
            patient, created = Patient.objects.get_or_create(
                email=patient_data['email'],
                defaults=patient_data,
            )
            patients.append(patient)
            if created:
                self.stdout.write(self.style.SUCCESS(f'✓ Created patient: {patient.name}'))
            else:
                self.stdout.write(f'  Patient already exists: {patient.name}')

        # Create Appointments
        today = date.today()
        appointments_data = [
            {
                'patient': patients[0],
                'date': today,
                'time': time(9, 0),
                'status': 'scheduled',
                'notes': 'Regular checkup appointment',
            },
            {
                'patient': patients[1],
                'date': today,
                'time': time(10, 30),
                'status': 'scheduled',
                'video_call_link': 'https://meet.google.com/abc-defg-hij',
                'notes': 'Follow-up consultation via video call',
            },
            {
                'patient': patients[2],
                'date': today + timedelta(days=1),
                'time': time(14, 0),
                'status': 'scheduled',
                'notes': 'New patient consultation',
            },
        ]

        for appt_data in appointments_data:
            appointment, created = Appointment.objects.get_or_create(
                doctor=doctor,
                patient=appt_data['patient'],
                date=appt_data['date'],
                time=appt_data['time'],
                defaults={
                    'status': appt_data['status'],
                    'video_call_link': appt_data.get('video_call_link'),
                    'notes': appt_data.get('notes'),
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(
                    f'✓ Created appointment: {appointment.patient.name} on {appointment.date} at {appointment.time}'
                ))
            else:
                self.stdout.write(
                    f'  Appointment already exists: {appointment.patient.name} on {appointment.date}'
                )

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 50))
        self.stdout.write(self.style.SUCCESS('Sample data creation complete!'))
        self.stdout.write(self.style.SUCCESS('=' * 50))
        self.stdout.write('')
        self.stdout.write('Test credentials:')
        self.stdout.write(f'  Email: doctor@test.com')
        self.stdout.write(f'  Password: doctor123')
        self.stdout.write('')
