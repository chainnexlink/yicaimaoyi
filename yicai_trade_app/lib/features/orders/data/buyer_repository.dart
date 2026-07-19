import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

/// 收藏项模型
class FavoriteItem {
  final int id;
  final int targetId;
  final String targetType; // PRODUCT, SUPPLIER, SHOP
  final String? targetName;
  final String? targetImage;
  final DateTime? createdAt;

  const FavoriteItem({
    required this.id,
    required this.targetId,
    required this.targetType,
    this.targetName,
    this.targetImage,
    this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: json['id'] ?? 0,
    targetId: json['targetId'] ?? 0,
    targetType: json['targetType'] ?? '',
    targetName: json['targetName'],
    targetImage: json['targetImage'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );
}

/// 采购商仓库 - 匹配后端 BuyerController (/api/buyer)
class BuyerRepository {
  final Dio _dio;
  BuyerRepository(this._dio);

  /// 获取采购商资料: GET /api/buyer/profile
  Future<Map<String, dynamic>> getProfile() async {
    final r = await _dio.get(ApiConstants.buyerProfile);
    return _unwrap(r.data);
  }

  /// 更新采购商资料: PUT /api/buyer/profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put(ApiConstants.buyerProfile, data: data);
  }

  /// 添加收藏: POST /api/buyer/favorites
  Future<void> addFavorite(int targetId, String targetType) async {
    await _dio.post(
      ApiConstants.buyerFavorites,
      data: {'targetId': targetId, 'targetType': targetType},
    );
  }

  /// 取消收藏: DELETE /api/buyer/favorites
  Future<void> removeFavorite(int targetId, String targetType) async {
    await _dio.delete(
      ApiConstants.buyerFavorites,
      queryParameters: {'targetId': targetId, 'targetType': targetType},
    );
  }

  /// 获取收藏列表: GET /api/buyer/favorites
  Future<List<FavoriteItem>> getFavorites({
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (type != null) params['type'] = type;
    final r = await _dio.get(
      ApiConstants.buyerFavorites,
      queryParameters: params,
    );
    final body = _unwrap(r.data);
    List items;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      items = body['content'] as List;
    } else if (body is List) {
      items = body;
    } else {
      return [];
    }
    return items
        .map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 检查是否已收藏: GET /api/buyer/favorites/check
  Future<bool> isFavorite(int targetId, String targetType) async {
    try {
      final r = await _dio.get(
        '${ApiConstants.buyerFavorites}/check',
        queryParameters: {'targetId': targetId, 'targetType': targetType},
      );
      final body = r.data;
      if (body is Map<String, dynamic>) return body['data'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }
}
