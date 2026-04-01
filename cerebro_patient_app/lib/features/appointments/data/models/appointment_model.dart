import '../../domain/entities/appointment_entity.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.doctorName,
    required super.doctorSpecialization,
    required super.clinicName,
    required super.date,
    required super.time,
    required super.status,
    required super.statusDisplay,
    super.notes,
    super.videoCallLink,
    super.consultationFee,
    super.doctorImage,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      doctorName: json['doctor_name'] as String? ?? '',
      doctorSpecialization:
          json['doctor_specialization'] as String? ?? '',
      clinicName: json['clinic_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      statusDisplay: json['status_display'] as String? ?? 'Scheduled',
      notes: json['notes'] as String? ?? '',
      videoCallLink: json['video_call_link'] as String?,
      consultationFee: _toDouble(json['consultation_fee']),
      doctorImage: json['doctor_image'] as String?,
    );
  }
}
