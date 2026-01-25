import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/services/auth_service.dart';

/// Provides authentication state management for the app
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  Doctor? _currentDoctor;
  bool _isAuthenticated = false;
  bool _isDoctor = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  Doctor? get currentDoctor => _currentDoctor;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDoctor => _isDoctor;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get userName => _currentUser?.fullName ?? 'User';
  String get userEmail => _currentUser?.email ?? '';
  String get userInitials {
    if (_currentUser == null) return 'U';
    final names = _currentUser!.fullName.split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  /// Initialize auth state by checking stored token
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        final result = await _authService.getCurrentUser();
        if (result.success && result.user != null) {
          _currentUser = result.user;
          _currentDoctor = result.doctor;
          _isDoctor = result.isDoctor;
          _isAuthenticated = true;
        } else {
          await _authService.logout();
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      _isAuthenticated = false;
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Login with email/mobile and password
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _currentDoctor = result.doctor;
        _isDoctor = result.isDoctor;
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.error ?? 'Login failed';
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login';
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  /// Signup with name, email/mobile, and password
  Future<bool> signup({
    required String name,
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signup(
        name: name,
        identifier: identifier,
        password: password,
      );

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _currentDoctor = result.doctor;
        _isDoctor = result.isDoctor;
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.error ?? 'Signup failed';
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during signup';
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _currentDoctor = result.doctor;
        _isDoctor = result.isDoctor;
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.error ?? 'Google sign-in failed';
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during Google sign-in';
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  /// Register current user as a doctor
  Future<bool> registerAsDoctor({
    required String specialization,
    int? clinicId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.registerAsDoctor(
        specialization: specialization,
        clinicId: clinicId,
      );

      if (result.success) {
        _currentDoctor = result.doctor;
        _isDoctor = result.isDoctor;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error ?? 'Failed to register as doctor';
      }
    } catch (e) {
      _errorMessage = 'An error occurred during doctor registration';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Get available clinics for registration
  Future<List<Clinic>> getClinics() async {
    return await _authService.getClinics();
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      final result = await _authService.getCurrentUser();
      if (result.success && result.user != null) {
        _currentUser = result.user;
        _currentDoctor = result.doctor;
        _isDoctor = result.isDoctor;
        notifyListeners();
      }
    } catch (e) {
      // Silent refresh failure
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    }

    _currentUser = null;
    _currentDoctor = null;
    _isAuthenticated = false;
    _isDoctor = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
