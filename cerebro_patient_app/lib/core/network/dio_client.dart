import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_strings.dart';
import '../errors/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _skipAuthKey = 'skipAuth';

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuthKey] == true) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.read(key: AppStrings.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.requestOptions.extra[_skipAuthKey] == true) {
      handler.next(error);
      return;
    }
    if (error.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final opts = error.requestOptions;
        try {
          final token = await _storage.read(key: AppStrings.accessTokenKey);
          opts.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          return handler.next(error);
        }
      }
    }
    handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppStrings.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.tokenRefresh}',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(
            key: AppStrings.accessTokenKey, value: data['access']);
        if (data['refresh'] != null) {
          await _storage.write(
              key: AppStrings.refreshTokenKey, value: data['refresh']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {_skipAuthKey: !requiresAuth}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(extra: {_skipAuthKey: !requiresAuth}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        options: Options(extra: {_skipAuthKey: !requiresAuth}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = e.response;
    if (response == null) {
      return const NetworkException();
    }

    if (response.statusCode == 401) {
      return const UnauthorizedException();
    }

    final data = response.data;
    String message = AppStrings.serverError;

    if (data is Map<String, dynamic>) {
      message = data['detail'] ??
          data['error'] ??
          data['message'] ??
          _extractFirstError(data) ??
          AppStrings.serverError;
    }

    return ServerException(message, statusCode: response.statusCode);
  }

  String? _extractFirstError(Map<String, dynamic> data) {
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String) return value;
    }
    return null;
  }
}
