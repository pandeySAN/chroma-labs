import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const bool isProduction = kReleaseMode;

  static const String androidDevBaseUrl = 'http://10.0.2.2:8000';
  static const String webDevBaseUrl = 'http://localhost:8000';
  static const String prodBaseUrl = 'https://cere-bro.in';

  static String get baseUrl {
    if (isProduction) return prodBaseUrl;
    if (kIsWeb) return webDevBaseUrl;
    return androidDevBaseUrl;
  }

  // Auth
  static const String login = '/api/auth/login/';
  static const String signup = '/api/auth/signup/';
  static const String googleAuth = '/api/auth/google/';
  static const String tokenRefresh = '/api/auth/token/refresh/';
  static const String me = '/api/auth/me/';
  static const String forgotPassword = '/api/auth/forgot-password/';
  static const String verifyOtp = '/api/auth/verify-otp/';
  static const String resetPassword = '/api/auth/reset-password/';

  // Clinics
  static const String clinicSearch = '/api/clinics/search/';

  // Appointments
  static const String availableSlots = '/api/appointments/slots/';
  static const String bookAppointment = '/api/appointments/book/';
  static const String myAppointments = '/api/appointments/my/';
  static String cancelAppointment(int id) => '/api/appointments/$id/cancel/';

  // Payments  ← NEW
  static const String createPaymentOrder = '/api/payments/create-order/';
  static const String verifyPayment = '/api/payments/verify/';
  static const String paymentHistory = '/api/payments/history/';
}
