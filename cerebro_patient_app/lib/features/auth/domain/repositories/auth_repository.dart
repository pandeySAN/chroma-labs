import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signup({
    required String name,
    required String identifier,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<bool> isLoggedIn();

  Future<Either<Failure, String>> forgotPassword(String identifier);

  Future<Either<Failure, void>> verifyOtp({
    required String identifier,
    required String otp,
  });

  Future<Either<Failure, void>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  });
}
