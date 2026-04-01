import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository _repository;
  const GoogleSignInUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() {
    return _repository.signInWithGoogle();
  }
}
