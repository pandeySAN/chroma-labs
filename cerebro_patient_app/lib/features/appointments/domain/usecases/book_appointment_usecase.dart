import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class BookAppointmentUseCase {
  final AppointmentRepository _repository;

  BookAppointmentUseCase(this._repository);

  Future<Either<Failure, AppointmentEntity>> call({
    required int doctorId,
    required int clinicId,
    required String date,
    required String time,
    String notes = '',
  }) {
    return _repository.bookAppointment(
      doctorId: doctorId,
      clinicId: clinicId,
      date: date,
      time: time,
      notes: notes,
    );
  }
}
