/// Doctor model representing a doctor profile
class Doctor {
  final int id;
  final String specialization;
  final int? clinicId;
  final String? clinicName;

  Doctor({
    required this.id,
    required this.specialization,
    this.clinicId,
    this.clinicName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      specialization: json['specialization'] as String? ?? 'General Practitioner',
      clinicId: json['clinic'] as int?,
      clinicName: json['clinic_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specialization': specialization,
      'clinic': clinicId,
      'clinic_name': clinicName,
    };
  }

  @override
  String toString() {
    return 'Doctor(id: $id, specialization: $specialization)';
  }
}

/// Clinic model
class Clinic {
  final int id;
  final String name;
  final String address;
  final String? phone;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
    };
  }
}
