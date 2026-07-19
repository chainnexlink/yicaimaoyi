import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(dioProvider));
});

class ReviewListState {
  final List<ReviewModel> reviews;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const ReviewListState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  ReviewListState copyWith({
    List<ReviewModel>? reviews,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return ReviewListState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final reviewListProvider =
    StateNotifierProvider<ReviewListNotifier, ReviewListState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final userType = ref.watch(currentUserTypeProvider);
  return ReviewListNotifier(
    ref.read(reviewRepositoryProvider),
    userId: userId,
    userType: userType,
  );
});

class ReviewListNotifier extends StateNotifier<ReviewListState> {
  final ReviewRepository _repository;
  final int userId;
  final String userType;

  ReviewListNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const ReviewListState());

  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = userType == 'SUPPLIER'
          ? await _repository.getBySupplier(userId, page: 0)
          : await _repository.getByBuyer(userId, page: 0);
      state = state.copyWith(
        reviews: result.content,
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
        reviews: [...state.reviews, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitReview(Map<String, dynamic> data) async {
    await _repository.submitReview(data);
    await loadReviews();
  }

  Future<void> refresh() => loadReviews();
}
