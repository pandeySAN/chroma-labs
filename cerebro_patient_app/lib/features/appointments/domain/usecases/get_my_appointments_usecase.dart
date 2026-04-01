import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class GetMyAppointmentsUseCase {
  final AppointmentRepository _repository;

  GetMyAppointmentsUseCase(this._repository);

  Future<Either<Failure, List<AppointmentEntity>>> call({String? status}) {
    return _repository.getMyAppointments(status: status);
  }
}
