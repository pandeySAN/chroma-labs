/// App configuration constants
class AppConfig {
  AppConfig._();

  /// Google OAuth Web Client ID
  /// Get this from Google Cloud Console:
  /// 1. Go to https://console.cloud.google.com
  /// 2. Select your project
  /// 3. Go to APIs & Services → Credentials
  /// 4. Create OAuth 2.0 Client ID (Web application)
  /// 5. Copy the Client ID here
  /// 
  /// IMPORTANT: Replace this with your actual Client ID
  static const String googleWebClientId = 
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
  
  /// Google OAuth Android Client ID (optional, usually auto-detected)
  static const String? googleAndroidClientId = null;
  
  /// Google OAuth iOS Client ID (optional, usually from GoogleService-Info.plist)
  static const String? googleIOSClientId = null;
}
