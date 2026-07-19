import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/order_repository.dart';
import '../../data/models/order_model.dart';

class OrderListState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? currentStatus;
  final String? searchKeyword;

  const OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
    this.currentStatus,
    this.searchKeyword,
  });

  OrderListState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? currentStatus,
    String? searchKeyword,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      currentStatus: currentStatus ?? this.currentStatus,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(dioProvider));
});

final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      final userType = ref.watch(currentUserTypeProvider);
      return OrderListNotifier(
        ref.read(orderRepositoryProvider),
        userId: userId,
        userType: userType,
      );
    });

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderRepository _repository;
  final int userId;
  final String userType;

  OrderListNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const OrderListState());

  bool get _isBuyer => userType != 'SUPPLIER';

  Future<void> loadOrders({String? status, String? keyword}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentStatus: status,
      searchKeyword: keyword,
    );
    try {
      final result = _isBuyer
          ? await _repository.getOrdersByBuyer(
              userId,
              status: status,
              keyword: keyword,
              page: 0,
            )
          : await _repository.getOrdersBySupplier(
              userId,
              status: status,
              page: 0,
            );
      state = state.copyWith(
        orders: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = _isBuyer
          ? await _repository.getOrdersByBuyer(
              userId,
              status: state.currentStatus,
              keyword: state.searchKeyword,
              page: nextPage,
            )
          : await _repository.getOrdersBySupplier(
              userId,
              status: state.currentStatus,
              page: nextPage,
            );
      state = state.copyWith(
        orders: [...state.orders, ...result.content],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() =>
      loadOrders(status: state.currentStatus, keyword: state.searchKeyword);

  Future<void> cancelOrder(int orderId, {String? reason}) async {
    try {
      await _repository.cancelOrder(orderId, operatorId: userId);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  Future<void> confirmReceipt(int orderId) async {
    try {
      await _repository.confirmReceipt(orderId, buyerId: userId);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  String _extractError(dynamic e) {
    if (e is Exception) return e.toString();
    return 'error.operation_failed'.tr();
  }
}
