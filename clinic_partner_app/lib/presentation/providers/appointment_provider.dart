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
  bool _isDemoMode = false;

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
    _isDemoMode = false;
    notifyListeners();
  }

  // =========================================
  // Demo Mode - Sample Appointments
  // =========================================

  /// Check if demo mode is active
  bool get isDemoMode => _isDemoMode;

  /// Load demo appointments for demonstration purposes
  /// This shows sample data without needing a backend connection
  void loadDemoAppointments() {
    _isDemoMode = true;
    _isLoading = false;
    _errorMessage = null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));
    final nextWeek = today.add(const Duration(days: 5));

    _appointments = [
      // Today's appointments
      Appointment(
        id: 1,
        patientName: 'Rahul Sharma',
        patientEmail: 'rahul.sharma@email.com',
        date: today,
        time: '09:00:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/abc-defg-hij',
        notes: 'First consultation for anxiety and stress management. Patient reports difficulty sleeping.',
      ),
      Appointment(
        id: 2,
        patientName: 'Priya Patel',
        patientEmail: 'priya.patel@email.com',
        date: today,
        time: '10:30:00',
        status: 'in_progress',
        videoCallLink: 'https://meet.google.com/xyz-uvwx-yz',
        notes: 'Follow-up session for cognitive behavioral therapy.',
      ),
      Appointment(
        id: 3,
        patientName: 'Amit Kumar',
        patientEmail: 'amit.kumar@email.com',
        date: today,
        time: '14:00:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/mno-pqrs-tuv',
        notes: null,
      ),
      Appointment(
        id: 4,
        patientName: 'Sneha Reddy',
        patientEmail: 'sneha.reddy@email.com',
        date: today,
        time: '16:30:00',
        status: 'scheduled',
        videoCallLink: null,
        notes: 'New patient - Depression screening and initial assessment.',
      ),

      // Tomorrow's appointments
      Appointment(
        id: 5,
        patientName: 'Vikram Singh',
        patientEmail: 'vikram.singh@email.com',
        date: tomorrow,
        time: '09:30:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/def-ghij-klm',
        notes: 'Regular monthly check-in for medication management.',
      ),
      Appointment(
        id: 6,
        patientName: 'Ananya Gupta',
        patientEmail: 'ananya.gupta@email.com',
        date: tomorrow,
        time: '11:00:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/nop-qrst-uvw',
        notes: 'Couples therapy session - third session.',
      ),
      Appointment(
        id: 7,
        patientName: 'Deepak Verma',
        patientEmail: 'deepak.verma@email.com',
        date: tomorrow,
        time: '15:00:00',
        status: 'scheduled',
        videoCallLink: null,
        notes: 'Work-related stress and burnout consultation.',
      ),

      // Day after tomorrow
      Appointment(
        id: 8,
        patientName: 'Kavitha Nair',
        patientEmail: 'kavitha.nair@email.com',
        date: dayAfter,
        time: '10:00:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/abc-mnop-qrs',
        notes: 'Child psychology consultation - behavioral issues.',
      ),
      Appointment(
        id: 9,
        patientName: 'Rajesh Menon',
        patientEmail: 'rajesh.menon@email.com',
        date: dayAfter,
        time: '14:30:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/tuv-wxyz-abc',
        notes: null,
      ),

      // Next week
      Appointment(
        id: 10,
        patientName: 'Meera Joshi',
        patientEmail: 'meera.joshi@email.com',
        date: nextWeek,
        time: '11:30:00',
        status: 'scheduled',
        videoCallLink: 'https://meet.google.com/jkl-mnop-qrs',
        notes: 'PTSD follow-up session - trauma processing.',
      ),
    ];

    // Sort by date and time
    _appointments.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.time.compareTo(b.time);
    });

    notifyListeners();
  }

  /// Toggle demo mode
  void toggleDemoMode() {
    if (_isDemoMode) {
      // Exit demo mode
      _isDemoMode = false;
      _appointments = [];
      fetchAppointments();
    } else {
      // Enter demo mode
      loadDemoAppointments();
    }
  }
}
