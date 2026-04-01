class AppStrings {
  AppStrings._();

  static const String appName = 'Cerebro';
  static const String tagline = 'Your Health, Simplified';

  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account?";
  static const String hasAccount = 'Already have an account?';
  static const String continueWithGoogle = 'Continue with Google';
  static const String orDivider = 'OR';

  // Errors
  static const String networkError = 'No internet connection';
  static const String serverError = 'Server error. Please try again.';
  static const String unknownError = 'Something went wrong';
  static const String sessionExpired = 'Session expired. Please login again.';

  // Storage keys
  static const String accessTokenKey = 'cerebro_access_token';
  static const String refreshTokenKey = 'cerebro_refresh_token';
  static const String userDataKey = 'cerebro_user_data';
}
