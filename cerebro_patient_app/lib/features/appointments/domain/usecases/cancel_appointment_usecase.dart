import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  final AppointmentRepository _repository;

  CancelAppointmentUseCase(this._repository);

  Future<Either<Failure, AppointmentEntity>> call(int id) {
    return _repository.cancelAppointment(id);
  }
}
