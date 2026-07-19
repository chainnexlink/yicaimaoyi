import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/monitor_repository.dart';
import '../../data/models/monitor_model.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return MonitorRepository(ref.read(dioProvider));
});

// ============ 监控主状态 ============
class MonitorState {
  final List<MonitorModel> monitors;
  final MonitorStats stats;
  final List<AlertItem> alerts;
  final int unviewedCount;
  final int currentTab; // 0=监控列表 1=预警
  final bool isLoading;
  final String? error;

  const MonitorState({
    this.monitors = const [],
    this.stats = const MonitorStats(),
    this.alerts = const [],
    this.unviewedCount = 0,
    this.currentTab = 0,
    this.isLoading = false,
    this.error,
  });

  MonitorState copyWith({
    List<MonitorModel>? monitors,
    MonitorStats? stats,
    List<AlertItem>? alerts,
    int? unviewedCount,
    int? currentTab,
    bool? isLoading,
    String? error,
  }) {
    return MonitorState(
      monitors: monitors ?? this.monitors,
      stats: stats ?? this.stats,
      alerts: alerts ?? this.alerts,
      unviewedCount: unviewedCount ?? this.unviewedCount,
      currentTab: currentTab ?? this.currentTab,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final monitorProvider = StateNotifierProvider<MonitorNotifier, MonitorState>((
  ref,
) {
  final userId = ref.watch(currentUserIdProvider);
  final userType = ref.watch(currentUserTypeProvider);
  return MonitorNotifier(
    ref.read(monitorRepositoryProvider),
    userId: userId,
    userType: userType,
  );
});

class MonitorNotifier extends StateNotifier<MonitorState> {
  final MonitorRepository _repository;
  final int userId;
  final String userType;

  MonitorNotifier(
    this._repository, {
    required this.userId,
    required this.userType,
  }) : super(const MonitorState());

  bool get _isBuyer => userType != 'SUPPLIER';

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 并行加载监控列表、预警列表、统计和未查看数
      final results = await Future.wait([
        _isBuyer
            ? _repository.getMonitorsByBuyer(userId)
            : _repository.getMonitorsBySupplier(userId),
        _isBuyer
            ? _repository.getAlertsByBuyer(userId)
            : Future.value(<AlertItem>[]),
        _repository.getStats(userId, isBuyer: _isBuyer),
        _isBuyer ? _repository.getUnviewedCount(userId) : Future.value(0),
      ]);
      state = state.copyWith(
        monitors: results[0] as List<MonitorModel>,
        alerts: results[1] as List<AlertItem>,
        stats: results[2] as MonitorStats,
        unviewedCount: results[3] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void switchTab(int index) {
    state = state.copyWith(currentTab: index);
  }

  Future<void> refreshAlerts() async {
    try {
      final alerts = await _repository.getAlertsByBuyer(userId);
      state = state.copyWith(alerts: alerts);
    } catch (_) {}
  }

  Future<void> resolveAlert(int alertId) async {
    try {
      await _repository.resolveAlert(alertId);
      await refreshAlerts();
    } catch (_) {}
  }

  Future<void> refresh() => loadData();
}
