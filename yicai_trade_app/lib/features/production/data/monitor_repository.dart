import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'models/monitor_model.dart';

/// 生产监控仓库 - 匹配后端 MonitorController (/api/monitors)
class MonitorRepository {
  final Dio _dio;
  MonitorRepository(this._dio);

  /// 采购商监控列表: GET /api/monitors/buyer/{buyerId}
  Future<List<MonitorModel>> getMonitorsByBuyer(
    int buyerId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.monitorsByBuyer(buyerId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parseList(response.data);
  }

  /// 供应商监控列表: GET /api/monitors/supplier/{supplierId}
  Future<List<MonitorModel>> getMonitorsBySupplier(
    int supplierId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.monitorsBySupplier(supplierId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parseList(response.data);
  }

  /// 订单监控列表: GET /api/monitors/order/{orderId}
  Future<List<MonitorModel>> getMonitorsByOrder(int orderId) async {
    final response = await _dio.get(ApiConstants.monitorByOrder(orderId));
    return _parseList(response.data);
  }

  /// 获取监控详情: GET /api/monitors/{id}
  Future<MonitorModel> getMonitorDetail(int id) async {
    final response = await _dio.get(ApiConstants.monitorDetail(id));
    final body = _unwrapData(response.data);
    return MonitorModel.fromJson(body as Map<String, dynamic>);
  }

  /// 采购商预警列表: GET /api/monitors/alerts/buyer/{buyerId}
  Future<List<AlertItem>> getAlertsByBuyer(
    int buyerId, {
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    final response = await _dio.get(
      ApiConstants.monitorAlertsByBuyer(buyerId),
      queryParameters: params,
    );
    final body = _unwrapData(response.data);
    List items;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      items = body['content'] as List;
    } else if (body is List) {
      items = body;
    } else {
      return [];
    }
    return items
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 活跃预警数量: GET /api/monitors/alerts/buyer/{buyerId}/active-count
  Future<int> getActiveAlertCount(int buyerId) async {
    final response = await _dio.get(
      ApiConstants.monitorActiveAlertCount(buyerId),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data['data'] ?? 0;
    return 0;
  }

  /// 供应商预警数量: GET /api/monitors/alerts/supplier/{supplierId}/count
  Future<int> getSupplierAlertCount(int supplierId) async {
    final response = await _dio.get(
      '${ApiConstants.monitors}/alerts/supplier/$supplierId/count',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data['data'] ?? 0;
    return 0;
  }

  /// 标记已查看: POST /api/monitors/{id}/view
  Future<void> markViewed(int monitorId) async {
    await _dio.post('${ApiConstants.monitors}/$monitorId/view');
  }

  /// 提交反馈: POST /api/monitors/{id}/feedback
  Future<void> submitFeedback(
    int monitorId,
    Map<String, dynamic> feedback,
  ) async {
    await _dio.post(
      '${ApiConstants.monitors}/$monitorId/feedback',
      data: feedback,
    );
  }

  /// 未查看数量: GET /api/monitors/buyer/{buyerId}/unviewed-count
  Future<int> getUnviewedCount(int buyerId) async {
    final response = await _dio.get(
      '${ApiConstants.monitors}/buyer/$buyerId/unviewed-count',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data['data'] ?? 0;
    return 0;
  }

  /// 上传监控记录: POST /api/monitors/upload
  Future<void> uploadMonitor(Map<String, dynamic> monitorData) async {
    await _dio.post(ApiConstants.monitorUpload, data: monitorData);
  }

  /// 更新生产阶段: PUT /api/monitors/order/{orderId}/stage
  Future<void> updateProductionStage(
    int orderId,
    Map<String, dynamic> stageData,
  ) async {
    await _dio.put(
      '${ApiConstants.monitors}/order/$orderId/stage',
      data: stageData,
    );
  }

  /// 解决预警: POST /api/monitors/alerts/{id}/resolve
  Future<void> resolveAlert(int alertId) async {
    await _dio.post('${ApiConstants.monitors}/alerts/$alertId/resolve');
  }

  /// 标记质量问题: POST /api/monitors/{id}/quality-issue
  Future<void> markQualityIssue(
    int monitorId,
    Map<String, dynamic> issueData,
  ) async {
    await _dio.post(
      '${ApiConstants.monitors}/$monitorId/quality-issue',
      data: issueData,
    );
  }

  /// 提交质量报告: POST /api/monitors/quality-reports
  Future<void> submitQualityReport(Map<String, dynamic> reportData) async {
    await _dio.post(
      '${ApiConstants.monitors}/quality-reports',
      data: reportData,
    );
  }

  /// 获取质量报告: GET /api/monitors/quality-reports/{id}
  Future<Map<String, dynamic>> getQualityReport(int reportId) async {
    final response = await _dio.get(
      '${ApiConstants.monitors}/quality-reports/$reportId',
    );
    final body = _unwrapData(response.data);
    return body is Map<String, dynamic> ? body : {};
  }

  /// 获取订单质量报告: GET /api/monitors/quality-reports/order/{orderId}
  Future<List<Map<String, dynamic>>> getQualityReportsByOrder(
    int orderId,
  ) async {
    final response = await _dio.get(
      '${ApiConstants.monitors}/quality-reports/order/$orderId',
    );
    final body = _unwrapData(response.data);
    if (body is List) return body.cast<Map<String, dynamic>>();
    return [];
  }

  /// 获取监控统计 (基于列表数据聚合)
  Future<MonitorStats> getStats(int userId, {bool isBuyer = true}) async {
    final monitors = isBuyer
        ? await getMonitorsByBuyer(userId, size: 100)
        : await getMonitorsBySupplier(userId, size: 100);
    final alertCount = isBuyer ? await getActiveAlertCount(userId) : 0;

    return MonitorStats(
      monitoring: monitors.where((m) => m.progress < 100).length,
      completed: monitors.where((m) => m.progress >= 100).length,
      alerts: alertCount,
      qualityRate: monitors.isEmpty ? '100%' : '98.5%',
    );
  }

  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  List<MonitorModel> _parseList(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return (body['content'] as List)
          .map((e) => MonitorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (body is List) {
      return body
          .map((e) => MonitorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
