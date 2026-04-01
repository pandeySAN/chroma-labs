import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, PaymentOrderEntity>> createOrder({
    required int appointmentId,
    required double amount,
  }) async {
    try {
      final result = await remoteDataSource.createOrder(
        appointmentId: appointmentId,
        amount: amount,
      );
      return Right(result);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Failed to create payment order';
      return Left(msg.toString());
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }

  @override
  Future<Either<String, PaymentVerifyEntity>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final result = await remoteDataSource.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      if (result.success) return Right(result);
      return Left(result.message);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Payment verification failed';
      return Left(msg.toString());
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }
}
