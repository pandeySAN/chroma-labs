import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/clinic_entity.dart';
import '../repositories/appointment_repository.dart';

class SearchClinicsUseCase {
  final AppointmentRepository _repository;

  SearchClinicsUseCase(this._repository);

  Future<Either<Failure, List<ClinicEntity>>> call(String query) {
    return _repository.searchClinics(query);
  }
}
