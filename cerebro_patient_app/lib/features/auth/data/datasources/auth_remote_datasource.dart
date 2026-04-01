import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';

class AuthRemoteDataSource {
  final DioClient _dio;

  static const _googleWebClientId =
      '230465261403-vqlfklqd8onjds2h5cucvphe9plmj92j.apps.googleusercontent.com';

  bool _googleInitialized = false;

  AuthRemoteDataSource(this._dio);

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _googleWebClientId,
      serverClientId: _googleWebClientId,
    );
    _googleInitialized = true;
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'identifier': identifier, 'password': password},
      requiresAuth: false,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.signup,
      data: {
        'name': name,
        'identifier': identifier,
        'password': password,
        'role': 'patient',
      },
      requiresAuth: false,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    await _ensureGoogleInit();

    final completer = Completer<GoogleSignInAccount>();

    late StreamSubscription<GoogleSignInAuthenticationEvent> sub;
    sub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (completer.isCompleted) return;
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn(:final user):
            completer.complete(user);
          case GoogleSignInAuthenticationEventSignOut():
            completer.completeError(
              const ServerException('Sign in cancelled'),
            );
        }
        sub.cancel();
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(
            ServerException(e is GoogleSignInException
                ? (e.description ?? 'Google sign-in failed')
                : e.toString()),
          );
        }
        sub.cancel();
      },
    );

    if (GoogleSignIn.instance.supportsAuthenticate()) {
      await GoogleSignIn.instance.authenticate();
    } else {
      sub.cancel();
      throw const ServerException(
        'Google Sign-In not supported on this platform',
      );
    }

    final user = await completer.future;

    final scopes = ['email', 'profile', 'openid'];
    final authorization =
        await user.authorizationClient.authorizeScopes(scopes);
    final accessToken = authorization.accessToken;

    final response = await _dio.post(
      ApiEndpoints.googleAuth,
      data: {
        'token': accessToken,
        'token_type': 'access_token',
        'role': 'patient',
      },
      requiresAuth: false,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data as Map<String, dynamic>;
  }

  Future<void> googleSignOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'identifier': identifier},
      requiresAuth: false,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {'identifier': identifier, 'otp': otp},
      requiresAuth: false,
    );
  }

  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'identifier': identifier,
        'otp': otp,
        'new_password': newPassword,
      },
      requiresAuth: false,
    );
  }
}
