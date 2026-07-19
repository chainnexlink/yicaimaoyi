import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class LogisticsInfo {
  final int id;
  final String? trackingNo;
  final String? carrier;
  final String status;
  final int? orderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LogisticsInfo({
    required this.id,
    this.trackingNo,
    this.carrier,
    required this.status,
    this.orderId,
    this.createdAt,
    this.updatedAt,
  });

  factory LogisticsInfo.fromJson(Map<String, dynamic> json) => LogisticsInfo(
        id: json['id'] ?? 0,
        trackingNo: json['trackingNo'] ?? json['trackingNumber'],
        carrier: json['carrier'] ?? json['logisticsCompany'],
        status: json['status'] ?? '',
        orderId: json['orderId'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );
}

class TrackingEvent {
  final String time;
  final String description;
  final String? location;

  const TrackingEvent({
    required this.time,
    required this.description,
    this.location,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
        time: json['time'] ?? '',
        description: json['description'] ?? json['info'] ?? '',
        location: json['location'],
      );
}

class TrackingQueryResult {
  final String trackingNo;
  final String? carrierCode;
  final String? status;
  final List<TrackingEvent> events;

  const TrackingQueryResult({
    required this.trackingNo,
    this.carrierCode,
    this.status,
    this.events = const [],
  });

  factory TrackingQueryResult.fromJson(Map<String, dynamic> json) =>
      TrackingQueryResult(
        trackingNo: json['trackingNo'] ?? '',
        carrierCode: json['carrierCode'],
        status: json['status'],
        events: (json['events'] as List<dynamic>?)
                ?.map((e) =>
                    TrackingEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// 物流仓库 - 匹配后端 LogisticsController
class LogisticsRepository {
  final Dio _dio;
  LogisticsRepository(this._dio);

  /// 创建物流单: POST /api/admin/logistics
  Future<LogisticsInfo> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.logistics, data: data);
    return LogisticsInfo.fromJson(_unwrap(r.data));
  }

  /// 获取物流详情: GET /api/admin/logistics/{id}
  Future<LogisticsInfo> getById(int id) async {
    final r = await _dio.get(ApiConstants.logisticsDetail(id));
    return LogisticsInfo.fromJson(_unwrap(r.data));
  }

  /// 根据物流单号查询: GET /api/admin/logistics/tracking/{trackingNo}
  Future<LogisticsInfo> getByTrackingNo(String trackingNo) async {
    final r = await _dio.get(ApiConstants.logisticsTracking(trackingNo));
    return LogisticsInfo.fromJson(_unwrap(r.data));
  }

  /// 分页查询物流列表: GET /api/admin/logistics
  Future<PageResult<LogisticsInfo>> list(
      {String? status, int page = 0, int size = 10}) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    final r =
        await _dio.get(ApiConstants.logistics, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 更新物流状态: PATCH /api/admin/logistics/{id}/status
  Future<void> updateStatus(int id, String status) async {
    await _dio.patch(
      '${ApiConstants.logisticsDetail(id)}/status',
      data: {'status': status},
    );
  }

  /// 物流统计: GET /api/admin/logistics/stats
  Future<Map<String, int>> getStats() async {
    final r = await _dio.get('${ApiConstants.logistics}/stats');
    final body = _unwrap(r.data);
    return body.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// 实时查询快递物流轨迹: GET /api/admin/logistics/track
  Future<TrackingQueryResult> queryTracking(String trackingNo,
      {String? carrierCode}) async {
    final params = <String, dynamic>{'trackingNo': trackingNo};
    if (carrierCode != null) params['carrierCode'] = carrierCode;
    final r = await _dio.get(ApiConstants.logisticsTrack,
        queryParameters: params);
    return TrackingQueryResult.fromJson(_unwrap(r.data));
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic> ? data['data'] : data;
    }
    return {};
  }

  PageResult<LogisticsInfo> _parsePage(dynamic data) {
    final body =
        data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => LogisticsInfo.fromJson(j));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => LogisticsInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: body.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: body.length,
      );
    }
    return const PageResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 10,
    );
  }
}
