from rest_framework import status, permissions, generics
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Clinic, Patient, Appointment
from .serializers import (
    ClinicSerializer,
    PatientSerializer,
    AppointmentSerializer,
    AppointmentDetailSerializer,
)
from accounts.models import Doctor


class AppointmentListView(APIView):
    """
    API view for listing appointments.
    Filters by the authenticated doctor and orders by date/time.
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Check if user is a doctor
        try:
            doctor = Doctor.objects.get(user=user)
        except Doctor.DoesNotExist:
            return Response(
                {'error': 'User is not registered as a doctor'},
                status=status.HTTP_403_FORBIDDEN,
            )
        
        # Get appointments for this doctor, ordered by date and time
        appointments = Appointment.objects.filter(
            doctor=doctor
        ).select_related(
            'patient', 'doctor', 'doctor__user'
        ).order_by('date', 'time')
        
        # Optional filters
        status_filter = request.query_params.get('status')
        if status_filter:
            appointments = appointments.filter(status=status_filter)
        
        date_filter = request.query_params.get('date')
        if date_filter:
            appointments = appointments.filter(date=date_filter)
        
        serializer = AppointmentSerializer(appointments, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AppointmentDetailView(APIView):
    """
    API view for retrieving, updating, or deleting a specific appointment.
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_appointment(self, pk, user):
        """Helper to get appointment with permission check."""
        try:
            doctor = Doctor.objects.get(user=user)
            return Appointment.objects.select_related(
                'patient', 'doctor', 'doctor__user', 'doctor__clinic'
            ).get(pk=pk, doctor=doctor)
        except Doctor.DoesNotExist:
            return None
        except Appointment.DoesNotExist:
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
        
        # Only allow updating certain fields
        allowed_fields = ['status', 'video_call_link', 'notes', 'date', 'time']
        update_data = {k: v for k, v in request.data.items() if k in allowed_fields}
        
        serializer = AppointmentSerializer(
            appointment,
            data=update_data,
            partial=True,
            context={'request': request}
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
    """
    API view for creating a new appointment.
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        # Check if user is a doctor
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response(
                {'error': 'User is not registered as a doctor'},
                status=status.HTTP_403_FORBIDDEN,
            )
        
        serializer = AppointmentSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save(doctor=doctor)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PatientListCreateView(generics.ListCreateAPIView):
    """
    API view for listing and creating patients.
    """
    
    queryset = Patient.objects.all().order_by('name')
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]


class PatientDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    API view for patient details.
    """
    
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]


class ClinicListView(generics.ListAPIView):
    """
    API view for listing clinics.
    """
    
    queryset = Clinic.objects.all().order_by('name')
    serializer_class = ClinicSerializer
    permission_classes = [permissions.IsAuthenticated]


class ClinicDetailView(generics.RetrieveAPIView):
    """
    API view for clinic details.
    """
    
    queryset = Clinic.objects.all()
    serializer_class = ClinicSerializer
    permission_classes = [permissions.IsAuthenticated]
