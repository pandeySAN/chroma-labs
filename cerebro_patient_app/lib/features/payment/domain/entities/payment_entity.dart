class PaymentOrderEntity {
  final String orderId;       // Razorpay order id  e.g. order_xxxxx
  final double amount;        // in ₹
  final String currency;
  final int appointmentId;

  const PaymentOrderEntity({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.appointmentId,
  });
}

class PaymentVerifyEntity {
  final bool success;
  final String message;
  final int? appointmentId;

  const PaymentVerifyEntity({
    required this.success,
    required this.message,
    this.appointmentId,
  });
}
