/// API Constants for the Clinic Partner App
/// 
/// Configure the baseUrl based on your environment:
/// - Development (Android Emulator): http://10.0.2.2:8000
/// - Development (iOS Simulator): http://localhost:8000
/// - Development (Physical Device): http://<your-ip>:8000
/// - Production: https://api.yourproductiondomain.com
class ApiConstants {
  ApiConstants._();

  // ===========================================
  // Environment Configuration
  // ===========================================
  
  /// Set to true for production, false for development
  static const bool isProduction = false;
  
  /// Development base URL (Android emulator)
  static const String _devBaseUrl = 'http://10.0.2.2:8000';
  
  /// Production base URL (replace with your domain)
  static const String _prodBaseUrl = 'https://api.clinicpartner.com';
  
  /// Current base URL based on environment
  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  // ===========================================
  // Authentication Endpoints
  // ===========================================
  
  /// POST - Google OAuth login
  static const String authGoogle = '/api/auth/google/';
  
  /// GET - Get current authenticated user
  static const String authMe = '/api/auth/me/';
  
  /// POST - Refresh JWT access token
  static const String authTokenRefresh = '/api/auth/token/refresh/';

  // ===========================================
  // Appointment Endpoints
  // ===========================================
  
  /// GET - List appointments for authenticated doctor
  static const String appointments = '/api/appointments/';
  
  /// POST - Create new appointment
  static const String appointmentCreate = '/api/appointments/create/';
  
  /// GET/PATCH/DELETE - Single appointment by ID
  static String appointmentDetail(int id) => '/api/appointments/$id/';

  // ===========================================
  // Patient Endpoints
  // ===========================================
  
  /// GET/POST - List or create patients
  static const String patients = '/api/appointments/patients/';
  
  /// GET/PATCH/DELETE - Single patient by ID
  static String patientDetail(int id) => '/api/appointments/patients/$id/';

  // ===========================================
  // Clinic Endpoints
  // ===========================================
  
  /// GET - List clinics
  static const String clinics = '/api/appointments/clinics/';
  
  /// GET - Single clinic by ID
  static String clinicDetail(int id) => '/api/appointments/clinics/$id/';

  // ===========================================
  // Storage Keys
  // ===========================================
  
  /// Key for storing JWT access token
  static const String accessTokenKey = 'access_token';
  
  /// Key for storing JWT refresh token
  static const String refreshTokenKey = 'refresh_token';
  
  /// Key for storing user data JSON
  static const String userDataKey = 'user_data';

  // ===========================================
  // Timeouts
  // ===========================================
  
  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 30);
  
  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 30);
}
