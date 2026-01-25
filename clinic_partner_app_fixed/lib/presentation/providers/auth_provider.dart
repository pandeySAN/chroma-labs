import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

/// Provider for managing authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // =========================================
  // State Properties
  // =========================================

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDoctor = false;

  // =========================================
  // Getters
  // =========================================

  /// Current authenticated user
  User? get currentUser => _currentUser;

  /// Whether an async operation is in progress
  bool get isLoading => _isLoading;

  /// Error message from last operation
  String? get errorMessage => _errorMessage;

  /// Whether user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Whether user is a doctor
  bool get isDoctor => _isDoctor;

  /// User's full name or empty string
  String get userName => _currentUser?.fullName ?? '';

  /// User's email or empty string
  String get userEmail => _currentUser?.email ?? '';

  /// User's profile picture URL
  String? get userProfilePicture => _currentUser?.profilePicture;

  // =========================================
  // Private Methods
  // =========================================

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? message) {
    _errorMessage = message;
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

  /// Check if user has valid authentication tokens
  /// Returns true if tokens exist, false otherwise
  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Try to load user from stored data first
        final storedUser = await _authService.getStoredUser();
        if (storedUser != null) {
          _currentUser = storedUser;
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Load current user from the API
  /// Call this after checkAuthStatus returns true
  Future<void> loadUser() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _authService.getCurrentUser();

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isDoctor = result.isDoctor;
        _errorMessage = null;
      } else {
        _errorMessage = result.error ?? 'Failed to load user';
        
        // If we can't load from API, try stored user
        final storedUser = await _authService.getStoredUser();
        if (storedUser != null) {
          _currentUser = storedUser;
          _errorMessage = null; // Clear error if we got stored user
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading user: ${e.toString()}';
    }

    _setLoading(false);
  }

  /// Sign in with Google
  /// Returns true if sign in was successful
  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _authService.signInWithGoogle();

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isDoctor = result.isDoctor;
        _errorMessage = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result.error ?? 'Sign in failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Sign in error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Logout the current user
  /// Clears all stored tokens and user data
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors, clear state anyway
    }

    _currentUser = null;
    _isDoctor = false;
    _errorMessage = null;
    
    _setLoading(false);
  }

  /// Initialize auth state
  /// Checks for existing tokens and loads user if authenticated
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final hasTokens = await checkAuthStatus();
      
      if (hasTokens) {
        await loadUser();
      }
    } catch (e) {
      _errorMessage = 'Initialization error: ${e.toString()}';
    }

    _setLoading(false);
  }

  /// Refresh user data from API
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final result = await _authService.getCurrentUser();
      
      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isDoctor = result.isDoctor;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail refresh
    }
  }
}
