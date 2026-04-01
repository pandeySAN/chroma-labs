import '../../domain/entities/clinic_entity.dart';

class DoctorInfoModel extends DoctorInfo {
  const DoctorInfoModel({
    required super.id,
    required super.name,
    required super.specialization,
    super.experienceYears,
    super.languages,
    super.consultationFee,
    super.profilePicture,
  });

  factory DoctorInfoModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return DoctorInfoModel(
      id: json['id'] as int,
      name: user['full_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      experienceYears: json['experience_years'] as int? ?? 0,
      languages: json['languages'] as String? ?? 'English',
      consultationFee: _toDouble(json['consultation_fee']),
      profilePicture: user['profile_picture'] as String?,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class ClinicModel extends ClinicEntity {
  const ClinicModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    super.doctors,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    final doctorList = (json['doctors'] as List<dynamic>?)
            ?.map(
              (d) => DoctorInfoModel.fromJson(d as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return ClinicModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      doctors: doctorList,
    );
  }
}
