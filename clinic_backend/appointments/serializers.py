from rest_framework import serializers
from .models import Clinic, Patient, Appointment
from accounts.serializers import DoctorSerializer, UserSerializer


class ClinicSerializer(serializers.ModelSerializer):
    class Meta:
        model = Clinic
        fields = ['id', 'name', 'address', 'phone']
        read_only_fields = ['id']


class ClinicSearchSerializer(serializers.ModelSerializer):
    """Includes the list of doctors working at the clinic."""

    doctors = DoctorSerializer(many=True, read_only=True)

    class Meta:
        model = Clinic
        fields = ['id', 'name', 'address', 'phone', 'doctors']
        read_only_fields = ['id']


class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = ['id', 'name', 'email', 'phone', 'date_of_birth']
        read_only_fields = ['id']


class AppointmentSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    patient_id = serializers.PrimaryKeyRelatedField(
        queryset=Patient.objects.all(),
        source='patient',
        write_only=True,
    )
    doctor_name = serializers.CharField(
        source='doctor.user.full_name', read_only=True
    )
    status_display = serializers.CharField(
        source='get_status_display', read_only=True
    )

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
        request = self.context.get('request')
        if request and hasattr(request.user, 'doctor_profile'):
            validated_data['doctor'] = request.user.doctor_profile
        return super().create(validated_data)


class AppointmentDetailSerializer(serializers.ModelSerializer):
    patient = PatientSerializer(read_only=True)
    doctor = DoctorSerializer(read_only=True)
    clinic = ClinicSerializer(read_only=True)
    status_display = serializers.CharField(
        source='get_status_display', read_only=True
    )

    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor',
            'patient',
            'clinic',
            'date',
            'time',
            'status',
            'status_display',
            'video_call_link',
            'notes',
        ]
        read_only_fields = ['id']


class BookAppointmentSerializer(serializers.Serializer):
    """Used by patients to book an appointment."""

    doctor_id = serializers.IntegerField()
    clinic_id = serializers.IntegerField()
    date = serializers.DateField()
    time = serializers.TimeField()
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    consultation_fee = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False, default=0,
    )


class PatientAppointmentSerializer(serializers.ModelSerializer):
    """Read-only serializer for a patient viewing their appointments."""

    doctor_name = serializers.CharField(
        source='doctor.user.full_name', read_only=True
    )
    doctor_specialization = serializers.CharField(
        source='doctor.specialization', read_only=True
    )
    clinic_name = serializers.CharField(
        source='clinic.name', read_only=True, default=''
    )
    status_display = serializers.CharField(
        source='get_status_display', read_only=True
    )

    class Meta:
        model = Appointment
        fields = [
            'id',
            'doctor_name',
            'doctor_specialization',
            'clinic_name',
            'date',
            'time',
            'status',
            'status_display',
            'notes',
            'video_call_link',
            'consultation_fee',
        ]
        read_only_fields = fields
