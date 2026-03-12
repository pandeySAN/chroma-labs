import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

/// HTTP API Client with authentication support
class ApiClient {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConstants.accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiConstants.refreshTokenKey);
  }

  /// Store tokens
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: ApiConstants.userDataKey);
  }

  /// Build headers with optional authentication
  Future<Map<String, String>> _buildHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Build full URL
  Uri _buildUrl(String endpoint) {
    return Uri.parse('${ApiConstants.baseUrl}$endpoint');
  }

  /// Validate that response is JSON
  void _ensureJson(http.Response response) {
    final contentType = response.headers['content-type'];
    final body = response.body.trim();
    
    // Check content-type header or body structure
    final isJson = (contentType != null && contentType.contains('application/json')) ||
        body.startsWith('{') ||
        body.startsWith('[');

    if (!isJson) {
      throw Exception(
        'Server error (${response.statusCode}). Please try again later.',
      );
    }
  }

  /// GET request
  Future<http.Response> get(String endpoint, {bool auth = true}) async {
    final headers = await _buildHeaders(auth: auth);

    final response = await http
        .get(_buildUrl(endpoint), headers: headers)
        .timeout(ApiConstants.connectionTimeout);

    return await _handleResponse(response);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = await _buildHeaders(auth: auth);

    final response = await http
        .post(
          _buildUrl(endpoint),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConstants.connectionTimeout);

    return await _handleResponse(response);
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = await _buildHeaders(auth: auth);

    final response = await http
        .patch(
          _buildUrl(endpoint),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConstants.connectionTimeout);

    return await _handleResponse(response);
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint, {bool auth = true}) async {
    final headers = await _buildHeaders(auth: auth);

    final response = await http
        .delete(
          _buildUrl(endpoint),
          headers: headers,
        )
        .timeout(ApiConstants.connectionTimeout);

    return await _handleResponse(response);
  }

  /// Handle response and token refresh if needed
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();

      if (refreshed) {
        throw TokenExpiredException('Token refreshed, retry request');
      } else {
        throw UnauthorizedException('Authentication failed');
      }
    }

    _ensureJson(response);

    return response;
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        _buildUrl(ApiConstants.authTokenRefresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _storage.write(
          key: ApiConstants.accessTokenKey,
          value: data['access'],
        );

        return true;
      }
    } catch (_) {}

    return false;
  }
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}