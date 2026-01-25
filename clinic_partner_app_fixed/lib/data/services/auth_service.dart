import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Service for handling authentication with Google OAuth and JWT tokens
class AuthService {
  // Secure storage for tokens
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // =========================================
  // Token Management
  // =========================================

  /// Store access and refresh tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: ApiConstants.accessTokenKey,
      value: accessToken,
    );
    await _storage.write(
      key: ApiConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConstants.accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiConstants.refreshTokenKey);
  }

  /// Store user data locally
  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(
      key: ApiConstants.userDataKey,
      value: jsonEncode(userData),
    );
  }

  /// Get stored user data
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

  /// Check if user has valid tokens stored
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // =========================================
  // Authentication Methods
  // =========================================

  /// Sign in with Google
  /// 1. Triggers Google Sign-In flow
  /// 2. Sends Google ID token to backend
  /// 3. Receives and stores JWT tokens
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Sign in was cancelled');
      }

      // Step 2: Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      // Step 3: Send token to backend
      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authGoogle}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': idToken}),
      ).timeout(ApiConstants.connectionTimeout);

      // Step 4: Handle response
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Store tokens
        await _storeTokens(
          accessToken: data['tokens']['access'],
          refreshToken: data['tokens']['refresh'],
        );
        
        // Store user data
        await _storeUserData(data['user']);
        
        // Parse user
        final user = User.fromJson(data['user']);
        final bool isDoctor = data['is_doctor'] ?? false;
        
        return AuthResult.success(user: user, isDoctor: isDoctor);
      } else {
        // Parse error message
        try {
          final error = jsonDecode(response.body);
          return AuthResult.failure(error['error'] ?? 'Authentication failed');
        } catch (e) {
          return AuthResult.failure('Authentication failed (${response.statusCode})');
        }
      }
    } on http.ClientException catch (e) {
      return AuthResult.failure('Network error: ${e.message}');
    } catch (e) {
      return AuthResult.failure('Sign in failed: ${e.toString()}');
    }
  }

  /// Get current user from backend
  /// GET /api/auth/me/
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
        
        // Update stored user data
        await _storeUserData(data['user']);
        
        return AuthResult.success(user: user, isDoctor: isDoctor);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          // Retry with new token
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

  /// Refresh the access token using refresh token
  /// POST /api/auth/token/refresh/
  Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();
      
      if (refreshTokenValue == null) {
        return false;
      }

      final Uri url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.authTokenRefresh}',
      );
      
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
        
        // Store new access token
        await _storage.write(
          key: ApiConstants.accessTokenKey,
          value: data['access'],
        );
        
        // Some backends also return a new refresh token
        if (data['refresh'] != null) {
          await _storage.write(
            key: ApiConstants.refreshTokenKey,
            value: data['refresh'],
          );
        }
        
        return true;
      } else {
        // Refresh token is invalid/expired
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  /// Clears all stored tokens and signs out of Google
  Future<void> logout() async {
    // Sign out from Google
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore Google sign out errors
    }
    
    // Clear all stored data
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: ApiConstants.userDataKey);
  }
}

/// Result wrapper for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final bool isDoctor;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.isDoctor = false,
    this.error,
  });

  /// Create a successful result
  factory AuthResult.success({
    required User user,
    required bool isDoctor,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      isDoctor: isDoctor,
    );
  }

  /// Create a failure result
  factory AuthResult.failure(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(user: ${user?.email}, isDoctor: $isDoctor)';
    }
    return 'AuthResult.failure(error: $error)';
  }
}
