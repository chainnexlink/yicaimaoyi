import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/demand_repository.dart';

final demandRepositoryProvider = Provider<DemandRepository>((ref) {
  return DemandRepository(ref.read(dioProvider));
});

class DemandListState {
  final List<DemandModel> demands;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? currentCategory;

  const DemandListState({
    this.demands = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
    this.currentCategory,
  });

  DemandListState copyWith({
    List<DemandModel>? demands,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? currentCategory,
  }) {
    return DemandListState(
      demands: demands ?? this.demands,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }
}

final demandListProvider =
    StateNotifierProvider<DemandListNotifier, DemandListState>((ref) {
  return DemandListNotifier(ref.read(demandRepositoryProvider));
});

class DemandListNotifier extends StateNotifier<DemandListState> {
  final DemandRepository _repository;

  DemandListNotifier(this._repository) : super(const DemandListState());

  Future<void> loadDemands({String? category}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentCategory: category,
    );
    try {
      final result =
          await _repository.list(category: category, page: 0);
      state = state.copyWith(
        demands: result.content,
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
      final result = await _repository.list(
          category: state.currentCategory, page: nextPage);
      state = state.copyWith(
        demands: [...state.demands, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createDemand(Map<String, dynamic> data) async {
    await _repository.create(data);
    await refresh();
  }

  Future<void> refresh() => loadDemands(category: state.currentCategory);
}

/// 我的需求（采购商）
final myDemandsProvider =
    StateNotifierProvider<MyDemandsNotifier, DemandListState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return MyDemandsNotifier(ref.read(demandRepositoryProvider), userId: userId);
});

class MyDemandsNotifier extends StateNotifier<DemandListState> {
  final DemandRepository _repository;
  final int userId;

  MyDemandsNotifier(this._repository, {required this.userId})
      : super(const DemandListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.listByBuyer(userId, page: 0);
      state = state.copyWith(
        demands: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}
