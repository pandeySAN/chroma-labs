import 'package:dartz/dartz.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class VerifyPaymentUseCase {
  final PaymentRepository repository;
  VerifyPaymentUseCase(this.repository);

  Future<Either<String, PaymentVerifyEntity>> execute({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return repository.verifyPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }
}
