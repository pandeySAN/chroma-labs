from rest_framework import serializers
from .models import Clinic, Patient, Appointment
from accounts.serializers import DoctorSerializer


class ClinicSerializer(serializers.ModelSerializer):
    """Serializer for Clinic model."""
    
    class Meta:
        model = Clinic
        fields = ['id', 'name', 'address', 'phone']
        read_only_fields = ['id']


class PatientSerializer(serializers.ModelSerializer):
    """Serializer for Patient model."""
    
    class Meta:
        model = Patient
        fields = ['id', 'name', 'email', 'phone', 'date_of_birth']
        read_only_fields = ['id']


class AppointmentSerializer(serializers.ModelSerializer):
    """
    Serializer for Appointment model with nested patient data.
    """
    
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset=Patient.objects.all(),
        source='patient',
        write_only=True,
    )
    doctor_name = serializers.CharField(source='doctor.user.full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor',
            'doctor_name',
            'patient',
            'patient_id',
            'date',
            'time',
            'status',
            'status_display',
            'video_call_link',
            'notes',
        ]
        read_only_fields = ['id', 'doctor']
    
    def create(self, validated_data):
        # Set the doctor from the request context
        request = self.context.get('request')
        if request and hasattr(request.user, 'doctor_profile'):
            validated_data['doctor'] = request.user.doctor_profile
        return super().create(validated_data)


class AppointmentDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for Appointment with full nested data.
    """
    
    patient = PatientSerializer(read_only=True)
    doctor = DoctorSerializer(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor',
            'patient',
            'date',
            'time',
            'status',
            'status_display',
            'video_call_link',
            'notes',
        ]
        read_only_fields = ['id']
