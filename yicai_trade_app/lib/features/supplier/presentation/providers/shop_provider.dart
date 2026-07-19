import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.read(dioProvider));
});

class ShopListState {
  final List<ShopInfo> shops;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const ShopListState({
    this.shops = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  ShopListState copyWith({
    List<ShopInfo>? shops,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return ShopListState(
      shops: shops ?? this.shops,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final shopListProvider =
    StateNotifierProvider<ShopListNotifier, ShopListState>((ref) {
  return ShopListNotifier(ref.read(shopRepositoryProvider));
});

class ShopListNotifier extends StateNotifier<ShopListState> {
  final ShopRepository _repository;

  ShopListNotifier(this._repository) : super(const ShopListState());

  Future<void> loadShops({String? keyword, String? industry}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.list(
          keyword: keyword, industry: industry, page: 0);
      state = state.copyWith(
        shops: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? keyword, String? industry}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.list(
          keyword: keyword, industry: industry, page: nextPage);
      state = state.copyWith(
        shops: [...state.shops, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh({String? keyword, String? industry}) =>
      loadShops(keyword: keyword, industry: industry);
}

/// 供应商自己的店铺
final myShopProvider = FutureProvider<ShopInfo?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.read(shopRepositoryProvider);
  return repo.getBySupplierId(userId);
});
