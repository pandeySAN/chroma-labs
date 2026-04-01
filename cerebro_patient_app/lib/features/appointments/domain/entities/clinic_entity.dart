class DoctorInfo {
  final int id;
  final String name;
  final String specialization;
  final int experienceYears;
  final String languages;
  final double consultationFee;
  final String? profilePicture;

  const DoctorInfo({
    required this.id,
    required this.name,
    required this.specialization,
    this.experienceYears = 0,
    this.languages = 'English',
    this.consultationFee = 0,
    this.profilePicture,
  });
}

class ClinicEntity {
  final int id;
  final String name;
  final String address;
  final String phone;
  final List<DoctorInfo> doctors;

  const ClinicEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.doctors = const [],
  });
}
