import 'package:dartz/dartz.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentOrderUseCase {
  final PaymentRepository repository;
  CreatePaymentOrderUseCase(this.repository);

  Future<Either<String, PaymentOrderEntity>> execute({
    required int appointmentId,
    required double amount,
  }) {
    return repository.createOrder(
      appointmentId: appointmentId,
      amount: amount,
    );
  }
}
