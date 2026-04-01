class AppointmentEntity {
  final int id;
  final String doctorName;
  final String doctorSpecialization;
  final String clinicName;
  final String date;
  final String time;
  final String status;
  final String statusDisplay;
  final String notes;
  final String? videoCallLink;
  final double consultationFee;   // ← added
  final String? doctorImage;      // ← added (URL or null)

  const AppointmentEntity({
    required this.id,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.clinicName,
    required this.date,
    required this.time,
    required this.status,
    required this.statusDisplay,
    this.notes = '',
    this.videoCallLink,
    this.consultationFee = 0.0,
    this.doctorImage,
  });
}
