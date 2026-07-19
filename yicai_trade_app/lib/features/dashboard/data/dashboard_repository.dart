import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'models/dashboard_model.dart';

/// 看板数据仓库 - 匹配后端 DashboardController 端点
class DashboardRepository {
  final Dio _dio;
  DashboardRepository(this._dio);

  /// 获取系统统计: GET /api/admin/dashboard/stats
  Future<DashboardData> getDashboardData({String period = 'month'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.dashboardStats,
        queryParameters: {'period': period},
      );
      final data = response.data;
      final body = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data']
          : data;
      return DashboardData.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return const DashboardData();
    }
  }
}
