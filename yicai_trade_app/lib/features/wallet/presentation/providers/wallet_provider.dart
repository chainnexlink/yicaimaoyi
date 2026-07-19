import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(dioProvider));
});

class WalletState {
  final WalletInfo? wallet;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  WalletState copyWith({
    WalletInfo? wallet,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  final userId = ref.watch(currentUserIdProvider);
  final userType = ref.watch(currentUserTypeProvider);
  return WalletNotifier(
    ref.read(walletRepositoryProvider),
    userId: userId,
    userType: userType,
  );
});

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;
  final int userId;
  final String userType;

  WalletNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const WalletState());

  /// 将 userType 映射为钱包 ownerType
  /// ADMIN 默认以 BUYER 身份访问钱包
  String get _ownerType => userType == 'SUPPLIER' ? 'SUPPLIER' : 'BUYER';

  bool _hasError = false;

  Future<void> loadWallet() async {
    if (_hasError) return; // 避免重复请求已知失败的接口
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wallet = await _repository.getWallet(_ownerType, userId);
      state = state.copyWith(wallet: wallet, isLoading: false);
    } catch (e) {
      _hasError = true;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTransactions() async {
    if (_hasError) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getTransactions(
        _ownerType,
        userId,
        page: 0,
      );
      state = state.copyWith(
        transactions: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      _hasError = true;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getTransactions(
        _ownerType,
        userId,
        page: nextPage,
      );
      state = state.copyWith(
        transactions: [...state.transactions, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 重置错误状态，允许重新加载
  void resetError() {
    _hasError = false;
  }

  Future<void> recharge(double amount) async {
    await _repository.recharge(_ownerType, userId, amount);
    _hasError = false;
    await loadWallet();
  }

  Future<void> withdraw(double amount) async {
    await _repository.withdraw(_ownerType, userId, amount);
    _hasError = false;
    await loadWallet();
  }
}
