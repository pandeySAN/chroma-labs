import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/time_slot_entity.dart';
import '../repositories/appointment_repository.dart';

class GetAvailableSlotsUseCase {
  final AppointmentRepository _repository;

  GetAvailableSlotsUseCase(this._repository);

  Future<Either<Failure, List<TimeSlotEntity>>> call({
    required int doctorId,
    required String date,
  }) {
    return _repository.getAvailableSlots(doctorId: doctorId, date: date);
  }
}
