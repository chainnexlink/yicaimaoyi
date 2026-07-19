import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/home_api.dart';
import '../../data/models/banner_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 首页数据状态
class HomeState {
  final List<BannerModel> banners;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.banners = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<BannerModel>? banners,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 首页 API Provider
final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.read(dioProvider));
});

/// 首页数据 Provider
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.read(homeApiProvider));
});

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeApi _api;

  HomeNotifier(this._api) : super(const HomeState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final banners = await _api.getActiveBanners();
      state = state.copyWith(banners: banners, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
