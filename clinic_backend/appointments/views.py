from datetime import datetime, timedelta, time as dt_time

from django.db.models import Q
from rest_framework import status, permissions, generics
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Clinic, Patient, Appointment
from .permissions import IsPatient
from .serializers import (
    ClinicSerializer,
    ClinicSearchSerializer,
    PatientSerializer,
    AppointmentSerializer,
    AppointmentDetailSerializer,
    BookAppointmentSerializer,
    PatientAppointmentSerializer,
)
from accounts.models import Doctor


# ---------------------------------------------------------------------------
# Doctor-facing views (unchanged except AppointmentListView role handling)
# ---------------------------------------------------------------------------

class AppointmentListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user

        if user.role == 'doctor':
            try:
                doctor = Doctor.objects.get(user=user)
            except Doctor.DoesNotExist:
                return Response(
                    {'error': 'User is not registered as a doctor'},
                    status=status.HTTP_403_FORBIDDEN,
                )
            appointments = Appointment.objects.filter(
                doctor=doctor
            ).select_related(
                'patient', 'doctor', 'doctor__user', 'clinic'
            ).order_by('date', 'time')
        elif user.role == 'patient':
            try:
                patient = Patient.objects.get(user=user)
            except Patient.DoesNotExist:
                return Response([], status=status.HTTP_200_OK)
            appointments = Appointment.objects.filter(
                patient=patient
            ).select_related(
                'doctor', 'doctor__user', 'clinic'
            ).order_by('date', 'time')
        else:
            return Response(
                {'error': 'Unknown role'},
                status=status.HTTP_403_FORBIDDEN,
            )

        status_filter = request.query_params.get('status')
        if status_filter:
            appointments = appointments.filter(status=status_filter)

        date_filter = request.query_params.get('date')
        if date_filter:
            appointments = appointments.filter(date=date_filter)

        if user.role == 'patient':
            serializer = PatientAppointmentSerializer(appointments, many=True)
        else:
            serializer = AppointmentSerializer(appointments, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AppointmentDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_appointment(self, pk, user):
        try:
            doctor = Doctor.objects.get(user=user)
            return Appointment.objects.select_related(
                'patient', 'doctor', 'doctor__user', 'clinic'
            ).get(pk=pk, doctor=doctor)
        except (Doctor.DoesNotExist, Appointment.DoesNotExist):
            return None

    def get(self, request, pk):
        appointment = self.get_appointment(pk, request.user)
        if not appointment:
            return Response(
                {'error': 'Appointment not found'},
                status=status.HTTP_404_NOT_FOUND,
            )
        serializer = AppointmentDetailSerializer(appointment)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request, pk):
        appointment = self.get_appointment(pk, request.user)
        if not appointment:
            return Response(
                {'error': 'Appointment not found'},
                status=status.HTTP_404_NOT_FOUND,
            )
        allowed_fields = ['status', 'video_call_link', 'notes', 'date', 'time']
        update_data = {
            k: v for k, v in request.data.items() if k in allowed_fields
        }
        serializer = AppointmentSerializer(
            appointment,
            data=update_data,
            partial=True,
            context={'request': request},
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        appointment = self.get_appointment(pk, request.user)
        if not appointment:
            return Response(
                {'error': 'Appointment not found'},
                status=status.HTTP_404_NOT_FOUND,
            )
        appointment.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class AppointmentCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response(
                {'error': 'User is not registered as a doctor'},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = AppointmentSerializer(
            data=request.data, context={'request': request}
        )
        if serializer.is_valid():
            serializer.save(doctor=doctor)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PatientListCreateView(generics.ListCreateAPIView):
    queryset = Patient.objects.all().order_by('name')
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]


class PatientDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]


class ClinicListView(generics.ListAPIView):
    queryset = Clinic.objects.all().order_by('name')
    serializer_class = ClinicSerializer
    permission_classes = [permissions.IsAuthenticated]


class ClinicDetailView(generics.RetrieveAPIView):
    queryset = Clinic.objects.all()
    serializer_class = ClinicSerializer
    permission_classes = [permissions.IsAuthenticated]


# ---------------------------------------------------------------------------
# Patient-facing views (new)
# ---------------------------------------------------------------------------

class ClinicSearchView(APIView):
    """GET /api/clinics/search/?q=name — public clinic search."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        clinics = Clinic.objects.prefetch_related('doctors', 'doctors__user')
        if query:
            clinics = clinics.filter(
                Q(name__icontains=query) | Q(address__icontains=query)
            )
        serializer = ClinicSearchSerializer(clinics[:50], many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AvailableSlotsView(APIView):
    """GET /api/appointments/slots/?doctor_id=&date=YYYY-MM-DD"""

    permission_classes = [permissions.IsAuthenticated]

    SLOT_START = dt_time(9, 0)
    SLOT_END = dt_time(18, 0)
    SLOT_DURATION_MIN = 30

    def get(self, request):
        doctor_id = request.query_params.get('doctor_id')
        date_str = request.query_params.get('date')

        if not doctor_id or not date_str:
            return Response(
                {'error': 'doctor_id and date are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Only real confirmed/active bookings block a slot.
        # pending_payment and cancelled appointments do NOT block slots.
        booked_times = set(
            Appointment.objects.filter(
                doctor_id=doctor_id,
                date=target_date,
                status__in=['scheduled', 'in_progress', 'confirmed'],
            ).values_list('time', flat=True)
        )

        now = datetime.now()
        is_today = target_date == now.date()

        slots = []
        current = datetime.combine(target_date, self.SLOT_START)
        end = datetime.combine(target_date, self.SLOT_END)
        while current < end:
            t = current.time()
            past = is_today and t <= now.time()
            slots.append({
                'time': t.strftime('%H:%M'),
                'is_available': (not past) and (t not in booked_times),
            })
            current += timedelta(minutes=self.SLOT_DURATION_MIN)

        return Response(slots, status=status.HTTP_200_OK)


def _get_or_create_patient(user):
    """Return the Patient linked to this user, creating one if needed."""
    try:
        return Patient.objects.get(user=user)
    except Patient.DoesNotExist:
        return Patient.objects.create(
            user=user,
            name=user.full_name or user.email.split('@')[0],
            email=user.email,
        )


class PatientBookAppointmentView(APIView):
    """POST /api/appointments/book/ — patient books an appointment."""

    permission_classes = [permissions.IsAuthenticated, IsPatient]

    def post(self, request):
        serializer = BookAppointmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            doctor = Doctor.objects.select_related('user').get(
                id=data['doctor_id']
            )
        except Doctor.DoesNotExist:
            return Response(
                {'error': 'Doctor not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            clinic = Clinic.objects.get(id=data['clinic_id'])
        except Clinic.DoesNotExist:
            return Response(
                {'error': 'Clinic not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Block only if slot has a real active booking (not pending/cancelled)
        if Appointment.objects.filter(
            doctor=doctor,
            date=data['date'],
            time=data['time'],
            status__in=['scheduled', 'in_progress', 'confirmed'],
        ).exists():
            return Response(
                {'error': 'This slot is already booked'},
                status=status.HTTP_409_CONFLICT,
            )

        patient = _get_or_create_patient(request.user)

        # Remove any stale pending_payment appointments for this slot
        # (from the same or other patients who abandoned payment)
        Appointment.objects.filter(
            doctor=doctor,
            date=data['date'],
            time=data['time'],
            status='pending_payment',
        ).delete()

        # Create with pending_payment — confirmed only after payment succeeds
        appointment = Appointment.objects.create(
            doctor=doctor,
            patient=patient,
            clinic=clinic,
            date=data['date'],
            time=data['time'],
            notes=data.get('notes', ''),
            consultation_fee=data.get('consultation_fee', 0),
            status='pending_payment',
        )

        return Response(
            PatientAppointmentSerializer(appointment).data,
            status=status.HTTP_201_CREATED,
        )


class PatientAppointmentListView(APIView):
    """GET /api/appointments/my/ — patient's own appointments."""

    permission_classes = [permissions.IsAuthenticated, IsPatient]

    def get(self, request):
        try:
            patient = Patient.objects.get(user=request.user)
        except Patient.DoesNotExist:
            return Response([], status=status.HTTP_200_OK)

        appointments = Appointment.objects.filter(
            patient=patient
        ).select_related(
            'doctor', 'doctor__user', 'clinic'
        ).order_by('date', 'time')

        status_filter = request.query_params.get('status')
        if status_filter:
            appointments = appointments.filter(status=status_filter)

        serializer = PatientAppointmentSerializer(appointments, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class CancelAppointmentView(APIView):
    """PATCH /api/appointments/<id>/cancel/ — patient cancels own."""

    permission_classes = [permissions.IsAuthenticated, IsPatient]

    def patch(self, request, pk):
        try:
            patient = Patient.objects.get(user=request.user)
        except Patient.DoesNotExist:
            return Response(
                {'error': 'Patient profile not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            appointment = Appointment.objects.get(pk=pk, patient=patient)
        except Appointment.DoesNotExist:
            return Response(
                {'error': 'Appointment not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if appointment.status == 'cancelled':
            return Response(
                {'error': 'Appointment is already cancelled'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        appointment.status = 'cancelled'
        appointment.save(update_fields=['status'])
        return Response(
            PatientAppointmentSerializer(appointment).data,
            status=status.HTTP_200_OK,
        )
