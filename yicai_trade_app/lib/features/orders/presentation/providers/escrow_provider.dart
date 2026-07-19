import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/escrow_repository.dart';

final escrowRepositoryProvider = Provider<EscrowRepository>((ref) {
  return EscrowRepository(ref.read(dioProvider));
});

class EscrowListState {
  final List<EscrowInfo> escrows;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const EscrowListState({
    this.escrows = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  EscrowListState copyWith({
    List<EscrowInfo>? escrows,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return EscrowListState(
      escrows: escrows ?? this.escrows,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final escrowListProvider =
    StateNotifierProvider<EscrowListNotifier, EscrowListState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final userType = ref.watch(currentUserTypeProvider);
  return EscrowListNotifier(
    ref.read(escrowRepositoryProvider),
    userId: userId,
    userType: userType,
  );
});

class EscrowListNotifier extends StateNotifier<EscrowListState> {
  final EscrowRepository _repository;
  final int userId;
  final String userType;

  EscrowListNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const EscrowListState());

  Future<void> loadEscrows() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = userType == 'SUPPLIER'
          ? await _repository.getBySupplier(userId, page: 0)
          : await _repository.getByBuyer(userId, page: 0);
      state = state.copyWith(
        escrows: result.content,
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
      final result = userType == 'SUPPLIER'
          ? await _repository.getBySupplier(userId, page: nextPage)
          : await _repository.getByBuyer(userId, page: nextPage);
      state = state.copyWith(
        escrows: [...state.escrows, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => loadEscrows();
}
