import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final data = await _remote.login(
        identifier: identifier,
        password: password,
      );
      return Right(await _handleAuthResponse(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      final data = await _remote.signup(
        name: name,
        identifier: identifier,
        password: password,
      );
      return Right(await _handleAuthResponse(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final data = await _remote.signInWithGoogle();
      return Right(await _handleAuthResponse(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final data = await _remote.getCurrentUser();
      final user = UserModel.fromJson(data['user']);
      await _storage.write(
        key: AppStrings.userDataKey,
        value: jsonEncode(user.toJson()),
      );
      return Right(user);
    } on UnauthorizedException {
      return const Left(AuthFailure('Session expired'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return await _getStoredUser();
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.googleSignOut();
      await _storage.delete(key: AppStrings.accessTokenKey);
      await _storage.delete(key: AppStrings.refreshTokenKey);
      await _storage.delete(key: AppStrings.userDataKey);
      return const Right(null);
    } catch (e) {
      await _storage.deleteAll();
      return const Right(null);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppStrings.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String identifier) async {
    try {
      final data = await _remote.forgotPassword(identifier);
      return Right(data['email'] as String? ?? '');
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      await _remote.verifyOtp(identifier: identifier, otp: otp);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Helpers

  Future<UserEntity> _handleAuthResponse(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _storage.write(
      key: AppStrings.accessTokenKey,
      value: tokens['access'],
    );
    await _storage.write(
      key: AppStrings.refreshTokenKey,
      value: tokens['refresh'],
    );

    final user = UserModel.fromJson(data['user']);
    await _storage.write(
      key: AppStrings.userDataKey,
      value: jsonEncode(user.toJson()),
    );
    return user;
  }

  Future<Either<Failure, UserEntity>> _getStoredUser() async {
    try {
      final raw = await _storage.read(key: AppStrings.userDataKey);
      if (raw == null) return const Left(AuthFailure('Not logged in'));
      final user = UserModel.fromJson(jsonDecode(raw));
      return Right(user);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
