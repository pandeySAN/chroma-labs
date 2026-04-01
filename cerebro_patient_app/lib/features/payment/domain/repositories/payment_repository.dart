import 'package:dartz/dartz.dart';
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<String, PaymentOrderEntity>> createOrder({
    required int appointmentId,
    required double amount,
  });

  Future<Either<String, PaymentVerifyEntity>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
}
