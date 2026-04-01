import 'dart:async';

typedef WebPaymentSuccessCallback = Future<void> Function({
  required String orderId,
  required String paymentId,
  required String signature,
});

typedef WebPaymentFailureCallback = void Function(String message);

Future<void> openWebRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String orderId,
  required String description,
  required WebPaymentSuccessCallback onSuccess,
  required WebPaymentFailureCallback onFailure,
  String prefillContact = '',
  String prefillEmail = '',
}) async {
  throw UnsupportedError('Web Razorpay checkout is only available on web.');
}
