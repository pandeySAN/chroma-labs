import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../models/appointment_model.dart';
import 'auth_service.dart';

/// Service for handling appointment-related API calls
class AppointmentService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  // =========================================
  // Helper Methods
  // =========================================

  /// Get authorization headers with bearer token
  Future<Map<String, String>> _getAuthHeaders() async {
    final accessToken = await _storage.read(key: ApiConstants.accessTokenKey);
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  /// Handle 401 response by refreshing token and retrying
  Future<http.Response?> _handleUnauthorized(
    Future<http.Response> Function() retryRequest,
  ) async {
    final refreshed = await _authService.refreshToken();
    if (refreshed) {
      return await retryRequest();
    }
    return null;
  }

  // =========================================
  // Appointment Methods
  // =========================================

  /// Get all appointments for the authenticated doctor
  /// GET /api/appointments/
  /// 
  /// Optional parameters:
  /// - [status]: Filter by status ('scheduled', 'in_progress', 'completed')
  /// - [date]: Filter by date (format: 'YYYY-MM-DD')
  Future<ServiceResult<List<Appointment>>> getAppointments({
    String? status,
    String? date,
  }) async {
    try {
      // Build URL with query parameters
      String endpoint = ApiConstants.appointments;
      final queryParams = <String>[];
      
      if (status != null && status.isNotEmpty) {
        queryParams.add('status=$status');
      }
      if (date != null && date.isNotEmpty) {
        queryParams.add('date=$date');
      }
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final Uri url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getAuthHeaders();

      // Make request
      var response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConstants.connectionTimeout);

      // Handle 401 - try to refresh token and retry
      if (response.statusCode == 401) {
        final retryResponse = await _handleUnauthorized(() async {
          final newHeaders = await _getAuthHeaders();
          return await http.get(url, headers: newHeaders);
        });
        
        if (retryResponse != null) {
          response = retryResponse;
        } else {
          return ServiceResult.failure('Session expired. Please sign in again.');
        }
      }

      // Parse response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        final List<Appointment> appointments = jsonList
            .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by date and time
        appointments.sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.time.compareTo(b.time);
        });
        
        return ServiceResult.success(appointments);
      } else {
        // Parse error message
        try {
          final error = jsonDecode(response.body);
          return ServiceResult.failure(
            error['error'] ?? 'Failed to load appointments',
          );
        } catch (e) {
          return ServiceResult.failure(
            'Failed to load appointments (${response.statusCode})',
          );
        }
      }
    } on http.ClientException catch (e) {
      return ServiceResult.failure('Network error: ${e.message}');
    } catch (e) {
      return ServiceResult.failure('Error: ${e.toString()}');
    }
  }

  /// Get a single appointment by ID
  /// GET /api/appointments/{id}/
  Future<ServiceResult<Appointment>> getAppointment(int id) async {
    try {
      final Uri url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.appointmentDetail(id)}',
      );
      final headers = await _getAuthHeaders();

      var response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConstants.connectionTimeout);

      // Handle 401
      if (response.statusCode == 401) {
        final retryResponse = await _handleUnauthorized(() async {
          final newHeaders = await _getAuthHeaders();
          return await http.get(url, headers: newHeaders);
        });
        
        if (retryResponse != null) {
          response = retryResponse;
        } else {
          return ServiceResult.failure('Session expired. Please sign in again.');
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return ServiceResult.success(Appointment.fromJson(json));
      } else if (response.statusCode == 404) {
        return ServiceResult.failure('Appointment not found');
      } else {
        return ServiceResult.failure('Failed to load appointment');
      }
    } catch (e) {
      return ServiceResult.failure('Error: ${e.toString()}');
    }
  }

  /// Update appointment status
  /// PATCH /api/appointments/{id}/
  Future<ServiceResult<Appointment>> updateStatus(
    int id,
    String status,
  ) async {
    return _updateAppointment(id, {'status': status});
  }

  /// Update appointment notes
  /// PATCH /api/appointments/{id}/
  Future<ServiceResult<Appointment>> updateNotes(
    int id,
    String notes,
  ) async {
    return _updateAppointment(id, {'notes': notes});
  }

  /// Update appointment video call link
  /// PATCH /api/appointments/{id}/
  Future<ServiceResult<Appointment>> updateVideoCallLink(
    int id,
    String videoCallLink,
  ) async {
    return _updateAppointment(id, {'video_call_link': videoCallLink});
  }

  /// Generic update appointment method
  /// PATCH /api/appointments/{id}/
  Future<ServiceResult<Appointment>> _updateAppointment(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final Uri url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.appointmentDetail(id)}',
      );
      final headers = await _getAuthHeaders();

      var response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(ApiConstants.connectionTimeout);

      // Handle 401
      if (response.statusCode == 401) {
        final retryResponse = await _handleUnauthorized(() async {
          final newHeaders = await _getAuthHeaders();
          return await http.patch(
            url,
            headers: newHeaders,
            body: jsonEncode(data),
          );
        });
        
        if (retryResponse != null) {
          response = retryResponse;
        } else {
          return ServiceResult.failure('Session expired. Please sign in again.');
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return ServiceResult.success(Appointment.fromJson(json));
      } else if (response.statusCode == 404) {
        return ServiceResult.failure('Appointment not found');
      } else {
        try {
          final error = jsonDecode(response.body);
          return ServiceResult.failure(
            error['error'] ?? 'Failed to update appointment',
          );
        } catch (e) {
          return ServiceResult.failure('Failed to update appointment');
        }
      }
    } catch (e) {
      return ServiceResult.failure('Error: ${e.toString()}');
    }
  }
}

/// Generic result wrapper for service operations
class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ServiceResult._({
    required this.success,
    this.data,
    this.error,
  });

  /// Create a successful result with data
  factory ServiceResult.success(T data) {
    return ServiceResult._(
      success: true,
      data: data,
    );
  }

  /// Create a failure result with error message
  factory ServiceResult.failure(String error) {
    return ServiceResult._(
      success: false,
      error: error,
    );
  }

  /// Check if result has data
  bool get hasData => data != null;

  @override
  String toString() {
    if (success) {
      return 'ServiceResult.success(data: $data)';
    }
    return 'ServiceResult.failure(error: $error)';
  }
}
