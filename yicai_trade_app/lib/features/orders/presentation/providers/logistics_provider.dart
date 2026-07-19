import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/logistics_repository.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return LogisticsRepository(ref.read(dioProvider));
});

class LogisticsListState {
  final List<LogisticsInfo> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const LogisticsListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  LogisticsListState copyWith({
    List<LogisticsInfo>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return LogisticsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final logisticsListProvider =
    StateNotifierProvider<LogisticsListNotifier, LogisticsListState>((ref) {
  return LogisticsListNotifier(ref.read(logisticsRepositoryProvider));
});

class LogisticsListNotifier extends StateNotifier<LogisticsListState> {
  final LogisticsRepository _repository;

  LogisticsListNotifier(this._repository) : super(const LogisticsListState());

  Future<void> loadList({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.list(status: status, page: 0);
      state = state.copyWith(
        items: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? status}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.list(status: status, page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh({String? status}) => loadList(status: status);
}
