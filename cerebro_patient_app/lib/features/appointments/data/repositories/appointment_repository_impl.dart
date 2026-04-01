import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/clinic_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource _remote;

  AppointmentRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<ClinicEntity>>> searchClinics(
      String query) async {
    try {
      final clinics = await _remote.searchClinics(query);
      return Right(clinics);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimeSlotEntity>>> getAvailableSlots({
    required int doctorId,
    required String date,
  }) async {
    try {
      final slots = await _remote.getAvailableSlots(
          doctorId: doctorId, date: date);
      return Right(slots);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required int doctorId,
    required int clinicId,
    required String date,
    required String time,
    String notes = '',
    double consultationFee = 0,
  }) async {
    try {
      final appointment = await _remote.bookAppointment(
        doctorId: doctorId,
        clinicId: clinicId,
        date: date,
        time: time,
        notes: notes,
        consultationFee: consultationFee,
      );
      return Right(appointment);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getMyAppointments({
    String? status,
  }) async {
    try {
      final appointments =
          await _remote.getMyAppointments(status: status);
      return Right(appointments);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(
      int id) async {
    try {
      final appointment = await _remote.cancelAppointment(id);
      return Right(appointment);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
