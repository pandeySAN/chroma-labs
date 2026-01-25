import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_config.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';

/// Service for handling authentication
class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  late final GoogleSignIn _googleSignIn;
  
  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? AppConfig.googleWebClientId : null,
    );
  }

  // =========================================
  // Token Management
  // =========================================

  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiConstants.refreshTokenKey);
  }

  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: ApiConstants.userDataKey, value: jsonEncode(userData));
  }

  Future<void> _storeDoctorData(bool isDoctor, Map<String, dynamic>? doctorData) async {
    await _storage.write(key: ApiConstants.isDoctorKey, value: isDoctor.toString());
    if (doctorData != null) {
      await _storage.write(key: ApiConstants.doctorDataKey, value: jsonEncode(doctorData));
    } else {
      await _storage.delete(key: ApiConstants.doctorDataKey);
    }
  }

  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: ApiConstants.userDataKey);
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> getStoredIsDoctor() async {
    final isDoctor = await _storage.read(key: ApiConstants.isDoctorKey);
    return isDoctor == 'true';
  }

  Future<Doctor?> getStoredDoctor() async {
    final doctorData = await _storage.read(key: ApiConstants.doctorDataKey);
    if (doctorData != null) {
      try {
        return Doctor.fromJson(jsonDecode(doctorData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // =========================================
  // Email/Mobile + Password Authentication
  // =========================================

  /// Sign up with name, email/mobile, and password
  Future<AuthResult> signup({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authSignup}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'identifier': identifier,
          'password': password,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        await _storeTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
        );
        await _storeUserData(data['user']);
        
        final user = User.fromJson(data['user']);
        final bool isDoctor = data['is_doctor'] ?? false;
        final doctorData = data['doctor'];
        
        await _storeDoctorData(isDoctor, doctorData);
        
        Doctor? doctor;
        if (isDoctor && doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }
        
        return AuthResult.success(user: user, isDoctor: isDoctor, doctor: doctor);
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = 'Signup failed';
        
        if (error is Map) {
          if (error.containsKey('identifier')) {
            errorMessage = error['identifier'] is List 
                ? error['identifier'][0] 
                : error['identifier'].toString();
          } else if (error.containsKey('password')) {
            errorMessage = error['password'] is List 
                ? error['password'][0] 
                : error['password'].toString();
          } else if (error.containsKey('name')) {
            errorMessage = error['name'] is List 
                ? error['name'][0] 
                : error['name'].toString();
          } else if (error.containsKey('error')) {
            errorMessage = error['error'];
          } else if (error.containsKey('detail')) {
            errorMessage = error['detail'];
          }
        }
        
        return AuthResult.failure(errorMessage);
      }
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  /// Login with email/mobile and password
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogin}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        await _storeTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
        );
        await _storeUserData(data['user']);
        
        final user = User.fromJson(data['user']);
        final bool isDoctor = data['is_doctor'] ?? false;
        final doctorData = data['doctor'];
        
        await _storeDoctorData(isDoctor, doctorData);
        
        Doctor? doctor;
        if (isDoctor && doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }
        
        return AuthResult.success(user: user, isDoctor: isDoctor, doctor: doctor);
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = 'Login failed';
        
        if (error is Map) {
          if (error.containsKey('identifier')) {
            errorMessage = error['identifier'] is List 
                ? error['identifier'][0] 
                : error['identifier'].toString();
          } else if (error.containsKey('password')) {
            errorMessage = error['password'] is List 
                ? error['password'][0] 
                : error['password'].toString();
          } else if (error.containsKey('non_field_errors')) {
            errorMessage = error['non_field_errors'] is List 
                ? error['non_field_errors'][0] 
                : error['non_field_errors'].toString();
          } else if (error.containsKey('error')) {
            errorMessage = error['error'];
          } else if (error.containsKey('detail')) {
            errorMessage = error['detail'];
          }
        }
        
        return AuthResult.failure(errorMessage);
      }
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  // =========================================
  // Google OAuth
  // =========================================

  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authGoogle}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': idToken}),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        await _storeTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
        );
        await _storeUserData(data['user']);
        
        final user = User.fromJson(data['user']);
        final bool isDoctor = data['is_doctor'] ?? false;
        final doctorData = data['doctor'];
        
        await _storeDoctorData(isDoctor, doctorData);
        
        Doctor? doctor;
        if (isDoctor && doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }
        
        return AuthResult.success(user: user, isDoctor: isDoctor, doctor: doctor);
      } else {
        try {
          final error = jsonDecode(response.body);
          return AuthResult.failure(error['error'] ?? 'Authentication failed');
        } catch (e) {
          return AuthResult.failure('Authentication failed (${response.statusCode})');
        }
      }
    } catch (e) {
      return AuthResult.failure('Sign in failed: ${e.toString()}');
    }
  }

  // =========================================
  // Doctor Registration
  // =========================================

  /// Register current user as a doctor
  Future<AuthResult> registerAsDoctor({
    required String specialization,
    int? clinicId,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return AuthResult.failure('Not authenticated');
      }

      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerDoctor}');
      
      final Map<String, dynamic> body = {
        'specialization': specialization,
      };
      if (clinicId != null) {
        body['clinic_id'] = clinicId;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        final doctorData = data['doctor'];
        final bool isDoctor = data['is_doctor'] ?? true;
        
        await _storeDoctorData(isDoctor, doctorData);
        
        Doctor? doctor;
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }
        
        // Re-fetch user to get updated data
        final storedUser = await getStoredUser();
        
        return AuthResult.success(
          user: storedUser!,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(error['error'] ?? 'Failed to register as doctor');
      }
    } catch (e) {
      return AuthResult.failure('Error: ${e.toString()}');
    }
  }

  /// Get list of available clinics
  Future<List<Clinic>> getClinics() async {
    try {
      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.listClinics}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Clinic.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // =========================================
  // Other Methods
  // =========================================

  Future<AuthResult> getCurrentUser() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return AuthResult.failure('Not authenticated');
      }

      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authMe}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final bool isDoctor = data['is_doctor'] ?? false;
        final doctorData = data['doctor'];
        
        await _storeUserData(data['user']);
        await _storeDoctorData(isDoctor, doctorData);
        
        Doctor? doctor;
        if (isDoctor && doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }
        
        return AuthResult.success(user: user, isDoctor: isDoctor, doctor: doctor);
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return getCurrentUser();
        }
        return AuthResult.failure('Session expired. Please sign in again.');
      } else {
        return AuthResult.failure('Failed to get user info');
      }
    } catch (e) {
      return AuthResult.failure('Error: ${e.toString()}');
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) return false;

      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authTokenRefresh}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshTokenValue}),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        await _storage.write(key: ApiConstants.accessTokenKey, value: data['access']);
        if (data['refresh'] != null) {
          await _storage.write(key: ApiConstants.refreshTokenKey, value: data['refresh']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore
    }
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: ApiConstants.userDataKey);
    await _storage.delete(key: ApiConstants.isDoctorKey);
    await _storage.delete(key: ApiConstants.doctorDataKey);
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final bool isDoctor;
  final Doctor? doctor;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.isDoctor = false,
    this.doctor,
    this.error,
  });

  factory AuthResult.success({
    required User user,
    required bool isDoctor,
    Doctor? doctor,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      isDoctor: isDoctor,
      doctor: doctor,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}
