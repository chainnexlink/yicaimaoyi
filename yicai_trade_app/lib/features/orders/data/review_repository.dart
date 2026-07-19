import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class ReviewModel {
  final int id;
  final int orderId;
  final int reviewerId;
  final int supplierId;
  final int rating;
  final String? content;
  final String? reply;
  final String status;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.supplierId,
    required this.rating,
    this.content,
    this.reply,
    this.status = 'VISIBLE',
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] ?? 0,
    orderId: json['orderId'] ?? 0,
    reviewerId: json['reviewerId'] ?? json['buyerId'] ?? 0,
    supplierId: json['supplierId'] ?? 0,
    rating: json['rating'] ?? 5,
    content: json['content'],
    reply: json['reply'],
    status: json['status'] ?? 'VISIBLE',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );
}

class ReviewSummary {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;

  const ReviewSummary({
    required this.totalReviews,
    required this.averageRating,
    this.ratingDistribution = const {},
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
    totalReviews: json['totalReviews'] ?? 0,
    averageRating: (json['averageRating'] ?? 0).toDouble(),
    ratingDistribution:
        (json['ratingDistribution'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.tryParse(k) ?? 0, v as int),
        ) ??
        {},
  );
}

/// 评价仓库 - 匹配后端 OrderReviewController
class ReviewRepository {
  final Dio _dio;
  ReviewRepository(this._dio);

  /// 提交评价: POST /api/review
  Future<void> submitReview(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.review, data: data);
  }

  /// 获取订单评价: GET /api/review/order/{orderId}
  Future<ReviewModel?> getByOrder(int orderId) async {
    try {
      final r = await _dio.get(ApiConstants.reviewByOrder(orderId));
      final body = r.data is Map<String, dynamic>
          ? (r.data['data'] ?? r.data)
          : r.data;
      if (body is Map<String, dynamic>) return ReviewModel.fromJson(body);
    } catch (_) {}
    return null;
  }

  /// 供应商的所有评价: GET /api/review/supplier/{supplierId}
  Future<PageResult<ReviewModel>> getBySupplier(
    int supplierId, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      ApiConstants.reviewBySupplier(supplierId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePage(r.data);
  }

  /// 买家的所有评价: GET /api/review/buyer/{buyerId}
  Future<PageResult<ReviewModel>> getByBuyer(
    int buyerId, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      ApiConstants.reviewByBuyer(buyerId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePage(r.data);
  }

  /// 供应商回复评价: POST /api/review/{id}/reply
  Future<void> replyToReview(
    int id, {
    required int supplierId,
    required String reply,
  }) async {
    await _dio.post(
      ApiConstants.reviewReply(id),
      data: {'supplierId': supplierId, 'reply': reply},
    );
  }

  /// 评价申诉: POST /api/review/{id}/appeal
  Future<void> appeal(
    int id, {
    required int buyerId,
    required String reason,
  }) async {
    await _dio.post(
      '${ApiConstants.review}/$id/appeal',
      data: {'buyerId': buyerId, 'reason': reason},
    );
  }

  /// 供应商评价汇总: GET /api/review/supplier/{supplierId}/summary
  Future<ReviewSummary> getSummary(int supplierId) async {
    final r = await _dio.get(ApiConstants.reviewSummary(supplierId));
    final body = r.data is Map<String, dynamic>
        ? (r.data['data'] ?? r.data)
        : r.data;
    return ReviewSummary.fromJson(body as Map<String, dynamic>);
  }

  PageResult<ReviewModel> _parsePage(dynamic data) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => ReviewModel.fromJson(j));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
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
      pageSize: 20,
    );
  }
}
