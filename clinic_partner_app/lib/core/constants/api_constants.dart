/// API Constants for the Clinic Partner App
class ApiConstants {
  ApiConstants._();

  // ===========================================
  // Environment Configuration
  // ===========================================
  
  static const bool isProduction = false;
  
  /// For Android emulator use 10.0.2.2, for web/iOS use localhost
  static const String devBaseUrl = 'http://10.0.2.2:8000';
  static const String webDevBaseUrl = 'http://localhost:8000';
  static const String prodBaseUrl = 'https://api.clinicpartner.com';
  
  /// Current base URL based on environment
  static String get baseUrl => isProduction ? prodBaseUrl : webDevBaseUrl;

  // ===========================================
  // Authentication Endpoints
  // ===========================================
  
  /// POST - Signup with email/mobile + password
  static const String authSignup = '/api/auth/signup/';
  
  /// POST - Login with email/mobile + password
  static const String authLogin = '/api/auth/login/';
  
  /// POST - Google OAuth login
  static const String authGoogle = '/api/auth/google/';
  
  /// GET - Get current authenticated user
  static const String authMe = '/api/auth/me/';
  
  /// POST - Refresh JWT access token
  static const String authTokenRefresh = '/api/auth/token/refresh/';
  
  /// POST - Register as a doctor
  static const String registerDoctor = '/api/auth/register-doctor/';
  
  /// GET - List available clinics
  static const String listClinics = '/api/auth/clinics/';

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
}
