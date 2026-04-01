import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/clinic_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../../domain/repositories/appointment_repository.dart';

// ── Dependency wiring ──

final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>(
  (ref) => AppointmentRemoteDataSource(ref.read(dioClientProvider)),
);

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepositoryImpl(
    ref.read(appointmentRemoteDataSourceProvider),
  ),
);

// ── Clinic Search ──

class ClinicSearchState {
  final bool isLoading;
  final List<ClinicEntity> clinics;
  final String? error;

  const ClinicSearchState({
    this.isLoading = false,
    this.clinics = const [],
    this.error,
  });

  ClinicSearchState copyWith({
    bool? isLoading,
    List<ClinicEntity>? clinics,
    String? error,
  }) {
    return ClinicSearchState(
      isLoading: isLoading ?? this.isLoading,
      clinics: clinics ?? this.clinics,
      error: error,
    );
  }
}

class ClinicSearchNotifier extends Notifier<ClinicSearchState> {
  @override
  ClinicSearchState build() => const ClinicSearchState();

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(appointmentRepositoryProvider).searchClinics(query);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (clinics) =>
          state = state.copyWith(isLoading: false, clinics: clinics),
    );
  }
}

final clinicSearchProvider =
    NotifierProvider<ClinicSearchNotifier, ClinicSearchState>(
  ClinicSearchNotifier.new,
);

// ── Slot Picker ──

class SlotState {
  final bool isLoading;
  final List<TimeSlotEntity> slots;
  final String? error;

  const SlotState({
    this.isLoading = false,
    this.slots = const [],
    this.error,
  });

  SlotState copyWith({
    bool? isLoading,
    List<TimeSlotEntity>? slots,
    String? error,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      slots: slots ?? this.slots,
      error: error,
    );
  }
}

class SlotNotifier extends Notifier<SlotState> {
  @override
  SlotState build() => const SlotState();

  Future<void> loadSlots({
    required int doctorId,
    required String date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref
        .read(appointmentRepositoryProvider)
        .getAvailableSlots(doctorId: doctorId, date: date);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (slots) => state = state.copyWith(isLoading: false, slots: slots),
    );
  }
}

final slotProvider = NotifierProvider<SlotNotifier, SlotState>(
  SlotNotifier.new,
);

// ── Appointments (book, list, cancel) ──

class AppointmentState {
  final bool isLoading;
  final List<AppointmentEntity> appointments;
  final String? error;
  final String? successMessage;

  const AppointmentState({
    this.isLoading = false,
    this.appointments = const [],
    this.error,
    this.successMessage,
  });

  AppointmentState copyWith({
    bool? isLoading,
    List<AppointmentEntity>? appointments,
    String? error,
    String? successMessage,
  }) {
    return AppointmentState(
      isLoading: isLoading ?? this.isLoading,
      appointments: appointments ?? this.appointments,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AppointmentNotifier extends Notifier<AppointmentState> {
  @override
  AppointmentState build() => const AppointmentState();

  AppointmentRepository get _repo =>
      ref.read(appointmentRepositoryProvider);

  Future<AppointmentEntity?> bookAppointment({
    required int doctorId,
    required int clinicId,
    required String date,
    required String time,
    String notes = '',
    double consultationFee = 0,
  }) async {
    state = state.copyWith(
        isLoading: true, error: null, successMessage: null);
    final result = await _repo.bookAppointment(
      doctorId: doctorId,
      clinicId: clinicId,
      date: date,
      time: time,
      notes: notes,
      consultationFee: consultationFee,
    );
    return result.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return null;
      },
      (appointment) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Appointment booked successfully!',
        );
        return appointment;
      },
    );
  }

  Future<void> loadMyAppointments({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getMyAppointments(status: status);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (list) =>
          state = state.copyWith(isLoading: false, appointments: list),
    );
  }

  Future<bool> cancelAppointment(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.cancelAppointment(id);
    return result.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (updated) {
        final newList = state.appointments.map((a) {
          if (a.id == id) return updated;
          return a;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          appointments: newList,
          successMessage: 'Appointment cancelled',
        );
        return true;
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final appointmentProvider =
    NotifierProvider<AppointmentNotifier, AppointmentState>(
  AppointmentNotifier.new,
);
