import 'package:flutter/foundation.dart';

/// API Constants for the Clinic Partner App
class ApiConstants {
  ApiConstants._();

  // ===========================================
  // Environment Configuration
  // ===========================================

  /// Change this to false for local development
  static const bool isProduction = true;

  /// Android emulator
  static const String androidDevBaseUrl = 'http://10.0.2.2:8000';

  /// Web / iOS development
  static const String webDevBaseUrl = 'http://localhost:8000';

  /// Production backend
  static const String prodBaseUrl = 'https://api.cere-bro.in';

  /// Dynamic base URL
  static String get baseUrl {
    if (isProduction) {
      return prodBaseUrl;
    }

    if (kIsWeb) {
      return webDevBaseUrl;
    }

    return androidDevBaseUrl;
  }

  // ===========================================
  // Authentication Endpoints
  // ===========================================

  static const String authSignup = '/api/auth/signup/';
  static const String authLogin = '/api/auth/login/';
  static const String authGoogle = '/api/auth/google/';
  static const String authMe = '/api/auth/me/';
  static const String authTokenRefresh = '/api/auth/token/refresh/';
  static const String registerDoctor = '/api/auth/register-doctor/';
  static const String listClinics = '/api/auth/clinics/';
  static const String forgotPassword = '/api/auth/forgot-password/';
  static const String verifyOtp = '/api/auth/verify-otp/';
  static const String resetPassword = '/api/auth/reset-password/';

  // ===========================================
  // Appointment Endpoints
  // ===========================================

  static const String appointments = '/api/appointments/';
  static const String appointmentCreate = '/api/appointments/create/';
  static String appointmentDetail(int id) => '/api/appointments/$id/';

  // ===========================================
  // Patient Endpoints
  // ===========================================

  static const String patients = '/api/appointments/patients/';
  static String patientDetail(int id) => '/api/appointments/patients/$id/';

  // ===========================================
  // Clinic Endpoints
  // ===========================================

  static const String clinics = '/api/appointments/clinics/';
  static String clinicDetail(int id) => '/api/appointments/clinics/$id/';

  // ===========================================
  // Storage Keys
  // ===========================================

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isDoctorKey = 'is_doctor';
  static const String doctorDataKey = 'doctor_data';

  // ===========================================
  // Timeouts
  // ===========================================

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ===========================================
  // Helper
  // ===========================================

  static String endpoint(String path) => '$baseUrl$path';
}