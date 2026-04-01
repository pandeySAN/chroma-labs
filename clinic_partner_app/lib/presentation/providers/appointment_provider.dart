import 'package:flutter/foundation.dart';
import '../../data/models/appointment_model.dart';
import '../../data/services/appointment_service.dart';

/// Provider for managing appointment state
class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  // =========================================
  // State Properties
  // =========================================

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusFilter;
  String? _dateFilter;

  // =========================================
  // Getters
  // =========================================

  /// List of all appointments
  List<Appointment> get appointments => _appointments;

  /// Whether an async operation is in progress
  bool get isLoading => _isLoading;

  /// Error message from last operation
  String? get errorMessage => _errorMessage;

  /// Current status filter
  String? get statusFilter => _statusFilter;

  /// Current date filter
  String? get dateFilter => _dateFilter;

  /// Whether there are any appointments
  bool get hasAppointments => _appointments.isNotEmpty;

  /// Total count of appointments
  int get appointmentCount => _appointments.length;

  /// Count of scheduled appointments
  int get scheduledCount => 
      _appointments.where((a) => a.status == 'scheduled').length;

  /// Count of in-progress appointments
  int get inProgressCount => 
      _appointments.where((a) => a.status == 'in_progress').length;

  /// Count of completed appointments
  int get completedCount => 
      _appointments.where((a) => a.status == 'completed').length;

  /// Get today's appointments
  List<Appointment> get todayAppointments =>
      _appointments.where((a) => a.isToday).toList();

  /// Get upcoming appointments (future dates)
  List<Appointment> get upcomingAppointments =>
      _appointments.where((a) => a.isFuture).toList();

  /// Get past appointments
  List<Appointment> get pastAppointments =>
      _appointments.where((a) => a.isPast).toList();

  // =========================================
  // Private Methods
  // =========================================

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================
  // Public Methods
  // =========================================

  /// Fetch appointments from the API
  /// 
  /// Parameters:
  /// - [status]: Filter by status ('scheduled', 'in_progress', 'completed')
  /// - [date]: Filter by date (format: 'YYYY-MM-DD')
  /// - [showLoading]: Whether to show loading indicator (default: true)
  Future<void> fetchAppointments({
    String? status,
    String? date,
    bool showLoading = true,
  }) async {
    if (_isLoading && showLoading) return;

    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;
    _statusFilter = status;
    _dateFilter = date;

    try {
      final result = await _appointmentService.getAppointments(
        status: status,
        date: date,
      );

      if (result.success && result.data != null) {
        _appointments = result.data!;
        _errorMessage = null;
      } else {
        _errorMessage = result.error ?? 'Failed to load appointments';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh appointments (silent, no loading indicator)
  Future<void> refreshAppointments() async {
    await fetchAppointments(
      status: _statusFilter,
      date: _dateFilter,
      showLoading: false,
    );
  }

  /// Set status filter and fetch appointments
  void setStatusFilter(String? status) {
    _statusFilter = status;
    fetchAppointments(status: status, date: _dateFilter);
  }

  /// Set date filter and fetch appointments
  void setDateFilter(String? date) {
    _dateFilter = date;
    fetchAppointments(status: _statusFilter, date: date);
  }

  /// Clear all filters and fetch appointments
  void clearFilters() {
    _statusFilter = null;
    _dateFilter = null;
    fetchAppointments();
  }

  /// Update appointment status
  /// Returns true if update was successful
  Future<bool> updateAppointmentStatus(int id, String status) async {
    try {
      final result = await _appointmentService.updateStatus(id, status);

      if (result.success && result.data != null) {
        // Update local list
        final index = _appointments.indexWhere((a) => a.id == id);
        if (index != -1) {
          _appointments[index] = result.data!;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result.error ?? 'Failed to update status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Start an appointment (change status to 'in_progress')
  Future<bool> startAppointment(int id) async {
    return updateAppointmentStatus(id, 'in_progress');
  }

  /// Complete an appointment (change status to 'completed')
  Future<bool> completeAppointment(int id) async {
    return updateAppointmentStatus(id, 'completed');
  }

  /// Update appointment notes
  /// Returns true if update was successful
  Future<bool> updateAppointmentNotes(int id, String notes) async {
    try {
      final result = await _appointmentService.updateNotes(id, notes);

      if (result.success && result.data != null) {
        final index = _appointments.indexWhere((a) => a.id == id);
        if (index != -1) {
          _appointments[index] = result.data!;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result.error ?? 'Failed to update notes';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Save a video call link (e.g. Google Meet) to the appointment
  Future<bool> setVideoCallLink(int id, String link) async {
    try {
      final result = await _appointmentService.updateVideoCallLink(id, link);

      if (result.success && result.data != null) {
        final index = _appointments.indexWhere((a) => a.id == id);
        if (index != -1) {
          _appointments[index] = result.data!;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result.error ?? 'Failed to save video link';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get appointment by ID from local list
  Appointment? getAppointmentById(int id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get appointments filtered by status from local list
  List<Appointment> getAppointmentsByStatus(String status) {
    return _appointments.where((a) => a.status == status).toList();
  }

  /// Clear all data (call on logout)
  void clear() {
    _appointments = [];
    _isLoading = false;
    _errorMessage = null;
    _statusFilter = null;
    _dateFilter = null;
    notifyListeners();
  }
}
