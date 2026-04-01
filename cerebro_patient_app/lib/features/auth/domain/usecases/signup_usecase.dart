import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository _repository;
  const SignupUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String identifier,
    required String password,
  }) {
    return _repository.signup(
      name: name,
      identifier: identifier,
      password: password,
    );
  }
}
