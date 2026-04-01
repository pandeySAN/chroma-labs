import '../../domain/entities/time_slot_entity.dart';

class TimeSlotModel extends TimeSlotEntity {
  const TimeSlotModel({
    required super.time,
    required super.isAvailable,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] as String,
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }
}
