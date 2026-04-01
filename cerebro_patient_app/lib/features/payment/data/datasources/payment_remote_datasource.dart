import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/payment_model.dart';

class PaymentRemoteDataSource {
  final DioClient _client;
  PaymentRemoteDataSource(this._client);

  Future<PaymentOrderModel> createOrder({
    required int appointmentId,
    required double amount,
  }) async {
    final response = await _client.post(
      ApiEndpoints.createPaymentOrder,
      data: {
        'appointment_id': appointmentId,
        'amount': amount,
      },
    );
    return PaymentOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentVerifyModel> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _client.post(
      ApiEndpoints.verifyPayment,
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return PaymentVerifyModel.fromJson(response.data as Map<String, dynamic>);
  }
}
