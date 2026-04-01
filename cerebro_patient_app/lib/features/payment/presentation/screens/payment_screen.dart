import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../providers/payment_provider.dart';
import 'booking_success_screen.dart';
import '../utils/razorpay_web_checkout_stub.dart'
    if (dart.library.html) '../utils/razorpay_web_checkout_web.dart'
    as web_checkout;

// ─── Put your Razorpay TEST key here.
// Switch to rzp_live_xxx before going to production.
const String _razorpayKeyId = 'rzp_live_SYCVQM2f4aoBTE';

class PaymentScreen extends ConsumerStatefulWidget {
  final AppointmentEntity appointment;
  const PaymentScreen({super.key, required this.appointment});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }

    // Create order as soon as screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _createOrder());
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ── Step 1: Create order on backend ─────────────────────────────────────
  Future<void> _createOrder() async {
    final order = await ref.read(paymentProvider.notifier).createOrder(
          appointmentId: widget.appointment.id,
          amount: widget.appointment.consultationFee,
        );

    if (order == null || !mounted) return;

    // ── Step 2: Open Razorpay checkout sheet ────────────────────────────
    final options = {
      'key': _razorpayKeyId,
      'amount': (order.amount * 100).toInt(), // Razorpay expects paise
      'order_id': order.orderId,
      'name': 'Cerebro Health',
      'description': 'Consultation with Dr. ${widget.appointment.doctorName}',
      'prefill': {
        // These come from your auth provider — replace with actual values
        // if you have a currentUserProvider set up.
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#1A5276',
      },
    };

    if (kIsWeb) {
      try {
        await web_checkout.openWebRazorpayCheckout(
          keyId: _razorpayKeyId,
          amountPaise: (order.amount * 100).toInt(),
          orderId: order.orderId,
          description: 'Consultation with Dr. ${widget.appointment.doctorName}',
          onSuccess: ({
            required String orderId,
            required String paymentId,
            required String signature,
          }) async {
            await _handleWebPaymentSuccess(
              orderId: orderId,
              paymentId: paymentId,
              signature: signature,
            );
          },
          onFailure: _handleWebPaymentFailure,
        );
      } catch (_) {
        _showError('Could not open web payment. Please try again.');
      }
      return;
    }

    try {
      _razorpay?.open(options);
    } catch (e) {
      _showError('Could not open payment. Please try again.');
    }
  }

  Future<void> _handleWebPaymentSuccess({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final verified = await ref.read(paymentProvider.notifier).verifyPayment(
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
        );

    if (!mounted) return;

    if (verified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            appointment: widget.appointment,
            paymentId: paymentId,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      final state = ref.read(paymentProvider);
      _showError(state.errorMessage ?? 'Payment verification failed.');
    }
  }

  void _handleWebPaymentFailure(String message) {
    _showError(message);
    ref.read(paymentProvider.notifier).reset();
  }

  // ── Step 3: Handle payment success ──────────────────────────────────────
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final verified = await ref.read(paymentProvider.notifier).verifyPayment(
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );

    if (!mounted) return;

    if (verified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            appointment: widget.appointment,
            paymentId: response.paymentId,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      final state = ref.read(paymentProvider);
      _showError(state.errorMessage ?? 'Payment verification failed.');
    }
  }

  // ── Payment failed ───────────────────────────────────────────────────────
  void _onPaymentError(PaymentFailureResponse response) {
    _showError(response.message ?? 'Payment was not completed.');
    // Reset state so patient can retry
    ref.read(paymentProvider.notifier).reset();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: _buildStatusIcon(state.status),
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _statusTitle(state.status),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _statusSubtitle(state.status),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),

            if (state.status == PaymentStatus.failed) ...[
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _createOrder,
                  child: Text(
                    'Retry Payment',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.creatingOrder:
      case PaymentStatus.verifying:
        return const Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 3),
        );
      case PaymentStatus.awaitingPayment:
        return const Icon(Icons.payment_rounded,
            size: 48, color: AppColors.primary);
      case PaymentStatus.success:
        return const Icon(Icons.check_circle_rounded,
            size: 56, color: AppColors.success);
      case PaymentStatus.failed:
        return const Icon(Icons.error_rounded,
            size: 56, color: AppColors.error);
      default:
        return const Icon(Icons.lock_rounded,
            size: 48, color: AppColors.primary);
    }
  }

  String _statusTitle(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.creatingOrder:
        return 'Preparing Payment...';
      case PaymentStatus.awaitingPayment:
        return 'Opening Payment Gateway';
      case PaymentStatus.verifying:
        return 'Verifying Payment...';
      case PaymentStatus.success:
        return 'Payment Successful!';
      case PaymentStatus.failed:
        return 'Payment Failed';
      default:
        return 'Initialising...';
    }
  }

  String _statusSubtitle(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.creatingOrder:
        return 'Please wait while we set up your payment.';
      case PaymentStatus.awaitingPayment:
        return 'Complete the payment in the Razorpay window.';
      case PaymentStatus.verifying:
        return 'Confirming your payment with our server...';
      case PaymentStatus.success:
        return 'Your appointment has been confirmed.';
      case PaymentStatus.failed:
        return 'Something went wrong. You can retry below.';
      default:
        return '';
    }
  }
}
