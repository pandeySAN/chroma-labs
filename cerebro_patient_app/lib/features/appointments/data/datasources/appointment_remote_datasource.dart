import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/appointment_model.dart';
import '../models/clinic_model.dart';
import '../models/time_slot_model.dart';

class AppointmentRemoteDataSource {
  final DioClient _client;

  AppointmentRemoteDataSource(this._client);

  Future<List<ClinicModel>> searchClinics(String query) async {
    final response = await _client.get(
      ApiEndpoints.clinicSearch,
      queryParameters: {'q': query},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ClinicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimeSlotModel>> getAvailableSlots({
    required int doctorId,
    required String date,
  }) async {
    final response = await _client.get(
      ApiEndpoints.availableSlots,
      queryParameters: {'doctor_id': doctorId, 'date': date},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentModel> bookAppointment({
    required int doctorId,
    required int clinicId,
    required String date,
    required String time,
    String notes = '',
    double consultationFee = 0,
  }) async {
    final response = await _client.post(
      ApiEndpoints.bookAppointment,
      data: {
        'doctor_id': doctorId,
        'clinic_id': clinicId,
        'date': date,
        'time': time,
        'notes': notes,
        'consultation_fee': consultationFee,
      },
    );
    return AppointmentModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<AppointmentModel>> getMyAppointments({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status;
    final response = await _client.get(
      ApiEndpoints.myAppointments,
      queryParameters: params,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentModel> cancelAppointment(int id) async {
    final response = await _client.patch(
      ApiEndpoints.cancelAppointment(id),
    );
    return AppointmentModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
