import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(ref.read(dioProvider));
});

class NewsListState {
  final List<NewsArticle> articles;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int? selectedIndustryId;

  const NewsListState({
    this.articles = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
    this.selectedIndustryId,
  });

  NewsListState copyWith({
    List<NewsArticle>? articles,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? selectedIndustryId,
  }) {
    return NewsListState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      selectedIndustryId: selectedIndustryId ?? this.selectedIndustryId,
    );
  }
}

final newsListProvider = StateNotifierProvider<NewsListNotifier, NewsListState>(
  (ref) {
    return NewsListNotifier(ref.read(newsRepositoryProvider));
  },
);

class NewsListNotifier extends StateNotifier<NewsListState> {
  final NewsRepository _repository;

  NewsListNotifier(this._repository) : super(const NewsListState());

  Future<void> loadArticles({int? industryId}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedIndustryId: industryId,
    );
    try {
      final result = await _repository.list(page: 0, industryId: industryId);
      state = state.copyWith(
        articles: result.content,
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
        page: nextPage,
        industryId: state.selectedIndustryId,
      );
      state = state.copyWith(
        articles: [...state.articles, ...result.content],
        isLoading: false,
        currentPage: nextPage,
        hasMore: result.hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => loadArticles(industryId: state.selectedIndustryId);
}

/// 最新资讯
final latestNewsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final repo = ref.read(newsRepositoryProvider);
  return repo.getLatest(size: 4);
});

/// 行业分类
final industriesProvider = FutureProvider<List<Industry>>((ref) async {
  final repo = ref.read(newsRepositoryProvider);
  return repo.getIndustries();
});

/// 新闻详情状态
class NewsDetailState {
  final NewsArticle? article;
  final List<NewsArticle> recommended;
  final bool isLoading;
  final String? error;

  const NewsDetailState({
    this.article,
    this.recommended = const [],
    this.isLoading = false,
    this.error,
  });

  NewsDetailState copyWith({
    NewsArticle? article,
    List<NewsArticle>? recommended,
    bool? isLoading,
    String? error,
  }) {
    return NewsDetailState(
      article: article ?? this.article,
      recommended: recommended ?? this.recommended,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 新闻详情 Provider - 按文章ID创建
final newsDetailProvider = StateNotifierProvider.autoDispose
    .family<NewsDetailNotifier, NewsDetailState, int>((ref, articleId) {
      return NewsDetailNotifier(ref.read(newsRepositoryProvider), articleId);
    });

class NewsDetailNotifier extends StateNotifier<NewsDetailState> {
  final NewsRepository _repository;
  final int _articleId;

  NewsDetailNotifier(this._repository, this._articleId)
    : super(const NewsDetailState());

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final article = await _repository.getDetail(_articleId);
      state = state.copyWith(article: article, isLoading: false);
      // 记录浏览量
      _repository.incrementViewCount(_articleId);
      // 加载推荐文章
      _loadRecommended();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadRecommended() async {
    try {
      final recommended = await _repository.getRecommended(size: 6);
      state = state.copyWith(recommended: recommended);
    } catch (_) {}
  }
}
