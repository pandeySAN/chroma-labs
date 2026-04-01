import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/create_payment_order_usecase.dart';
import '../../domain/usecases/verify_payment_usecase.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────

final paymentRemoteDsProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSource(ref.watch(dioClientProvider));
});

final paymentRepoProvider = Provider<PaymentRepositoryImpl>((ref) {
  return PaymentRepositoryImpl(ref.watch(paymentRemoteDsProvider));
});

final createOrderUseCaseProvider = Provider<CreatePaymentOrderUseCase>((ref) {
  return CreatePaymentOrderUseCase(ref.watch(paymentRepoProvider));
});

final verifyPaymentUseCaseProvider = Provider<VerifyPaymentUseCase>((ref) {
  return VerifyPaymentUseCase(ref.watch(paymentRepoProvider));
});

// ─── State ────────────────────────────────────────────────────────────────

enum PaymentStatus {
  idle,
  creatingOrder,
  awaitingPayment,
  verifying,
  success,
  failed,
}

class PaymentState {
  final PaymentStatus status;
  final PaymentOrderEntity? order;
  final String? errorMessage;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.order,
    this.errorMessage,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    PaymentOrderEntity? order,
    String? errorMessage,
  }) {
    return PaymentState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  CreatePaymentOrderUseCase get _createOrderUC =>
      ref.read(createOrderUseCaseProvider);
  VerifyPaymentUseCase get _verifyUC => ref.read(verifyPaymentUseCaseProvider);

  /// Step 1 — call backend to create a Razorpay order
  Future<PaymentOrderEntity?> createOrder({
    required int appointmentId,
    required double amount,
  }) async {
    state = state.copyWith(status: PaymentStatus.creatingOrder);
    final result = await _createOrderUC.execute(
      appointmentId: appointmentId,
      amount: amount,
    );
    return result.fold(
      (error) {
        state = state.copyWith(
            status: PaymentStatus.failed, errorMessage: error);
        return null;
      },
      (order) {
        state =
            state.copyWith(status: PaymentStatus.awaitingPayment, order: order);
        return order;
      },
    );
  }

  /// Step 2 — verify after Razorpay SDK callback
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = state.copyWith(status: PaymentStatus.verifying);
    final result = await _verifyUC.execute(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
    return result.fold(
      (error) {
        state = state.copyWith(
            status: PaymentStatus.failed, errorMessage: error);
        return false;
      },
      (_) {
        state = state.copyWith(status: PaymentStatus.success);
        return true;
      },
    );
  }

  void reset() => state = const PaymentState();
}

final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);
