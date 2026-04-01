import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

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
  await _ensureCheckoutScript();

  final razorpayCtor = js_util.getProperty(html.window, 'Razorpay');
  if (razorpayCtor == null) {
    onFailure('Razorpay checkout is unavailable on web.');
    return;
  }

  final options = js_util.jsify({
    'key': keyId,
    'amount': amountPaise,
    'order_id': orderId,
    'name': 'Cerebro Health',
    'description': description,
    'prefill': {
      'contact': prefillContact,
      'email': prefillEmail,
    },
    'theme': {
      'color': '#1A5276',
    },
    'handler': js_util.allowInterop((dynamic response) async {
      final rzOrderId =
          (js_util.getProperty(response, 'razorpay_order_id') ?? orderId)
              .toString();
      final rzPaymentId =
          (js_util.getProperty(response, 'razorpay_payment_id') ?? '')
              .toString();
      final rzSignature =
          (js_util.getProperty(response, 'razorpay_signature') ?? '')
              .toString();

      await onSuccess(
        orderId: rzOrderId,
        paymentId: rzPaymentId,
        signature: rzSignature,
      );
    }),
    'modal': {
      'ondismiss': js_util.allowInterop(() {
        onFailure('Payment popup was closed.');
      }),
    },
  });

  final razorpay = js_util.callConstructor(razorpayCtor, [options]);

  js_util.callMethod(razorpay, 'on', [
    'payment.failed',
    js_util.allowInterop((dynamic response) {
      final error = js_util.getProperty(response, 'error');
      final message = error != null
          ? (js_util.getProperty(error, 'description') ?? 'Payment failed')
              .toString()
          : 'Payment failed';
      onFailure(message);
    }),
  ]);

  js_util.callMethod(razorpay, 'open', []);
}

Future<void> _ensureCheckoutScript() async {
  final existing = html.document.getElementById('razorpay-checkout-js');
  if (existing != null) return;

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = 'razorpay-checkout-js'
    ..type = 'text/javascript'
    ..src = 'https://checkout.razorpay.com/v1/checkout.js'
    ..async = true;

  script.onLoad.first.then((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        Exception('Failed to load Razorpay checkout script.'),
      );
    }
  });

  html.document.head?.append(script);
  await completer.future;
}
