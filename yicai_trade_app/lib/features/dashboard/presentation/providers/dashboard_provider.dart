import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_model.dart';

class DashboardState {
  final DashboardData data;
  final bool isLoading;
  final String? error;
  final String period;

  const DashboardState({
    this.data = const DashboardData(),
    this.isLoading = false,
    this.error,
    this.period = 'month',
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
    String? period,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref.read(dashboardRepositoryProvider));
    });

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState());

  Future<void> loadData({String period = 'month'}) async {
    state = state.copyWith(isLoading: true, error: null, period: period);
    try {
      final data = await _repository.getDashboardData(period: period);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadData(period: state.period);
}
