import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(dioProvider));
});

class PaymentListState {
  final List<PaymentRecord> payments;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const PaymentListState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  PaymentListState copyWith({
    List<PaymentRecord>? payments,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return PaymentListState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final paymentListProvider =
    StateNotifierProvider<PaymentListNotifier, PaymentListState>((ref) {
  return PaymentListNotifier(ref.read(paymentRepositoryProvider));
});

class PaymentListNotifier extends StateNotifier<PaymentListState> {
  final PaymentRepository _repository;

  PaymentListNotifier(this._repository) : super(const PaymentListState());

  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getMyPayments(page: 0);
      state = state.copyWith(
        payments: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getMyPayments(page: nextPage);
      state = state.copyWith(
        payments: [...state.payments, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => loadPayments();
}
