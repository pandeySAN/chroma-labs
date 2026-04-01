import '../../domain/entities/payment_entity.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class PaymentOrderModel extends PaymentOrderEntity {
  const PaymentOrderModel({
    required super.orderId,
    required super.amount,
    required super.currency,
    required super.appointmentId,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      orderId: json['order_id'] as String,
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      appointmentId: json['appointment_id'] as int,
    );
  }
}

class PaymentVerifyModel extends PaymentVerifyEntity {
  const PaymentVerifyModel({
    required super.success,
    required super.message,
    super.appointmentId,
  });

  factory PaymentVerifyModel.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyModel(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      appointmentId: json['appointment_id'] as int?,
    );
  }
}
