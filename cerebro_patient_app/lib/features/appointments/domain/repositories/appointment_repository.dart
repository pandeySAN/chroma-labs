import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/appointment_entity.dart';
import '../entities/clinic_entity.dart';
import '../entities/time_slot_entity.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, List<ClinicEntity>>> searchClinics(String query);

  Future<Either<Failure, List<TimeSlotEntity>>> getAvailableSlots({
    required int doctorId,
    required String date,
  });

  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required int doctorId,
    required int clinicId,
    required String date,
    required String time,
    String notes,
    double consultationFee,
  });

  Future<Either<Failure, List<AppointmentEntity>>> getMyAppointments({
    String? status,
  });

  Future<Either<Failure, AppointmentEntity>> cancelAppointment(int id);
}
