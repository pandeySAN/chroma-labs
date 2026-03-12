import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_config.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: kIsWeb ? AppConfig.googleWebClientId : null,
      serverClientId: AppConfig.googleWebClientId,
    );
  }

  // ============================
  // Safe JSON helpers
  // ============================

  Map<String, dynamic>? _safeJsonDecode(String body) {
    try {
      final trimmed = body.trim();

      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('<')) return null;

      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'];
    final body = response.body.trim();

    if (contentType != null && contentType.contains('application/json')) {
      return true;
    }

    if (body.isEmpty) return true;

    return body.startsWith('{') || body.startsWith('[');
  }

  // ============================
  // Token Storage
  // ============================

  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: ApiConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: ApiConstants.refreshTokenKey);
  }

  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(
      key: ApiConstants.userDataKey,
      value: jsonEncode(userData),
    );
  }

  Future<void> _storeDoctorData(bool isDoctor, Map<String, dynamic>? doctor) async {
    await _storage.write(
      key: ApiConstants.isDoctorKey,
      value: isDoctor.toString(),
    );

    if (doctor != null) {
      await _storage.write(
        key: ApiConstants.doctorDataKey,
        value: jsonEncode(doctor),
      );
    } else {
      await _storage.delete(key: ApiConstants.doctorDataKey);
    }
  }

  // ============================
  // Local stored user
  // ============================

  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: ApiConstants.userDataKey);

    if (userData == null) return null;

    try {
      return User.fromJson(jsonDecode(userData));
    } catch (_) {
      return null;
    }
  }

  Future<bool> getStoredIsDoctor() async {
    final value = await _storage.read(key: ApiConstants.isDoctorKey);
    return value == 'true';
  }

  Future<Doctor?> getStoredDoctor() async {
    final doctorData = await _storage.read(key: ApiConstants.doctorDataKey);

    if (doctorData == null) return null;

    try {
      return Doctor.fromJson(jsonDecode(doctorData));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ============================
  // SIGNUP
  // ============================

  Future<AuthResult> signup({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.authSignup));

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

      if (!_isJsonResponse(response)) {
        return AuthResult.failure('Server returned invalid response');
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 201 && data != null) {
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
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }

        return AuthResult.success(
          user: user,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      }

      return AuthResult.failure(data?['detail'] ?? 'Signup failed');
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  // ============================
  // LOGIN
  // ============================

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.authLogin));

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

      if (!_isJsonResponse(response)) {
        return AuthResult.failure('Server returned invalid response');
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
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
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }

        return AuthResult.success(
          user: user,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      }

      return AuthResult.failure(data?['detail'] ?? 'Login failed');
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  // ============================
  // CURRENT USER
  // ============================

  Future<AuthResult> getCurrentUser() async {
    try {
      final token = await getAccessToken();

      if (token == null) {
        return AuthResult.failure('Not authenticated');
      }

      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.authMe));

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return AuthResult.failure('Server error');
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        final user = User.fromJson(data['user']);

        await _storeUserData(data['user']);

        final bool isDoctor = data['is_doctor'] ?? false;
        final doctorData = data['doctor'];

        await _storeDoctorData(isDoctor, doctorData);

        Doctor? doctor;
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }

        return AuthResult.success(
          user: user,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      }

      return AuthResult.failure('Failed to fetch user');
    } catch (e) {
      return AuthResult.failure('Error: $e');
    }
  }

  // ============================
  // GOOGLE SIGN IN
  // ============================

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        return AuthResult.failure('Failed to get Google token');
      }

      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.authGoogle));

      final body = <String, dynamic>{};
      if (idToken != null) {
        body['token'] = idToken;
        body['token_type'] = 'id_token';
      } else {
        body['token'] = accessToken;
        body['token_type'] = 'access_token';
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return AuthResult.failure('Server error');
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
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
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }

        return AuthResult.success(
          user: user,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      }

      return AuthResult.failure(data?['error'] ?? 'Google sign in failed');
    } catch (e) {
      return AuthResult.failure('Sign in error: $e');
    }
  }

  // ============================
  // REGISTER AS DOCTOR
  // ============================

  Future<AuthResult> registerAsDoctor({
    required String specialization,
    int? clinicId,
  }) async {
    try {
      final token = await getAccessToken();

      if (token == null) {
        return AuthResult.failure('Not authenticated');
      }

      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.registerDoctor));

      final body = <String, dynamic>{
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
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return AuthResult.failure('Server error');
      }

      final data = _safeJsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        final bool isDoctor = data['is_doctor'] ?? true;
        final doctorData = data['doctor'];

        await _storeDoctorData(isDoctor, doctorData);

        final storedUser = await getStoredUser();

        Doctor? doctor;
        if (doctorData != null) {
          doctor = Doctor.fromJson(doctorData);
        }

        return AuthResult.success(
          user: storedUser!,
          isDoctor: isDoctor,
          doctor: doctor,
        );
      }

      return AuthResult.failure(data?['error'] ?? 'Registration failed');
    } catch (e) {
      return AuthResult.failure('Error: $e');
    }
  }

  // ============================
  // GET CLINICS
  // ============================

  Future<List<Clinic>> getClinics() async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.listClinics));

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200 && _isJsonResponse(response)) {
        final body = response.body.trim();
        if (body.startsWith('[')) {
          final List<dynamic> data = jsonDecode(body);
          return data.map((json) => Clinic.fromJson(json)).toList();
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // ============================
  // REFRESH TOKEN
  // ============================

  Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();

      if (refreshTokenValue == null) return false;

      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.authTokenRefresh));

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshTokenValue}),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200 && _isJsonResponse(response)) {
        final data = _safeJsonDecode(response.body);

        if (data != null && data['access'] != null) {
          await _storage.write(
            key: ApiConstants.accessTokenKey,
            value: data['access'],
          );

          if (data['refresh'] != null) {
            await _storage.write(
              key: ApiConstants.refreshTokenKey,
              value: data['refresh'],
            );
          }

          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================
  // FORGOT PASSWORD
  // ============================

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.forgotPassword));

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'identifier': identifier}),
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent',
          'email': data['email'] ?? '',
        };
      }

      final errorMsg = _extractError(data);
      return {'success': false, 'error': errorMsg ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================
  // VERIFY OTP
  // ============================

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.verifyOtp));

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'identifier': identifier, 'otp': otp}),
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message'] ?? 'OTP verified'};
      }

      final errorMsg = _extractError(data);
      return {'success': false, 'error': errorMsg ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============================
  // RESET PASSWORD
  // ============================

  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.endpoint(ApiConstants.resetPassword));

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identifier': identifier,
          'otp': otp,
          'new_password': newPassword,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      if (!_isJsonResponse(response)) {
        return {'success': false, 'error': 'Server error. Please try again.'};
      }

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message'] ?? 'Password reset'};
      }

      final errorMsg = _extractError(data);
      return {'success': false, 'error': errorMsg ?? 'Failed to reset password'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  String? _extractError(Map<String, dynamic>? data) {
    if (data == null) return null;

    if (data.containsKey('detail')) return data['detail'].toString();

    for (final key in ['identifier', 'otp', 'new_password', 'error', 'non_field_errors']) {
      if (data.containsKey(key)) {
        final val = data[key];
        if (val is List && val.isNotEmpty) return val.first.toString();
        if (val is String) return val;
      }
    }

    return null;
  }

  // ============================
  // LOGOUT
  // ============================

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: ApiConstants.userDataKey);
    await _storage.delete(key: ApiConstants.isDoctorKey);
    await _storage.delete(key: ApiConstants.doctorDataKey);
  }
}

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
    return AuthResult._(
      success: false,
      error: error,
    );
  }
}